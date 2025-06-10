import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../../models/column_model.dart';
import '../../models/additional_models.dart';
import '../../core/constants.dart';
import '../../services/api_service.dart';


class ColumnsModule {
  static const String _moduleName = 'ColumnsModule';
  
  // Cache keys
  static const String _allColumnsKey = 'all_columns';
  static const String _columnsByCategoryKey = 'columns_category_';
  static const String _columnsByAuthorKey = 'columns_author_';
  static const String _columnDetailsKey = 'column_details_';
  static const String _favoriteColumnsKey = 'favorite_columns';
  static const String _recentColumnsKey = 'recent_columns';
  static const String _columnStatsKey = 'column_stats';
  static const String _readColumnsKey = 'read_columns';
  static const String _bookmarkedColumnsKey = 'bookmarked_columns';
  
  // API endpoints
  static const String _columnsEndpoint = '/columns';
  static const String _columnDetailsEndpoint = '/columns/{cdate}/{id}';
  static const String _authorColumnsEndpoint = '/columnists/{id}/columns';
  static const String _selectedColumnsEndpoint = '/columns/collections/selected';
  
  // Module state
  final ApiService _apiService;
  final CacheManager _cacheManager;
  final AnalyticsService _analyticsService;
  
  SharedPreferences? _prefs;
  StreamController<ColumnEvent>? _eventController;
  Timer? _cacheCleanupTimer;
  Timer? _syncTimer;
  
  // In-memory cache
  final Map<String, ColumnModel> _columnsCache = {};
  final Map<String, List<ColumnModel>> _categoryColumnsCache = {};
  final Set<String> _favoriteColumnIds = {};
  final List<String> _recentColumnIds = [];
  final Map<String, int> _columnViewCounts = {};
  final Set<String> _readColumnIds = {};
  final Set<String> _bookmarkedColumnIds = {};
  
  // Configuration
  static const int _maxRecentColumns = 50;
  static const int _maxCacheSize = 100;
  static const Duration _cacheExpiration = Duration(hours: 24);
  static const Duration _cleanupInterval = Duration(hours: 1);
  static const Duration _syncInterval = Duration(minutes: 30);
  
  bool _isInitialized = false;

  ColumnsModule({
    required ApiService apiService,
    required CacheManager cacheManager,
    required AnalyticsService analyticsService,
  })  : _apiService = apiService,
        _cacheManager = cacheManager,
        _analyticsService = analyticsService;

  // Initialization
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      _prefs = await SharedPreferences.getInstance();
      _eventController = StreamController<ColumnEvent>.broadcast();
      
      await _loadLocalData();
      _startBackgroundTasks();
      
