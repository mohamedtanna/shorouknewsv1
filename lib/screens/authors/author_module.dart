import 'package:flutter/foundation.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../../models/additional_models.dart'; // Contains AuthorModel, ColumnModel
import '../../services/api_service.dart';
import '../../services/firebase_service.dart';

// Data class for Author Statistics (if not already in additional_models.dart)
// Assuming AuthorStats, AuthorSocialLinks, AuthorSearchFilters, AuthorColumnSortBy
// are defined as in the provided code snippet.
// If they are in additional_models.dart, this can be removed and imported.

class AuthorStats {
  final int totalColumns;
  final int totalViews;
  final DateTime? lastPublished;
  final double averageRating;
  final List<String> topTopics;
  final Map<String, int> monthlyStats;

  AuthorStats({
    required this.totalColumns,
    required this.totalViews,
    this.lastPublished,
    required this.averageRating,
    required this.topTopics,
    required this.monthlyStats,
  });

  factory AuthorStats.fromJson(Map<String, dynamic> json) {
    return AuthorStats(
      totalColumns: json['totalColumns'] as int? ?? 0,
      totalViews: json['totalViews'] as int? ?? 0,
      lastPublished: json['lastPublished'] != null
          ? DateTime.tryParse(json['lastPublished'] as String)
          : null,
      averageRating: (json['averageRating'] as num?)?.toDouble() ?? 0.0,
      topTopics: List<String>.from(json['topTopics'] as List? ?? []),
      monthlyStats: Map<String, int>.from(json['monthlyStats'] as Map? ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalColumns': totalColumns,
      'totalViews': totalViews,
      'lastPublished': lastPublished?.toIso8601String(),
      'averageRating': averageRating,
      'topTopics': topTopics,
      'monthlyStats': monthlyStats,
    };
  }
}

class AuthorSocialLinks {
  final String? facebook;
  final String? twitter;
  final String? instagram;
  final String? linkedin;
  final String? website;
  final String? email;

  AuthorSocialLinks({
    this.facebook,
    this.twitter,
    this.instagram,
    this.linkedin,
    this.website,
    this.email,
  });

  factory AuthorSocialLinks.fromJson(Map<String, dynamic> json) {
    return AuthorSocialLinks(
      facebook: json['facebook'] as String?,
      twitter: json['twitter'] as String?,
      instagram: json['instagram'] as String?,
      linkedin: json['linkedin'] as String?,
      website: json['website'] as String?,
      email: json['email'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'facebook': facebook,
      'twitter': twitter,
      'instagram': instagram,
      'linkedin': linkedin,
      'website': website,
      'email': email,
    };
  }

  bool get hasAnyLink {
    return facebook != null ||
        twitter != null ||
        instagram != null ||
        linkedin != null ||
        website != null ||
        email != null;
  }

  List<Map<String, dynamic>> get availableLinks {
    final links = <Map<String, dynamic>>[];

    if (facebook != null && facebook!.isNotEmpty) {
      links.add({
        'type': 'facebook',
        'url': facebook!,
        'label': 'فيسبوك',
        // 'icon': Icons.facebook, // For UI layer
      });
    }
    if (twitter != null && twitter!.isNotEmpty) {
      links.add({
        'type': 'twitter',
        'url': twitter!,
        'label': 'تويتر',
        // 'icon': YourTwitterIcon,
      });
    }
    if (instagram != null && instagram!.isNotEmpty) {
      links.add({
        'type': 'instagram',
        'url': instagram!,
        'label': 'إنستغرام',
        // 'icon': YourInstagramIcon,
      });
    }
    if (linkedin != null && linkedin!.isNotEmpty) {
      links.add({
        'type': 'linkedin',
        'url': linkedin!,
        'label': 'لينكد إن',
        // 'icon': YourLinkedInIcon,
      });
    }
    if (website != null && website!.isNotEmpty) {
      links.add({
        'type': 'website',
        'url': website!,
        'label': 'الموقع الشخصي',
        // 'icon': Icons.web,
      });
    }
    if (email != null && email!.isNotEmpty) {
      links.add({
        'type': 'email',
        'url': 'mailto:$email',
        'label': 'البريد الإلكتروني',
        // 'icon': Icons.email,
      });
    }
    return links;
  }
}

class AuthorSearchFilters {
  final String? searchQuery;
  final DateTime? fromDate;
  final DateTime? toDate;
  final List<String> categories; // Assuming category IDs or names
  final AuthorColumnSortBy sortBy;
  final bool ascending;

