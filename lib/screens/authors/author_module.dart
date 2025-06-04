import 'package:flutter/foundation.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../../models/additional_models.dart';
import '../../services/api_service.dart';
import '../../services/firebase_service.dart';

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
      totalColumns: json['totalColumns'] ?? 0,
      totalViews: json['totalViews'] ?? 0,
      lastPublished: json['lastPublished'] != null 
          ? DateTime.parse(json['lastPublished']) 
          : null,
      averageRating: (json['averageRating'] ?? 0.0).toDouble(),
      topTopics: List<String>.from(json['topTopics'] ?? []),
      monthlyStats: Map<String, int>.from(json['monthlyStats'] ?? {}),
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
      facebook: json['facebook'],
      twitter: json['twitter'],
      instagram: json['instagram'],
      linkedin: json['linkedin'],
      website: json['website'],
      email: json['email'],
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
    
    if (facebook != null) {
      links.add({
        'type': 'facebook',
        'url': facebook!,
        'label': 'فيسبوك',
        'icon': 'facebook',
      });
    }
    
    if (twitter != null) {
      links.add({
        'type': 'twitter',
        'url': twitter!,
        'label': 'تويتر',
        'icon': 'twitter',
      });
    }
    
    if (instagram != null) {
      links.add({
        'type': 'instagram',
        'url': instagram!,
        'label': 'إنستغرام',
        'icon': 'instagram',
      });
    }
    
    if (linkedin != null) {
      links.add({
        'type': 'linkedin',
        'url': linkedin!,
        'label': 'لينكد إن',
        'icon': 'linkedin',
      });
    }
    
    if (website != null) {
      links.add({
        'type': 'website',
        'url': website!,
        'label': 'الموقع الشخصي',
        'icon': 'web',
      });
    }
    
    if (email != null) {
      links.add({
        'type': 'email',
        'url': 'mailto:$email',
        'label': 'البريد الإلكتروني',
        'icon': 'email',
      });
    }
    
    return links;
  }
}

class AuthorSearchFilters {
  final String? searchQuery;
  final DateTime? fromDate;
  final DateTime? toDate;
  final List<String> categories;
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
    
    params['sort_by'] = sortBy.name;
    params['ascending'] = ascending.toString();
    
    return params;
  }
}

enum AuthorColumnSortBy {
  date,
  title,
  views,
  rating,
}

class AuthorModule {
  final ApiService _apiService = ApiService();
  final FirebaseService _firebaseService = FirebaseService();

  // Cache for authors data
  final Map<String, AuthorModel> _authorsCache = {};
  final Map<String, List<ColumnModel>> _authorColumnsCache = {};
  final Map<String, AuthorStats> _authorStatsCache = {};
  final Map<String, AuthorSocialLinks> _authorSocialLinksCache = {};

  // Favorites management
  Set<String> _favoriteAuthors = {};
  bool _favoritesLoaded = false;

  // Reading history
  final Map<String, DateTime> _authorVisitHistory = {};

  // Getters
  Set<String> get favoriteAuthors => Set.unmodifiable(_favoriteAuthors);
  Map<String, DateTime> get authorVisitHistory => Map.unmodifiable(_authorVisitHistory);

  // Initialize module
  Future<void> initialize() async {
    await _loadFavoriteAuthors();
    await _loadAuthorVisitHistory();
  }

  // Get author details
  Future<AuthorModel> getAuthor(String authorId, {bool useCache = true}) async {
    if (useCache && _authorsCache.containsKey(authorId)) {
      return _authorsCache[authorId]!;
    }

    try {
      final author = await _apiService.getAuthor(authorId);
      _authorsCache[authorId] = author;
      
      // Track author view
      await _trackAuthorView(authorId);
      
      return author;
    } catch (e) {
      debugPrint('Error getting author: $e');
      rethrow;
    }
  }