      _isInitialized = true;
      debugPrint('$_moduleName: Initialized successfully');
    } catch (e) {
      debugPrint('$_moduleName: Initialization error: $e');
      throw Exception('Failed to initialize ColumnsModule: $e');
    }
  }

  Future<void> _loadLocalData() async {
    try {
      // Load favorite columns
      final favoriteIds = _prefs?.getStringList(_favoriteColumnsKey) ?? [];
      _favoriteColumnIds.addAll(favoriteIds);
      
      // Load recent columns
      final recentIds = _prefs?.getStringList(_recentColumnsKey) ?? [];
      _recentColumnIds.addAll(recentIds);
      
      // Load read columns
      final readIds = _prefs?.getStringList(_readColumnsKey) ?? [];
      _readColumnIds.addAll(readIds);
      
      // Load bookmarked columns
      final bookmarkedIds = _prefs?.getStringList(_bookmarkedColumnsKey) ?? [];
      _bookmarkedColumnIds.addAll(bookmarkedIds);
      
      // Load column stats
      final statsJson = _prefs?.getString(_columnStatsKey);
      if (statsJson != null) {
        final stats = json.decode(statsJson) as Map<String, dynamic>;
        stats.forEach((key, value) {
          _columnViewCounts[key] = value as int;
        });
      }
      
      // Load cached columns
      await _loadCachedColumns();
      
    } catch (e) {
      debugPrint('$_moduleName: Error loading local data: $e');
    }
  }

  Future<void> _loadCachedColumns() async {
    try {
      // Load all columns from cache
      final cachedData = await _cacheManager.get(_allColumnsKey);
      if (cachedData != null) {
        final columnsList = (cachedData['data'] as List)
            .map((item) => ColumnModel.fromJson(item))
            .toList();
        
        for (final column in columnsList) {
          _columnsCache[column.id] = column;
        }
      }
    } catch (e) {
      debugPrint('$_moduleName: Error loading cached columns: $e');
    }
  }

  void _startBackgroundTasks() {
    // Start cache cleanup timer
    _cacheCleanupTimer = Timer.periodic(_cleanupInterval, (_) {
      _cleanupCache();
    });
    
    // Start sync timer
    _syncTimer = Timer.periodic(_syncInterval, (_) {
      _syncWithServer();
    });
  }

  // Public API
  
  Stream<ColumnEvent> get eventStream => _eventController?.stream ?? const Stream.empty();

  Future<List<ColumnModel>> getAllColumns({
    int page = 1,
    int pageSize = 20,
    bool forceRefresh = false,
  }) async {
    _ensureInitialized();
    
    final cacheKey = '$_allColumnsKey:$page:$pageSize';
    
    // Check cache first
    if (!forceRefresh) {
      final cachedData = await _cacheManager.get(cacheKey);
      if (cachedData != null && !_isCacheExpired(cachedData['timestamp'])) {
        return (cachedData['data'] as List)
            .map((item) => ColumnModel.fromJson(item))
            .toList();
      }
    }
    
    try {
      // Fetch from API
      final response = await _apiService.get(
        _columnsEndpoint,
        queryParameters: {
          'currentpage': page.toString(),
          'pagesize': pageSize.toString(),
        },
      );
      
      final columns = (response.data as List)
          .map((item) => ColumnModel.fromJson(item))
          .toList();
      
      // Update cache
      await _cacheManager.set(cacheKey, {
        'data': columns.map((c) => c.toJson()).toList(),
        'timestamp': DateTime.now().toIso8601String(),
      });
      
      // Update in-memory cache
      for (final column in columns) {
        _columnsCache[column.id] = column;
      }
      
      _analyticsService.logEvent('columns_loaded', parameters: {
        'page': page,
        'count': columns.length,
      });
      
      return columns;
    } catch (e) {
      debugPrint('$_moduleName: Error fetching columns: $e');
      
      // Return cached data if available
      final cachedData = await _cacheManager.get(cacheKey);
      if (cachedData != null) {
        return (cachedData['data'] as List)
            .map((item) => ColumnModel.fromJson(item))
            .toList();
      }
      
      throw Exception('Failed to load columns: $e');
    }
  }

  Future<List<ColumnModel>> getSelectedColumns({bool forceRefresh = false}) async {
    _ensureInitialized();
    
    const cacheKey = 'selected_columns';
    
    // Check cache first
    if (!forceRefresh) {
      final cachedData = await _cacheManager.get(cacheKey);
      if (cachedData != null && !_isCacheExpired(cachedData['timestamp'])) {
        return (cachedData['data'] as List)
            .map((item) => ColumnModel.fromJson(item))
            .toList();
      }
    }
    
    try {
      // Fetch from API
      final response = await _apiService.get(_selectedColumnsEndpoint);
      
      final columns = (response.data as List)
          .map((item) => ColumnModel.fromJson(item))
          .toList();
      
      // Update cache
      await _cacheManager.set(cacheKey, {
        'data': columns.map((c) => c.toJson()).toList(),
        'timestamp': DateTime.now().toIso8601String(),
      });
      
      // Update in-memory cache
      for (final column in columns) {
        _columnsCache[column.id] = column;
      }
      
      return columns;
    } catch (e) {
      debugPrint('$_moduleName: Error fetching selected columns: $e');
      
      // Return cached data if available
      final cachedData = await _cacheManager.get(cacheKey);
      if (cachedData != null) {
        return (cachedData['data'] as List)
            .map((item) => ColumnModel.fromJson(item))
            .toList();
      }
      
      throw Exception('Failed to load selected columns: $e');
    }
  }

  Future<List<ColumnModel>> getColumnsByAuthor(
    String authorId, {
    int page = 1,
    int pageSize = 20,
    bool forceRefresh = false,
  }) async {
    _ensureInitialized();
    
    final cacheKey = '$_columnsByAuthorKey$authorId:$page:$pageSize';
    
    // Check cache first
    if (!forceRefresh) {
      final cachedData = await _cacheManager.get(cacheKey);
      if (cachedData != null && !_isCacheExpired(cachedData['timestamp'])) {
        return (cachedData['data'] as List)
            .map((item) => ColumnModel.fromJson(item))
            .toList();
      }
    }
    
    try {
      // Fetch from API
      final endpoint = _authorColumnsEndpoint.replaceAll('{id}', authorId);
      final response = await _apiService.get(
        endpoint,
        queryParameters: {
          'currentpage': page.toString(),
          'pagesize': pageSize.toString(),
        },
      );
      
      final columns = (response.data as List)
          .map((item) => ColumnModel.fromJson(item))
          .toList();
      
      // Update cache
      await _cacheManager.set(cacheKey, {
        'data': columns.map((c) => c.toJson()).toList(),
        'timestamp': DateTime.now().toIso8601String(),
      });
      
      // Update in-memory cache
      for (final column in columns) {
        _columnsCache[column.id] = column;
      }
      
      _analyticsService.logEvent('author_columns_loaded', parameters: {
        'author_id': authorId,
        'count': columns.length,
      });
      
      return columns;
    } catch (e) {
      debugPrint('$_moduleName: Error fetching columns by author: $e');
      
      // Return cached data if available
      final cachedData = await _cacheManager.get(cacheKey);
      if (cachedData != null) {
        return (cachedData['data'] as List)
            .map((item) => ColumnModel.fromJson(item))
            .toList();
      }
      
      throw Exception('Failed to load columns by author: $e');
    }
  }

  Future<ColumnModel> getColumnDetails(String cdate, String columnId, {bool forceRefresh = false}) async {
    _ensureInitialized();
    
    final cacheKey = '$_columnDetailsKey$columnId';
    
    // Check in-memory cache first
    if (!forceRefresh && _columnsCache.containsKey(columnId)) {
      final column = _columnsCache[columnId]!;
      if (column.body.isNotEmpty) {
        _trackColumnView(column);
        return column;
      }
    }
    
    // Check persistent cache
    if (!forceRefresh) {
      final cachedData = await _cacheManager.get(cacheKey);
      if (cachedData != null && !_isCacheExpired(cachedData['timestamp'])) {
        final column = ColumnModel.fromJson(cachedData['data']);
        _columnsCache[columnId] = column;
        _trackColumnView(column);
        return column;
      }
    }
    
    try {
      // Fetch from API
      final endpoint = _columnDetailsEndpoint
          .replaceAll('{cdate}', cdate)
          .replaceAll('{id}', columnId);
      
      final response = await _apiService.get(endpoint);
      final column = ColumnModel.fromJson(response.data);
      
      // Update cache
      await _cacheManager.set(cacheKey, {
        'data': column.toJson(),
        'timestamp': DateTime.now().toIso8601String(),
      });
      
      // Update in-memory cache
      _columnsCache[columnId] = column;
      
      _trackColumnView(column);
      
      return column;
    } catch (e) {
      debugPrint('$_moduleName: Error fetching column details: $e');
      
      // Return cached data if available
      if (_columnsCache.containsKey(columnId)) {
        return _columnsCache[columnId]!;
      }
      
      final cachedData = await _cacheManager.get(cacheKey);
      if (cachedData != null) {
        return ColumnModel.fromJson(cachedData['data']);
      }
      
      throw Exception('Failed to load column details: $e');
    }
  }

  Future<List<ColumnModel>> searchColumns(
    String query, {
    int page = 1,
    int pageSize = 20,
  }) async {
    _ensureInitialized();
    
    if (query.isEmpty) return [];
    
    try {
      // Search in cache first
      final cachedResults = _searchInCache(query);
      if (cachedResults.isNotEmpty) {
        return cachedResults;
      }
      
      // Fetch from API
      final response = await _apiService.get(
        _columnsEndpoint,
        queryParameters: {
          'search': query,
          'currentpage': page.toString(),
          'pagesize': pageSize.toString(),
        },
      );
      
      final columns = (response.data as List)
          .map((item) => ColumnModel.fromJson(item))
          .toList();
      
      // Update in-memory cache
      for (final column in columns) {
        _columnsCache[column.id] = column;
      }
      
      _analyticsService.logEvent('columns_searched', parameters: {
        'query': query,
        'results': columns.length,
      });
      
      return columns;
    } catch (e) {
      debugPrint('$_moduleName: Error searching columns: $e');
      throw Exception('Failed to search columns: $e');
    }
  }

  List<ColumnModel> _searchInCache(String query) {
    final lowercaseQuery = query.toLowerCase();
    return _columnsCache.values.where((column) {
      return column.title.toLowerCase().contains(lowercaseQuery) ||
             column.columnistArName.toLowerCase().contains(lowercaseQuery) ||
             column.summary.toLowerCase().contains(lowercaseQuery);
    }).toList();
  }

  // Favorites Management
  
  Future<void> addColumnToFavorites(ColumnModel column) async {
    _ensureInitialized();
    
    if (_favoriteColumnIds.contains(column.id)) return;
    
    _favoriteColumnIds.add(column.id);
    _columnsCache[column.id] = column;
    
    await _saveFavorites();
    
    _eventController?.add(ColumnEvent(
      type: ColumnEventType.favoriteAdded,
      columnId: column.id,
    ));
    
    _analyticsService.logEvent('column_favorited', parameters: {
      'column_id': column.id,
      'author_id': column.columnistId,
    });
  }

  Future<void> removeColumnFromFavorites(String columnId) async {
    _ensureInitialized();
    
    if (!_favoriteColumnIds.contains(columnId)) return;
    
    _favoriteColumnIds.remove(columnId);
    
    await _saveFavorites();
    
    _eventController?.add(ColumnEvent(
      type: ColumnEventType.favoriteRemoved,
      columnId: columnId,
    ));
    
    _analyticsService.logEvent('column_unfavorited', parameters: {
      'column_id': columnId,
    });
  }

  bool isColumnFavorite(String columnId) {
    return _favoriteColumnIds.contains(columnId);
  }

  Future<List<ColumnModel>> getFavoriteColumns() async {
    _ensureInitialized();
    
    final favoriteColumns = <ColumnModel>[];
    
    for (final columnId in _favoriteColumnIds) {
      if (_columnsCache.containsKey(columnId)) {
        favoriteColumns.add(_columnsCache[columnId]!);
      } else {
        // Try to load from cache
        final cacheKey = '$_columnDetailsKey$columnId';
        final cachedData = await _cacheManager.get(cacheKey);
        if (cachedData != null) {
          final column = ColumnModel.fromJson(cachedData['data']);
          _columnsCache[columnId] = column;
          favoriteColumns.add(column);
        }
      }
    }
    
    return favoriteColumns;
  }

  Future<void> _saveFavorites() async {
    await _prefs?.setStringList(_favoriteColumnsKey, _favoriteColumnIds.toList());
  }

  // Bookmarks Management
  
  Future<void> addColumnToBookmarks(ColumnModel column) async {
    _ensureInitialized();
    
    if (_bookmarkedColumnIds.contains(column.id)) return;
    
    _bookmarkedColumnIds.add(column.id);
    _columnsCache[column.id] = column;
    
    await _saveBookmarks();
    
    _eventController?.add(ColumnEvent(
      type: ColumnEventType.bookmarkAdded,
      columnId: column.id,
    ));
    
    _analyticsService.logEvent('column_bookmarked', parameters: {
      'column_id': column.id,
    });
  }

  Future<void> removeColumnFromBookmarks(String columnId) async {
    _ensureInitialized();
    
    if (!_bookmarkedColumnIds.contains(columnId)) return;
    
    _bookmarkedColumnIds.remove(columnId);
    
    await _saveBookmarks();
    
    _eventController?.add(ColumnEvent(
      type: ColumnEventType.bookmarkRemoved,
      columnId: columnId,
    ));
  }

  bool isColumnBookmarked(String columnId) {
    return _bookmarkedColumnIds.contains(columnId);
  }

  Future<List<ColumnModel>> getBookmarkedColumns() async {
    _ensureInitialized();
    
    final bookmarkedColumns = <ColumnModel>[];
    
    for (final columnId in _bookmarkedColumnIds) {
      if (_columnsCache.containsKey(columnId)) {
        bookmarkedColumns.add(_columnsCache[columnId]!);
      }
    }
    
    return bookmarkedColumns;
  }

  Future<void> _saveBookmarks() async {
    await _prefs?.setStringList(_bookmarkedColumnsKey, _bookmarkedColumnIds.toList());
  }

  // Reading History
  
  void _trackColumnView(ColumnModel column) {
    // Add to recent columns
    _recentColumnIds.remove(column.id);
    _recentColumnIds.insert(0, column.id);
    
    // Limit recent columns
    if (_recentColumnIds.length > _maxRecentColumns) {
      _recentColumnIds.removeRange(_maxRecentColumns, _recentColumnIds.length);
    }
    
    // Update view count
    _columnViewCounts[column.id] = (_columnViewCounts[column.id] ?? 0) + 1;
    
    // Mark as read
    _readColumnIds.add(column.id);
    
    // Save to preferences
    _saveRecentColumns();
    _saveReadColumns();
    _saveColumnStats();
    
    _eventController?.add(ColumnEvent(
      type: ColumnEventType.viewed,
      columnId: column.id,
    ));
    
    _analyticsService.logEvent('column_viewed', parameters: {
      'column_id': column.id,
      'author_id': column.columnistId,
      'view_count': _columnViewCounts[column.id],
    });
  }

  Future<void> markColumnAsRead(String columnId) async {
    _ensureInitialized();
    
    if (_readColumnIds.contains(columnId)) return;
    
    _readColumnIds.add(columnId);
    await _saveReadColumns();
    
    _eventController?.add(ColumnEvent(
      type: ColumnEventType.markedAsRead,
      columnId: columnId,
    ));
  }

  bool isColumnRead(String columnId) {
    return _readColumnIds.contains(columnId);
  }

  List<String> getRecentlyViewedColumnIds({int limit = 10}) {
    return _recentColumnIds.take(limit).toList();
  }

  Future<List<ColumnModel>> getRecentlyViewedColumns({int limit = 10}) async {
    _ensureInitialized();
    
    final recentColumns = <ColumnModel>[];
    final recentIds = getRecentlyViewedColumnIds(limit: limit);
    
    for (final columnId in recentIds) {
      if (_columnsCache.containsKey(columnId)) {
        recentColumns.add(_columnsCache[columnId]!);
      }
    }
    
    return recentColumns;
  }

  int getColumnViewCount(String columnId) {
    return _columnViewCounts[columnId] ?? 0;
  }

  Future<void> _saveRecentColumns() async {
    await _prefs?.setStringList(_recentColumnsKey, _recentColumnIds);
  }

  Future<void> _saveReadColumns() async {
    await _prefs?.setStringList(_readColumnsKey, _readColumnIds.toList());
  }

  Future<void> _saveColumnStats() async {
    final statsJson = json.encode(_columnViewCounts);
    await _prefs?.setString(_columnStatsKey, statsJson);
  }

  // Categories
  
  Future<List<ColumnCategory>> getColumnCategories() async {
    _ensureInitialized();
    
    // For now, return mock categories
    // In a real app, this would fetch from API
    return [
      ColumnCategory(id: '1', name: 'سياسة', columnsCount: 45),
      ColumnCategory(id: '2', name: 'اقتصاد', columnsCount: 32),
      ColumnCategory(id: '3', name: 'رياضة', columnsCount: 28),
      ColumnCategory(id: '4', name: 'ثقافة', columnsCount: 41),
      ColumnCategory(id: '5', name: 'تكنولوجيا', columnsCount: 19),
      ColumnCategory(id: '6', name: 'صحة', columnsCount: 23),
    ];
  }

  Future<List<ColumnModel>> getColumnsByCategory(
    String categoryId, {
    int page = 1,
    int pageSize = 20,
    bool forceRefresh = false,
  }) async {
    _ensureInitialized();
    
    final cacheKey = '$_columnsByCategoryKey$categoryId:$page:$pageSize';
    
    // Check cache first
    if (!forceRefresh) {
      final cachedData = await _cacheManager.get(cacheKey);
      if (cachedData != null && !_isCacheExpired(cachedData['timestamp'])) {
        return (cachedData['data'] as List)
            .map((item) => ColumnModel.fromJson(item))
            .toList();
      }
    }
    
    try {
      // Fetch from API
      final response = await _apiService.get(
        _columnsEndpoint,
        queryParameters: {
          'category': categoryId,
          'currentpage': page.toString(),
          'pagesize': pageSize.toString(),
        },
      );
      
      final columns = (response.data as List)
          .map((item) => ColumnModel.fromJson(item))
          .toList();
      
      // Update cache
      await _cacheManager.set(cacheKey, {
        'data': columns.map((c) => c.toJson()).toList(),
        'timestamp': DateTime.now().toIso8601String(),
      });
      
      // Update in-memory cache
      for (final column in columns) {
        _columnsCache[column.id] = column;
      }
      
      return columns;
    } catch (e) {
      debugPrint('$_moduleName: Error fetching columns by category: $e');
      
      // Return cached data if available
      final cachedData = await _cacheManager.get(cacheKey);
      if (cachedData != null) {
        return (cachedData['data'] as List)
            .map((item) => ColumnModel.fromJson(item))
            .toList();
      }
      
      throw Exception('Failed to load columns by category: $e');
    }
  }

  // Related Columns
  
  Future<List<ColumnModel>> getRelatedColumns(String columnId, {int limit = 6}) async {
    _ensureInitialized();
    
    // Get the original column
    ColumnModel? originalColumn;
    if (_columnsCache.containsKey(columnId)) {
      originalColumn = _columnsCache[columnId];
    }
    
    if (originalColumn == null) return [];
    
    // Find related columns by the same author
    final relatedColumns = _columnsCache.values
        .where((column) => 
            column.id != columnId && 
            column.columnistId == originalColumn.columnistId)
        .take(limit)
        .toList();
    
    // If not enough columns by the same author, add some from cache
    if (relatedColumns.length < limit) {
      final additionalColumns = _columnsCache.values
          .where((column) => 
              column.id != columnId && 
              column.columnistId != originalColumn.columnistId)
          .take(limit - relatedColumns.length)
          .toList();
      
      relatedColumns.addAll(additionalColumns);
    }
    
    return relatedColumns;
  }

  // Statistics
  
  Future<ColumnStats> getColumnStatistics() async {
    _ensureInitialized();
    
    final totalColumns = _columnsCache.length;
    final totalViews = _columnViewCounts.values.fold<int>(0, (sum, count) => sum + count);
    final totalReads = _readColumnIds.length;
    final totalFavorites = _favoriteColumnIds.length;
    final totalBookmarks = _bookmarkedColumnIds.length;
    
    // Calculate most viewed column
    String? mostViewedColumnId;
    int maxViews = 0;
    _columnViewCounts.forEach((columnId, views) {
      if (views > maxViews) {
        maxViews = views;
        mostViewedColumnId = columnId;
      }
    });
    
    ColumnModel? mostViewedColumn;
    if (mostViewedColumnId != null && _columnsCache.containsKey(mostViewedColumnId)) {
      mostViewedColumn = _columnsCache[mostViewedColumnId];
    }
    
    return ColumnStats(
      totalColumns: totalColumns,
      totalViews: totalViews,
      totalReads: totalReads,
      totalFavorites: totalFavorites,
      totalBookmarks: totalBookmarks,
      averageViewsPerColumn: totalColumns > 0 ? totalViews / totalColumns : 0,
      mostViewedColumn: mostViewedColumn,
      recentlyViewedCount: _recentColumnIds.length,
    );
  }

  // Cache Management
  
  void clearCache() {
    _columnsCache.clear();
    _categoryColumnsCache.clear();
    _cacheManager.clear();
    
    debugPrint('$_moduleName: Cache cleared');
  }

  void clearUserData() {
    _favoriteColumnIds.clear();
    _recentColumnIds.clear();
    _readColumnIds.clear();
    _bookmarkedColumnIds.clear();
    _columnViewCounts.clear();
    
    _saveFavorites();
    _saveRecentColumns();
    _saveReadColumns();
    _saveBookmarks();
    _saveColumnStats();
    
    debugPrint('$_moduleName: User data cleared');
  }

  Future<void> _cleanupCache() async {
    // Remove old columns from cache
    if (_columnsCache.length > _maxCacheSize) {
      final columnsToRemove = _columnsCache.length - _maxCacheSize;
      final sortedColumns = _columnsCache.entries.toList()
        ..sort((a, b) {
          final aIndex = _recentColumnIds.indexOf(a.key);
          final bIndex = _recentColumnIds.indexOf(b.key);
          
          if (aIndex == -1 && bIndex == -1) return 0;
          if (aIndex == -1) return -1;
          if (bIndex == -1) return 1;
          
          return bIndex.compareTo(aIndex);
        });
      
      for (var i = 0; i < columnsToRemove; i++) {
        _columnsCache.remove(sortedColumns[i].key);
      }
    }
    
    // Clean expired cache entries
    await _cacheManager.removeExpired();
    
    debugPrint('$_moduleName: Cache cleanup completed');
  }

  Future<void> _syncWithServer() async {
    if (!await _hasInternetConnection()) return;
    
    try {
      // Sync favorites
      if (_favoriteColumnIds.isNotEmpty) {
        // In a real app, this would sync with server
        debugPrint('$_moduleName: Syncing ${_favoriteColumnIds.length} favorites');
      }
      
      // Sync reading history
      if (_readColumnIds.isNotEmpty) {
        // In a real app, this would sync with server
        debugPrint('$_moduleName: Syncing ${_readColumnIds.length} read columns');
      }
      
      // Sync statistics
      if (_columnViewCounts.isNotEmpty) {
        // In a real app, this would sync with server
        debugPrint('$_moduleName: Syncing column statistics');
      }

    } catch (e) {
      debugPrint('$_moduleName: Sync error: $e');
    }
  }

  // Utility Methods
  
  bool _isCacheExpired(String? timestamp) {
    if (timestamp == null) return true;
    
    try {
      final cacheTime = DateTime.parse(timestamp);
      final now = DateTime.now();
      return now.difference(cacheTime) > _cacheExpiration;
    } catch (e) {
      return true;
    }
  }

  Future<bool> _hasInternetConnection() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      return connectivityResult != ConnectivityResult.none;
    } catch (e) {
      return false;
    }
  }

  void _ensureInitialized() {
    if (!_isInitialized) {
      throw Exception('$_moduleName not initialized. Call initialize() first.');
    }
  }

  // Disposal
  
  void dispose() {
    _eventController?.close();
    _cacheCleanupTimer?.cancel();
    _syncTimer?.cancel();
    _isInitialized = false;
    
    debugPrint('$_moduleName: Disposed');
  }

  // Export/Import functionality
  
  Future<Map<String, dynamic>> exportUserData() async {
    _ensureInitialized();
    
    return {
      'favorites': _favoriteColumnIds.toList(),
      'recent': _recentColumnIds,
      'read': _readColumnIds.toList(),
      'bookmarks': _bookmarkedColumnIds.toList(),
      'stats': _columnViewCounts,
      'export_date': DateTime.now().toIso8601String(),
    };
  }

  Future<void> importUserData(Map<String, dynamic> data) async {
    _ensureInitialized();
    
    try {
      // Import favorites
      if (data['favorites'] != null) {
        _favoriteColumnIds.clear();
        _favoriteColumnIds.addAll(List<String>.from(data['favorites']));
      }
      
      // Import recent
      if (data['recent'] != null) {
        _recentColumnIds.clear();
        _recentColumnIds.addAll(List<String>.from(data['recent']));
      }
      
      // Import read
      if (data['read'] != null) {
        _readColumnIds.clear();
        _readColumnIds.addAll(List<String>.from(data['read']));
      }
      
      // Import bookmarks
      if (data['bookmarks'] != null) {
        _bookmarkedColumnIds.clear();
        _bookmarkedColumnIds.addAll(List<String>.from(data['bookmarks']));
      }
      
      // Import stats
      if (data['stats'] != null) {
        _columnViewCounts.clear();
        (data['stats'] as Map<String, dynamic>).forEach((key, value) {
          _columnViewCounts[key] = value as int;
        });
      }
      
      // Save all imported data
      await Future.wait([
        _saveFavorites(),
        _saveRecentColumns(),
        _saveReadColumns(),
        _saveBookmarks(),
        _saveColumnStats(),
      ]);
      
      debugPrint('$_moduleName: User data imported successfully');
    } catch (e) {
      debugPrint('$_moduleName: Error importing user data: $e');
      throw Exception('Failed to import user data: $e');
    }
  }

  // Advanced Search
  
  Future<List<ColumnModel>> advancedSearch({
    String? query,
    String? authorId,
    String? categoryId,
    DateTime? fromDate,
    DateTime? toDate,
    ColumnSortBy sortBy = ColumnSortBy.date,
    bool ascending = false,
    int page = 1,
    int pageSize = 20,
  }) async {
    _ensureInitialized();
    
    try {
      final queryParams = <String, String>{
        'currentpage': page.toString(),
        'pagesize': pageSize.toString(),
        'sort': sortBy.toString().split('.').last,
        'order': ascending ? 'asc' : 'desc',
      };
      
      if (query != null && query.isNotEmpty) {
        queryParams['search'] = query;
      }
      
      if (authorId != null) {
        queryParams['author'] = authorId;
      }
      
      if (categoryId != null) {
        queryParams['category'] = categoryId;
      }
      
      if (fromDate != null) {
        queryParams['from'] = fromDate.toIso8601String();
      }
      
      if (toDate != null) {
        queryParams['to'] = toDate.toIso8601String();
      }
      
      final response = await _apiService.get(
        _columnsEndpoint,
        queryParameters: queryParams,
      );
      
      final columns = (response.data as List)
          .map((item) => ColumnModel.fromJson(item))
          .toList();
      
      // Update in-memory cache
      for (final column in columns) {
        _columnsCache[column.id] = column;
      }
      
      _analyticsService.logEvent('advanced_search', parameters: {
        'has_query': query != null,
        'has_author': authorId != null,
        'has_category': categoryId != null,
        'has_date_range': fromDate != null || toDate != null,
        'sort_by': sortBy.toString(),
        'results': columns.length,
      });
      
      return columns;
    } catch (e) {
      debugPrint('$_moduleName: Error in advanced search: $e');
      throw Exception('Failed to perform advanced search: $e');
    }
  }

  // Batch Operations
  
  Future<void> markMultipleColumnsAsRead(List<String> columnIds) async {
    _ensureInitialized();
    
    for (final columnId in columnIds) {
      _readColumnIds.add(columnId);
    }
    
    await _saveReadColumns();
    
    _analyticsService.logEvent('columns_marked_as_read', parameters: {
      'count': columnIds.length,
    });
  }

  Future<void> addMultipleColumnsToFavorites(List<ColumnModel> columns) async {
    _ensureInitialized();
    
    for (final column in columns) {
      _favoriteColumnIds.add(column.id);
      _columnsCache[column.id] = column;
    }
    
    await _saveFavorites();
    
    _analyticsService.logEvent('columns_batch_favorited', parameters: {
      'count': columns.length,
    });
  }

  Future<void> removeMultipleColumnsFromFavorites(List<String> columnIds) async {
    _ensureInitialized();
    
    for (final columnId in columnIds) {
      _favoriteColumnIds.remove(columnId);
    }
    
    await _saveFavorites();
    
    _analyticsService.logEvent('columns_batch_unfavorited', parameters: {
      'count': columnIds.length,
    });
  }

  // Offline Support
  
  Future<void> downloadColumnForOffline(ColumnModel column) async {
    _ensureInitialized();
    
    try {
      // Save complete column data for offline access
      final cacheKey = 'offline_column_${column.id}';
      await _cacheManager.set(cacheKey, {
        'data': column.toJson(),
        'timestamp': DateTime.now().toIso8601String(),
        'offline': true,
      });
      
      // Download and cache images if any
      // In a real app, this would download and cache images locally
      
      _analyticsService.logEvent('column_downloaded_offline', parameters: {
        'column_id': column.id,
      });
      
    } catch (e) {
      debugPrint('$_moduleName: Error downloading column for offline: $e');
      throw Exception('Failed to download column for offline reading: $e');
    }
  }

  Future<List<ColumnModel>> getOfflineColumns() async {
    _ensureInitialized();
    
    final offlineColumns = <ColumnModel>[];
    
    // Get all offline columns from cache
    // In a real app, this would query the cache for offline-marked entries
    
    return offlineColumns;
  }

  Future<void> removeOfflineColumn(String columnId) async {
    _ensureInitialized();
    
    final cacheKey = 'offline_column_$columnId';
    await _cacheManager.remove(cacheKey);
    
    _analyticsService.logEvent('column_removed_offline', parameters: {
      'column_id': columnId,
    });
  }

  // Sharing
  
  String generateShareLink(ColumnModel column) {
    // Generate a shareable link for the column
    return '${AppConstants.baseUrl}/column/${column.cdate}/${column.id}';
  }

  Future<void> shareColumn(ColumnModel column, {String? message}) async {
    _ensureInitialized();
    
    final shareLink = generateShareLink(column);
    final shareText = message ?? 'اقرأ مقال "${column.title}" بقلم ${column.columnistArName}';
    
    // In a real app, this would use the share plugin
    debugPrint('Sharing: $shareText\n$shareLink');
    
    _analyticsService.logEvent('column_shared', parameters: {
      'column_id': column.id,
      'author_id': column.columnistId,
    });
  }

  // Analytics helpers
  
  void logColumnImpression(String columnId) {
    _analyticsService.logEvent('column_impression', parameters: {
      'column_id': columnId,
    });
  }

  void logColumnEngagement(String columnId, String action) {
    _analyticsService.logEvent('column_engagement', parameters: {
      'column_id': columnId,
      'action': action,
    });
  }
}