  AuthorSearchFilters({
    this.searchQuery,
    this.fromDate,
    this.toDate,
    this.categories = const [],
    this.sortBy = AuthorColumnSortBy.date,
    this.ascending = false,
  });

  AuthorSearchFilters copyWith({
    String? searchQuery,
    DateTime? fromDate,
    DateTime? toDate,
    List<String>? categories,
    AuthorColumnSortBy? sortBy,
    bool? ascending,
  }) {
    return AuthorSearchFilters(
      searchQuery: searchQuery ?? this.searchQuery,
      fromDate: fromDate ?? this.fromDate,
      toDate: toDate ?? this.toDate,
      categories: categories ?? this.categories,
      sortBy: sortBy ?? this.sortBy,
      ascending: ascending ?? this.ascending,
    );
  }

  Map<String, dynamic> toQueryParameters() {
    final params = <String, dynamic>{};
    if (searchQuery != null && searchQuery!.isNotEmpty) {
      params['search'] = searchQuery;
    }
    if (fromDate != null) {
      params['from_date'] = fromDate!.toIso8601String();
    }
    if (toDate != null) {
      params['to_date'] = toDate!.toIso8601String();
    }
    if (categories.isNotEmpty) {
      params['categories'] = categories.join(',');
    }
    params['sort_by'] = sortBy.name; // Enum .name gives string representation
    params['ascending'] = ascending.toString();
    return params;
  }
}

enum AuthorColumnSortBy {
  date,
  title,
  views, // Popularity
  rating, // If applicable
}

class AuthorModule {
  final ApiService _apiService = ApiService();
  final FirebaseService _firebaseService = FirebaseService();

  // Cache for authors data
  final Map<String, AuthorModel> _authorsCache = {};
  final Map<String, List<ColumnModel>> _authorColumnsCache = {}; // Key: authorId-page-pageSize-filtersHash
  final Map<String, AuthorStats> _authorStatsCache = {};
  final Map<String, AuthorSocialLinks> _authorSocialLinksCache = {};

  // Favorites management
  Set<String> _favoriteAuthorIds = {}; // Renamed for clarity
  bool _favoritesLoaded = false;
  static const String _favoriteAuthorsKey = 'favorite_authors_v1';

  // Reading history (Author visit history)
  final Map<String, DateTime> _authorVisitHistory = {};
  static const String _authorVisitHistoryKey = 'author_visit_history_v1';


  // Getters
  Set<String> get favoriteAuthorIds => Set.unmodifiable(_favoriteAuthorIds);
  Map<String, DateTime> get authorVisitHistory => Map.unmodifiable(_authorVisitHistory);

  // Initialize module
  Future<void> initialize() async {
    await _loadFavoriteAuthors();
    await _loadAuthorVisitHistory();
    debugPrint("AuthorModule initialized.");
  }

  // Get author details
  Future<AuthorModel> getAuthor(String authorId, {bool useCache = true}) async {
    if (useCache && _authorsCache.containsKey(authorId)) {
      debugPrint("Author $authorId found in memory cache.");
      await _trackAuthorView(authorId); // Track view even if from cache
      return _authorsCache[authorId]!;
    }

    try {
      debugPrint("Fetching author $authorId from API.");
      final author = await _apiService.getAuthor(authorId);
      _authorsCache[authorId] = author;
      await _trackAuthorView(authorId);
      return author;
    } catch (e) {
      debugPrint('Error getting author $authorId: $e');
      rethrow;
    }
  }

