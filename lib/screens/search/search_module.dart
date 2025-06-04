import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert'; // For JSON encoding/decoding of recent searches

import '../../models/new_model.dart'; // For NewsArticle model
import '../../services/api_service.dart'; // To call the search API

class SearchModule {
  final ApiService _apiService = ApiService();
  static const String _recentSearchesKey = 'recent_search_queries';
  static const int _maxRecentSearches = 10; // Max number of recent searches to store

  /// Performs a news search using the ApiService.
  ///
  /// [query]: The search term.
  /// [page]: The page number for pagination.
  /// [pageSize]: The number of results per page.
  /// Returns a list of [NewsArticle] matching the query.
  Future<List<NewsArticle>> performSearch(
    String query, {
    int page = 1,
    int pageSize = 15, // Default page size for search results
  }) async {
    if (query.trim().isEmpty) {
      return []; // Return empty list if query is empty
    }
    try {
      // Add the query to recent searches upon successful search initiation
      // It's better to add it here rather than after results,
      // as the user intended to search for it.
      await addRecentSearch(query.trim());

      final results = await _apiService.searchNews(
        query.trim(),
        currentPage: page,
        pageSize: pageSize,
      );
      return results;
    } catch (e) {
      debugPrint('Error performing search in SearchModule: $e');
      // Rethrow to allow UI to handle the error display
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
  /// Ensures no duplicates and limits the list to [_maxRecentSearches].
  Future<void> addRecentSearch(String query) async {
    if (query.trim().isEmpty) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> searches = await getRecentSearches();

      // Remove the query if it already exists to move it to the top (most recent)
      searches.removeWhere((s) => s.toLowerCase() == query.toLowerCase().trim());

      // Add the new query to the beginning of the list
      searches.insert(0, query.trim());

      // Limit the number of recent searches
      if (searches.length > _maxRecentSearches) {
        searches = searches.sublist(0, _maxRecentSearches);
      }

      await prefs.setStringList(_recentSearchesKey, searches);
    } catch (e) {
      debugPrint('Error adding recent search: $e');
    }
  }

  /// Clears all recent search queries.
  Future<void> clearRecentSearches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_recentSearchesKey);
    } catch (e) {
      debugPrint('Error clearing recent searches: $e');
    }
  }

  /// Placeholder for fetching search suggestions (e.g., for type-ahead).
  ///
  /// [partialQuery]: The partially typed search term.
  /// This would typically involve another API call or local filtering.
  Future<List<String>> getSearchSuggestions(String partialQuery) async {
    if (partialQuery.trim().isEmpty) {
      return [];
    }
    // Simulate fetching suggestions
    // In a real app, this could be an API call or filtering from a local dataset
    await Future.delayed(const Duration(milliseconds: 200));
    final mockSuggestions = [
      '$partialQuery الأول',
      '$partialQuery الثاني',
      'اقتراح متعلق بـ $partialQuery',
      'المزيد عن $partialQuery',
    ];
    // Filter mock suggestions based on the partial query for a more realistic feel
    return mockSuggestions
        .where((s) => s.toLowerCase().contains(partialQuery.toLowerCase()))
        .take(5) // Limit suggestions
        .toList();
  }

  void dispose() {
    // Clean up any resources if needed
  }
}