// Event system for columns
enum ColumnEventType {
  viewed,
  favoriteAdded,
  favoriteRemoved,
  bookmarkAdded,
  bookmarkRemoved,
  markedAsRead,
  downloaded,
  shared,
}

class ColumnEvent {
  final ColumnEventType type;
  final String columnId;
  final Map<String, dynamic>? data;

  ColumnEvent({
    required this.type,
    required this.columnId,
    this.data,
  });
}

// Sort options for columns
enum ColumnSortBy {
  date,
  popularity,
  title,
  author,
}

// Statistics model
class ColumnStats {
  final int totalColumns;
  final int totalViews;
  final int totalReads;
  final int totalFavorites;
  final int totalBookmarks;
  final double averageViewsPerColumn;
  final ColumnModel? mostViewedColumn;
  final int recentlyViewedCount;

  ColumnStats({
    required this.totalColumns,
    required this.totalViews,
    required this.totalReads,
    required this.totalFavorites,
    required this.totalBookmarks,
    required this.averageViewsPerColumn,
    this.mostViewedColumn,
    required this.recentlyViewedCount,
  });
}

// Category model
class ColumnCategory {
  final String id;
  final String name;
  final int columnsCount;

  ColumnCategory({
    required this.id,
    required this.name,
    required this.columnsCount,
  });
}