  // Get author columns with pagination and filtering
  Future<List<ColumnModel>> getAuthorColumns(
    String authorId, {
    int page = 1,
    int pageSize = 10,
    AuthorSearchFilters? filters,
    bool useCache = false,
  }) async {
    final cacheKey = '$authorId-$page-$pageSize-${filters?.searchQuery ?? ""}';
    
    if (useCache && _authorColumnsCache.containsKey(cacheKey)) {
      return _authorColumnsCache[cacheKey]!;
    }

    try {
      final columns = await _apiService.getAuthorColumns(
        authorId,
        currentPage: page,
        pageSize: pageSize,
      );

      // Apply local filtering if needed
      var filteredColumns = columns;
      if (filters != null) {
        filteredColumns = _applyFilters(columns, filters);
      }

      _authorColumnsCache[cacheKey] = filteredColumns;
      return filteredColumns;
    } catch (e) {
      debugPrint('Error getting author columns: $e');
      rethrow;
    }
  }

  // Apply search filters to columns list
  List<ColumnModel> _applyFilters(List<ColumnModel> columns, AuthorSearchFilters filters) {
    var filteredColumns = columns;

    // Search query filter
    if (filters.searchQuery != null && filters.searchQuery!.isNotEmpty) {
      filteredColumns = filteredColumns.where((column) {
        final query = filters.searchQuery!.toLowerCase();
        return column.title.toLowerCase().contains(query) ||
               column.body.toLowerCase().contains(query);
      }).toList();
    }

    // Date range filter
    if (filters.fromDate != null || filters.toDate != null) {
      filteredColumns = filteredColumns.where((column) {
        final columnDate = DateTime.tryParse(column.creationDate);
        if (columnDate == null) return false;

        if (filters.fromDate != null && columnDate.isBefore(filters.fromDate!)) {
          return false;
        }
        if (filters.toDate != null && columnDate.isAfter(filters.toDate!)) {
          return false;
        }
        return true;
      }).toList();
    }

    // Sort columns
    filteredColumns.sort((a, b) {
      int comparison = 0;
      
      switch (filters.sortBy) {
        case AuthorColumnSortBy.date:
          final dateA = DateTime.tryParse(a.creationDate) ?? DateTime.now();
          final dateB = DateTime.tryParse(b.creationDate) ?? DateTime.now();
          comparison = dateA.compareTo(dateB);
          break;
        case AuthorColumnSortBy.title:
          comparison = a.title.compareTo(b.title);
          break;
        case AuthorColumnSortBy.views:
          // If view count is available in future API updates
          comparison = 0;
          break;
        case AuthorColumnSortBy.rating:
          // If rating is available in future API updates
          comparison = 0;
          break;
      }

      return filters.ascending ? comparison : -comparison;
    });

    return filteredColumns;
  }

  // Get author statistics
  Future<AuthorStats> getAuthorStats(String authorId, {bool useCache = true}) async {
    if (useCache && _authorStatsCache.containsKey(authorId)) {
      return _authorStatsCache[authorId]!;
    }

    try {
      // In a real implementation, this would come from the API
      // For now, we'll generate mock statistics based on columns
      final columns = await getAuthorColumns(authorId, pageSize: 100);
      
      final stats = AuthorStats(
        totalColumns: columns.length,
        totalViews: columns.length * 150, // Mock calculation
        lastPublished: columns.isNotEmpty 
            ? DateTime.tryParse(columns.first.creationDate)
            : null,
        averageRating: 4.2, // Mock rating
        topTopics: _extractTopTopics(columns),
        monthlyStats: _generateMonthlyStats(columns),
      );

      _authorStatsCache[authorId] = stats;
      return stats;
    } catch (e) {
      debugPrint('Error getting author stats: $e');
      // Return default stats on error
      return AuthorStats(
        totalColumns: 0,
        totalViews: 0,
        averageRating: 0.0,
        topTopics: [],
        monthlyStats: {},
      );
    }
  }

