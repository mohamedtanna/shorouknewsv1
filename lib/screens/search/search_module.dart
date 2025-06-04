import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
// For JSON encoding/decoding of recent searches

import '../../models/new_model.dart'; // For NewsArticle model
import '../../services/api_service.dart'; // To call the search API

class SearchModule {
  final ApiService _apiService = ApiService();
  static const String _recentSearchesKey = 'recent_search_queries_v1'; // Added _v1 for potential future migrations
  static const int _maxRecentSearches = 10; // Max number of recent searches to store

  /// Performs a news search using the ApiService.
  ///
  /// [query]: The search term.
  /// [page]: The page number for pagination.
  /// [pageSize]: The number of results per page.
  /// Returns a list of [NewsArticle] matching the query.
  /// Throws an exception if the search fails.
  Future<List<NewsArticle>> performSearch(
    String query, {
    int page = 1,
    int pageSize = 15,
  }) async {
    final trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) {
      return []; // Return empty list if query is empty
    }
    try {
      // The search term is added to recent searches in the UI layer (SearchScreen)
      // before navigating to results, which is a common pattern.
      final results = await _apiService.searchNews(
        trimmedQuery,
        currentPage: page,
        pageSize: pageSize,
      );
      return results;
    } catch (e) {
      debugPrint('Error performing search in SearchModule for query "$trimmedQuery": $e');
      // Rethrow to allow UI to handle the error display appropriately
      rethrow;
    }
  }

  /// Retrieves the list of recent search queries.
  Future<List<String>> getRecentSearches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String>? searches = prefs.getStringList(_recentSearchesKey);
      return searches?.toList() ?? []; // Return a mutable list or empty
    } catch (e) {
      debugPrint('Error getting recent searches: $e');
      return [];
    }
  }

  /// Adds a search query to the list of recent searches.
  ///
  /// Ensures no duplicates (case-insensitive) and limits the list to [_maxRecentSearches].
  /// The most recent search is added to the top.
  Future<void> addRecentSearch(String query) async {
    final trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> searches = await getRecentSearches();

      // Remove the query if it already exists (case-insensitive) to move it to the top
      searches.removeWhere((s) => s.toLowerCase() == trimmedQuery.toLowerCase());

      // Add the new query to the beginning of the list
      searches.insert(0, trimmedQuery);

      // Limit the number of recent searches
      if (searches.length > _maxRecentSearches) {
        searches = searches.sublist(0, _maxRecentSearches);
      }

      await prefs.setStringList(_recentSearchesKey, searches);
    } catch (e) {
      debugPrint('Error adding recent search "$trimmedQuery": $e');
    }
  }

  /// Clears all recent search queries.
  Future<void> clearRecentSearches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_recentSearchesKey);
      debugPrint('Recent searches cleared.');
    } catch (e) {
      debugPrint('Error clearing recent searches: $e');
    }
  }

  /// Fetches search suggestions based on a partial query.
  ///
  /// [partialQuery]: The partially typed search term.
  /// This is a placeholder and would typically involve an API call or local filtering.
  Future<List<String>> getSearchSuggestions(String partialQuery) async {
    final trimmedQuery = partialQuery.trim();
    if (trimmedQuery.isEmpty) {
      return [];
    }
    // Simulate fetching suggestions (replace with actual API call or logic)
    debugPrint('Fetching suggestions for: "$trimmedQuery"');
    await Future.delayed(Duration(milliseconds: 150 + (trimmedQuery.length * 20))); // Simulate network delay

    // Mock suggestions - replace with actual suggestion logic
    final List<String> allPossibleSuggestions = [
      "أخبار $trimmedQuery اليوم",
      "تحليل $trimmedQuery الاقتصادي",
      "مقالات عن $trimmedQuery",
      "$trimmedQuery والسياسة",
      "تأثير $trimmedQuery على المجتمع",
      "مستقبل $trimmedQuery في المنطقة",
      "أحدث تطورات $trimmedQuery",
      "خبراء يناقشون $trimmedQuery",
    ];

    return allPossibleSuggestions
        .where((s) => s.toLowerCase().contains(trimmedQuery.toLowerCase()))
        .take(5) // Limit the number of suggestions
        .toList();
  }

  /// Call this method when the module is no longer needed to clean up resources.
  void dispose() {
    // If there were any streams or other resources, they would be closed here.
    debugPrint('SearchModule disposed.');
  }
}