  // Get author columns with pagination and filtering
  Future<List<ColumnModel>> getAuthorColumns(
    String authorId, {
    int page = 1,
    int pageSize = 10,
    AuthorSearchFilters? filters, // Optional filters
    bool useCache = false, // Caching for paginated lists can be complex, use with care
  }) async {
    // More sophisticated cache key might include filter hash
    final cacheKey = '$authorId-cols-p$page-s$pageSize-${filters?.searchQuery?.hashCode ?? 0}';
    
    if (useCache && _authorColumnsCache.containsKey(cacheKey)) {
      debugPrint("Author columns for $authorId (page $page) found in memory cache.");
      return _authorColumnsCache[cacheKey]!;
    }

    try {
      debugPrint("Fetching author columns for $authorId (page $page) from API.");
      // Assuming ApiService.getAuthorColumns does not yet support filters directly
      // If it does, pass filters.toQueryParameters()
      final columns = await _apiService.getAuthorColumns(
        authorId,
        currentPage: page,
        pageSize: pageSize,
      );

      var filteredColumns = columns;
      if (filters != null) {
        filteredColumns = _applyFilters(columns, filters);
      }

      if (useCache) {
        _authorColumnsCache[cacheKey] = filteredColumns;
      }
      return filteredColumns;
    } catch (e) {
      debugPrint('Error getting author columns for $authorId (page $page): $e');
      rethrow;
    }
  }

  List<ColumnModel> _applyFilters(List<ColumnModel> columns, AuthorSearchFilters filters) {
    var filteredColumns = List<ColumnModel>.from(columns); // Create a mutable copy

    if (filters.searchQuery != null && filters.searchQuery!.isNotEmpty) {
      final query = filters.searchQuery!.toLowerCase();
      filteredColumns = filteredColumns.where((column) {
        return column.title.toLowerCase().contains(query) ||
               (column.body.isNotEmpty && column.body.toLowerCase().contains(query)) || // Check if body is not empty
               (column.summary.isNotEmpty && column.summary.toLowerCase().contains(query));
      }).toList();
    }

    if (filters.fromDate != null) {
      filteredColumns = filteredColumns.where((column) {
        final columnDate = DateTime.tryParse(column.creationDate);
        return columnDate != null && !columnDate.isBefore(filters.fromDate!);
      }).toList();
    }
    if (filters.toDate != null) {
      filteredColumns = filteredColumns.where((column) {
        final columnDate = DateTime.tryParse(column.creationDate);
        // Add 1 day to toDate to make it inclusive of the whole day
        return columnDate != null && columnDate.isBefore(filters.toDate!.add(const Duration(days: 1)));
      }).toList();
    }

    // TODO: Implement category filtering if your ColumnModel has category info
    // and AuthorSearchFilters.categories is used.

    filteredColumns.sort((a, b) {
      int comparison = 0;
      switch (filters.sortBy) {
        case AuthorColumnSortBy.date:
          final dateA = DateTime.tryParse(a.creationDate) ?? DateTime(1900);
          final dateB = DateTime.tryParse(b.creationDate) ?? DateTime(1900);
          comparison = dateA.compareTo(dateB);
          break;
        case AuthorColumnSortBy.title:
          comparison = a.title.compareTo(b.title);
          break;
        case AuthorColumnSortBy.views:
          // Placeholder: Requires view count in ColumnModel or fetched separately
          // final viewsA = getColumnViewCount(a.id); // Example
          // final viewsB = getColumnViewCount(b.id); // Example
          // comparison = viewsA.compareTo(viewsB);
          break;
        case AuthorColumnSortBy.rating:
          // Placeholder: Requires rating in ColumnModel or fetched separately
          break;
      }
      return filters.ascending ? comparison : -comparison;
    });

    return filteredColumns;
  }