  // Extract top topics from columns (basic keyword analysis)
  List<String> _extractTopTopics(List<ColumnModel> columns) {
    final topicCount = <String, int>{};
    
    for (final column in columns) {
      final words = column.title.split(' ');
      for (final word in words) {
        if (word.length > 3) { // Only consider words longer than 3 characters
          final cleanWord = word.toLowerCase().trim();
          topicCount[cleanWord] = (topicCount[cleanWord] ?? 0) + 1;
        }
      }
    }

    // Get top 5 topics
    final sortedTopics = topicCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sortedTopics.take(5).map((e) => e.key).toList();
  }

  // Generate monthly statistics
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

  // Get author social links
  Future<AuthorSocialLinks> getAuthorSocialLinks(String authorId) async {
    if (_authorSocialLinksCache.containsKey(authorId)) {
      return _authorSocialLinksCache[authorId]!;
    }

    try {
      // In a real implementation, this would come from the API
      // For now, return empty social links
      final socialLinks = AuthorSocialLinks();
      _authorSocialLinksCache[authorId] = socialLinks;
      return socialLinks;
    } catch (e) {
      debugPrint('Error getting author social links: $e');
      return AuthorSocialLinks();
    }
  }

  // Favorite authors management
  Future<void> toggleFavoriteAuthor(String authorId) async {
    if (_favoriteAuthors.contains(authorId)) {
      _favoriteAuthors.remove(authorId);
      await _firebaseService.logEvent('author_unfavorited', {
        'author_id': authorId,
      });
    } else {
      _favoriteAuthors.add(authorId);
      await _firebaseService.logEvent('author_favorited', {
        'author_id': authorId,
      });
    }

    await _saveFavoriteAuthors();
  }

  bool isAuthorFavorite(String authorId) {
    return _favoriteAuthors.contains(authorId);
  }

  Future<List<AuthorModel>> getFavoriteAuthors() async {
    final favoriteAuthorsList = <AuthorModel>[];
    
    for (final authorId in _favoriteAuthors) {
      try {
        final author = await getAuthor(authorId);
        favoriteAuthorsList.add(author);
      } catch (e) {
        debugPrint('Error loading favorite author $authorId: $e');
      }
    }

    return favoriteAuthorsList;
  }