  Future<AuthorStats> getAuthorStats(String authorId, {bool useCache = true}) async {
    if (useCache && _authorStatsCache.containsKey(authorId)) {
      return _authorStatsCache[authorId]!;
    }
    try {
      // This is mock data. Replace with actual API call if available.
      // final statsData = await _apiService.getAuthorStats(authorId);
      // final stats = AuthorStats.fromJson(statsData);
      
      // Mock implementation:
      final columns = await getAuthorColumns(authorId, pageSize: 200); // Fetch more for better stats
      final stats = AuthorStats(
        totalColumns: columns.length,
        totalViews: columns.fold(0, (sum, item) => sum + (item.id.hashCode % 1000 + 50)), // Mock views
        lastPublished: columns.isNotEmpty ? DateTime.tryParse(columns.first.creationDate) : null,
        averageRating: (authorId.hashCode % 15 + 35) / 10.0, // Mock rating 3.5 to 4.9
        topTopics: _extractTopTopics(columns),
        monthlyStats: _generateMonthlyStats(columns),
      );
      _authorStatsCache[authorId] = stats;
      return stats;
    } catch (e) {
      debugPrint('Error getting author stats for $authorId: $e');
      return AuthorStats(totalColumns: 0, totalViews: 0, averageRating: 0.0, topTopics: [], monthlyStats: {});
    }
  }

  List<String> _extractTopTopics(List<ColumnModel> columns) {
    final topicCount = <String, int>{};
    for (final column in columns) {
      // Simple topic extraction from title words (can be improved)
      column.title.split(' ').where((word) => word.length > 3).forEach((word) {
        final cleanWord = word.replaceAll(RegExp(r'[^\w\sأ-ي]'), '').toLowerCase(); // Basic cleaning
        if (cleanWord.isNotEmpty) {
          topicCount[cleanWord] = (topicCount[cleanWord] ?? 0) + 1;
        }
      });
    }
    final sortedTopics = topicCount.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return sortedTopics.take(5).map((e) => e.key).toList();
  }

  Map<String, int> _generateMonthlyStats(List<ColumnModel> columns) {
    final monthlyStats = <String, int>{};
    for (final column in columns) {
      final date = DateTime.tryParse(column.creationDate);
      if (date != null) {
        final monthKey = '${date.year}-${date.month.toString().padLeft(2, '0')}';
        monthlyStats[monthKey] = (monthlyStats[monthKey] ?? 0) + 1;
      }
    }
    return monthlyStats;
  }

  Future<AuthorSocialLinks> getAuthorSocialLinks(String authorId, {bool useCache = true}) async {
    if (useCache && _authorSocialLinksCache.containsKey(authorId)) {
      return _authorSocialLinksCache[authorId]!;
    }
    try {
      // Placeholder: Replace with actual API call if backend provides social links
      // final linksData = await _apiService.getAuthorSocialLinks(authorId);
      // final socialLinks = AuthorSocialLinks.fromJson(linksData);
      await Future.delayed(const Duration(milliseconds: 100)); // Simulate API call
      final socialLinks = AuthorSocialLinks( // Mock data
        facebook: "https://facebook.com/author-$authorId",
        twitter: "https://twitter.com/author-$authorId",
        website: "https://author-$authorId.example.com",
      );
      _authorSocialLinksCache[authorId] = socialLinks;
      return socialLinks;
    } catch (e) {
      debugPrint('Error getting author social links for $authorId: $e');
      return AuthorSocialLinks();
    }
  }

  Future<void> toggleFavoriteAuthor(String authorId) async {
    if (_favoriteAuthorIds.contains(authorId)) {
      _favoriteAuthorIds.remove(authorId);
      // Corrected: Call logAnalyticsEvent
      await _firebaseService.logAnalyticsEvent('author_unfavorited', parameters: {
        'author_id': authorId,
      });
    } else {
      _favoriteAuthorIds.add(authorId);
      // Corrected: Call logAnalyticsEvent
      await _firebaseService.logAnalyticsEvent('author_favorited', parameters: {
        'author_id': authorId,
      });
    }
    await _saveFavoriteAuthors();
  }

  bool isAuthorFavorite(String authorId) {
    return _favoriteAuthorIds.contains(authorId);
  }

  Future<List<AuthorModel>> getFavoriteAuthors() async {
    final favoriteAuthorsList = <AuthorModel>[];
    if (!_favoritesLoaded) await _loadFavoriteAuthors(); // Ensure favorites are loaded

    for (final authorId in _favoriteAuthorIds) {
      try {
        // Fetch from cache first, then API if not found
        final author = await getAuthor(authorId, useCache: true);
        favoriteAuthorsList.add(author);
      } catch (e) {
        debugPrint('Error loading favorite author $authorId from getFavoriteAuthors: $e');
        // Optionally remove invalid ID from favorites if getAuthor fails consistently
        // _favoriteAuthorIds.remove(authorId);
        // await _saveFavoriteAuthors();
      }
    }
    return favoriteAuthorsList;
  }

  Future<void> _saveFavoriteAuthors() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_favoriteAuthorsKey, _favoriteAuthorIds.toList());
    } catch (e) {
      debugPrint('Error saving favorite authors: $e');
    }
  }

  Future<void> _loadFavoriteAuthors() async {
    if (_favoritesLoaded) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final favoritesList = prefs.getStringList(_favoriteAuthorsKey) ?? [];
      _favoriteAuthorIds = favoritesList.toSet();
      _favoritesLoaded = true;
      debugPrint("Favorite authors loaded: $_favoriteAuthorIds");
    } catch (e) {
      debugPrint('Error loading favorite authors: $e');
    }
  }

  Future<void> _trackAuthorView(String authorId) async {
    _authorVisitHistory[authorId] = DateTime.now();
    await _saveAuthorVisitHistory();
    // Corrected: Call logAnalyticsEvent
    await _firebaseService.logAnalyticsEvent('author_viewed', parameters: {
      'author_id': authorId,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<void> _saveAuthorVisitHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = <String, String>{};
      _authorVisitHistory.forEach((authorId, date) {
        historyJson[authorId] = date.toIso8601String();
      });
      await prefs.setString(_authorVisitHistoryKey, jsonEncode(historyJson));
    } catch (e) {
      debugPrint('Error saving author visit history: $e');
    }
  }

  Future<void> _loadAuthorVisitHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJsonString = prefs.getString(_authorVisitHistoryKey);
      if (historyJsonString != null) {
        final historyJson = jsonDecode(historyJsonString) as Map<String, dynamic>;
        historyJson.forEach((authorId, dateString) {
          final date = DateTime.tryParse(dateString as String);
          if (date != null) {
            _authorVisitHistory[authorId] = date;
          }
        });
        debugPrint("Author visit history loaded.");
      }
    } catch (e) {
      debugPrint('Error loading author visit history: $e');
    }
  }

  List<String> getRecentlyVisitedAuthors({int limit = 5}) { // Default to 5 for UI
    final sortedHistory = _authorVisitHistory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value)); // Sort by most recent
    return sortedHistory.take(limit).map((e) => e.key).toList();
  }

  Future<void> shareAuthor(AuthorModel author) async {
    try {
      final shareText = '''
📝 ${author.arName}
${author.description.isNotEmpty ? author.description : 'كاتب ومحلل في جريدة الشروق.'}

اقرأ مقالات ${author.arName} على تطبيق الشروق.
#الشروق #كاتب #مقالات
      '''; // Added fallback for description
      await Share.share(
        shareText,
        subject: 'كاتب من الشروق - ${author.arName}',
      );
      // Corrected: Call logAnalyticsEvent
      await _firebaseService.logAnalyticsEvent('author_shared', parameters: {
        'author_id': author.id,
        'author_name': author.arName,
      });
    } catch (e) {
      debugPrint('Error sharing author: $e');
      // Do not throw exception to UI, just log.
    }
  }

  Future<void> openExternalLink(String url) async {
    try {
      final uri = Uri.parse(url);
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        debugPrint('Could not launch $url');
        // Optionally show a message to user via a SnackBar or similar
      }
    } catch (e) {
      debugPrint('Error opening external link $url: $e');
    }
  }

  Future<List<AuthorModel>> searchAuthors(String query) async {
    if (query.trim().isEmpty) return [];
    try {
      // Placeholder: In a real app, this would be an API call.
      // For now, search through cached authors.
      debugPrint("Searching authors for: $query");
      await Future.delayed(const Duration(milliseconds: 200)); // Simulate network
      final searchResults = _authorsCache.values.where((author) {
        return author.arName.toLowerCase().contains(query.toLowerCase()) ||
               (author.description.isNotEmpty && author.description.toLowerCase().contains(query.toLowerCase()));
      }).toList();

      // Corrected: Call logAnalyticsEvent
      await _firebaseService.logAnalyticsEvent('authors_searched', parameters: {
        'query': query,
        'results_count': searchResults.length,
      });
      return searchResults;
    } catch (e) {
      debugPrint('Error searching authors: $e');
      return [];
    }
  }

  Future<List<AuthorModel>> getRecommendedAuthors({int limit = 5}) async {
    // Simple recommendation: recently visited or favorited authors not yet followed,
    // or most popular authors if no other data.
    // This is a placeholder for more sophisticated recommendation logic.
    if (!_favoritesLoaded) await _loadFavoriteAuthors();
    await _loadAuthorVisitHistory();

    Set<String> candidates = {};
    candidates.addAll(getRecentlyVisitedAuthors(limit: limit + 5));
    candidates.addAll(_favoriteAuthorIds);
    
    final recommendations = <AuthorModel>[];
    for (final authorId in candidates) {
      if (recommendations.length >= limit) break;
      try {
        final author = await getAuthor(authorId, useCache: true);
        recommendations.add(author);
      } catch (e) { /* ignore */ }
    }

    // If still not enough, could fetch popular authors from API
    if (recommendations.length < limit) {
        // Placeholder: final popularAuthors = await _apiService.getPopularAuthors(limit: limit - recommendations.length);
        // recommendations.addAll(popularAuthors);
    }
    return recommendations.take(limit).toList();
  }

  void clearCache() {
    _authorsCache.clear();
    _authorColumnsCache.clear();
    _authorStatsCache.clear();
    _authorSocialLinksCache.clear();
    debugPrint("AuthorModule caches cleared.");
  }

  Future<void> clearAllUserData() async {
    clearCache();
    _favoriteAuthorIds.clear();
    _authorVisitHistory.clear();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_favoriteAuthorsKey);
    await prefs.remove(_authorVisitHistoryKey);
    
    _favoritesLoaded = false; // Reset flag
    debugPrint("AuthorModule user data cleared.");
  }

  Map<String, dynamic> getAuthorEngagementMetrics(String authorId) {
    final visitCount = _authorVisitHistory.containsKey(authorId) ? 1 : 0; // Simplified, could be actual count
    final isFavorite = _favoriteAuthorIds.contains(authorId);
    final lastVisit = _authorVisitHistory[authorId];
    
    return {
      'visit_count': visitCount,
      'is_favorite': isFavorite,
      'last_visit': lastVisit?.toIso8601String(),
      'engagement_score': _calculateEngagementScore(authorId),
    };
  }

  double _calculateEngagementScore(String authorId) {
    double score = 0.0;
    if (_favoriteAuthorIds.contains(authorId)) score += 50.0;
    
    final lastVisit = _authorVisitHistory[authorId];
    if (lastVisit != null) {
      final daysSinceVisit = DateTime.now().difference(lastVisit).inDays;
      if (daysSinceVisit <= 7) {
        score += 30.0;
      // ignore: curly_braces_in_flow_control_structures
      } else if (daysSinceVisit <= 30) score += 15.0;
    }
    if (_authorsCache.containsKey(authorId)) score += 20.0; // Bonus if recently loaded
    return score.clamp(0.0, 100.0);
  }

  void dispose() {
    // Clear caches on dispose if this module instance is meant to be short-lived.
    // For a singleton-like service, explicit clearAllData() might be preferred.
    clearCache();
    debugPrint('AuthorModule disposed.');
  }
}