  // Save/load favorite authors
  Future<void> _saveFavoriteAuthors() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('favorite_authors', _favoriteAuthors.toList());
    } catch (e) {
      debugPrint('Error saving favorite authors: $e');
    }
  }

  Future<void> _loadFavoriteAuthors() async {
    if (_favoritesLoaded) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final favoritesList = prefs.getStringList('favorite_authors') ?? [];
      _favoriteAuthors = favoritesList.toSet();
      _favoritesLoaded = true;
    } catch (e) {
      debugPrint('Error loading favorite authors: $e');
    }
  }

  // Author visit history
  Future<void> _trackAuthorView(String authorId) async {
    _authorVisitHistory[authorId] = DateTime.now();
    await _saveAuthorVisitHistory();
    
    // Log analytics
    await _firebaseService.logEvent('author_viewed', {
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
      
      await prefs.setString('author_visit_history', jsonEncode(historyJson));
    } catch (e) {
      debugPrint('Error saving author visit history: $e');
    }
  }

  Future<void> _loadAuthorVisitHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJsonString = prefs.getString('author_visit_history');
      
      if (historyJsonString != null) {
        final historyJson = jsonDecode(historyJsonString) as Map<String, dynamic>;
        
        historyJson.forEach((authorId, dateString) {
          final date = DateTime.tryParse(dateString);
          if (date != null) {
            _authorVisitHistory[authorId] = date;
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading author visit history: $e');
    }
  }

  // Get recently visited authors
  List<String> getRecentlyVisitedAuthors({int limit = 10}) {
    final sortedHistory = _authorVisitHistory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sortedHistory.take(limit).map((e) => e.key).toList();
  }

  // Share author profile
  Future<void> shareAuthor(AuthorModel author) async {
    try {
      final shareText = '''
📝 ${author.arName}
${author.description}

اقرأ مقالات ${author.arName} على تطبيق الشروق

#الشروق #كاتب #مقالات
      ''';

      await Share.share(
        shareText,
        subject: 'كاتب من الشروق - ${author.arName}',
      );

      // Log analytics
      await _firebaseService.logEvent('author_shared', {
        'author_id': author.id,
        'author_name': author.arName,
      });
    } catch (e) {
      debugPrint('Error sharing author: $e');
      throw Exception('فشل في مشاركة الكاتب');
    }
  }

  // Open external link
  Future<void> openExternalLink(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      } else {
        throw Exception('Could not launch $url');
      }
    } catch (e) {
      debugPrint('Error opening external link: $e');
      throw Exception('فشل في فتح الرابط');
    }
  }

  // Search authors
  Future<List<AuthorModel>> searchAuthors(String query) async {
    try {
      // In a real implementation, this would be an API call
      // For now, we'll search through cached authors
      final searchResults = <AuthorModel>[];
      
      for (final author in _authorsCache.values) {
        if (author.arName.toLowerCase().contains(query.toLowerCase()) ||
            author.description.toLowerCase().contains(query.toLowerCase())) {
          searchResults.add(author);
        }
      }

      // Log analytics
      await _firebaseService.logEvent('authors_searched', {
        'query': query,
        'results_count': searchResults.length,
      });

      return searchResults;
    } catch (e) {
      debugPrint('Error searching authors: $e');
      return [];
    }
  }

  // Get author recommendations based on reading history
  Future<List<AuthorModel>> getRecommendedAuthors({int limit = 5}) async {
    try {
      // Simple recommendation based on recently visited authors
      final recentAuthors = getRecentlyVisitedAuthors(limit: limit * 2);
      final recommendations = <AuthorModel>[];
      
      for (final authorId in recentAuthors.take(limit)) {
        try {
          final author = await getAuthor(authorId);
          recommendations.add(author);
        } catch (e) {
          // Skip if author not found
        }
      }

      return recommendations;
    } catch (e) {
      debugPrint('Error getting recommended authors: $e');
      return [];
    }
  }

  // Clear cache
  void clearCache() {
    _authorsCache.clear();
    _authorColumnsCache.clear();
    _authorStatsCache.clear();
    _authorSocialLinksCache.clear();
  }

  // Clear all author data
  Future<void> clearAllData() async {
    clearCache();
    _favoriteAuthors.clear();
    _authorVisitHistory.clear();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('favorite_authors');
    await prefs.remove('author_visit_history');
    
    _favoritesLoaded = false;
  }

  // Get author engagement metrics
  Map<String, dynamic> getAuthorEngagementMetrics(String authorId) {
    final visitCount = _authorVisitHistory.containsKey(authorId) ? 1 : 0;
    final isFavorite = _favoriteAuthors.contains(authorId);
    final lastVisit = _authorVisitHistory[authorId];
    
    return {
      'visit_count': visitCount,
      'is_favorite': isFavorite,
      'last_visit': lastVisit?.toIso8601String(),
      'engagement_score': _calculateEngagementScore(authorId),
    };
  }

  // Calculate engagement score (0-100)
  double _calculateEngagementScore(String authorId) {
    double score = 0.0;
    
    // Favorite author bonus
    if (_favoriteAuthors.contains(authorId)) {
      score += 50.0;
    }
    
    // Recent visit bonus
    final lastVisit = _authorVisitHistory[authorId];
    if (lastVisit != null) {
      final daysSinceVisit = DateTime.now().difference(lastVisit).inDays;
      if (daysSinceVisit <= 7) {
        score += 30.0;
      } else if (daysSinceVisit <= 30) {
        score += 15.0;
      }
    }
    
    // Cache presence bonus (indicates recent activity)
    if (_authorsCache.containsKey(authorId)) {
      score += 20.0;
    }
    
    return score.clamp(0.0, 100.0);
  }

  // Dispose resources
  void dispose() {
    clearCache();
  }
}