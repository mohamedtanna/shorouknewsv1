import 'package:flutter/foundation.dart';

import '../models/new_model.dart';
import '../models/column_model.dart';
import '../services/api_service.dart';

class NewsProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  // Loading states
  bool _isLoadingMainStories = false;
  bool _isLoadingTopStories = false;
  bool _isLoadingMostRead = false;
  bool _isLoadingColumns = false;
  bool _isLoadingSections = false;

  // Data
  List<NewsArticle> _mainStories = [];
  List<NewsArticle> _topStories = [];
  List<NewsArticle> _mostReadStories = [];
  List<ColumnModel> _selectedColumns = [];
  List<NewsSection> _sections = [];

  // Pagination
  final Map<String, int> _currentPages = {};
  final Map<String, bool> _hasMoreData = {};

  // Getters
  bool get isLoadingMainStories => _isLoadingMainStories;
  bool get isLoadingTopStories => _isLoadingTopStories;
  bool get isLoadingMostRead => _isLoadingMostRead;
  bool get isLoadingColumns => _isLoadingColumns;
  bool get isLoadingSections => _isLoadingSections;

  List<NewsArticle> get mainStories => _mainStories;
  List<NewsArticle> get topStories => _topStories;
  List<NewsArticle> get mostReadStories => _mostReadStories;
  List<ColumnModel> get selectedColumns => _selectedColumns;
  List<NewsSection> get sections => _sections;

  // Load main stories
  Future<void> loadMainStories() async {
    if (_isLoadingMainStories) return;

    _isLoadingMainStories = true;
    notifyListeners();

    try {
      _mainStories = await _apiService.getMainStories();
    } catch (e) {
      debugPrint('Error loading main stories: $e');
    } finally {
      _isLoadingMainStories = false;
      notifyListeners();
    }
  }

  // Load top stories
  Future<void> loadTopStories() async {
    if (_isLoadingTopStories) return;

    _isLoadingTopStories = true;
    notifyListeners();

    try {
      _topStories = await _apiService.getTopStories();
    } catch (e) {
      debugPrint('Error loading top stories: $e');
    } finally {
      _isLoadingTopStories = false;
      notifyListeners();
    }
  }

  // Load most read stories
  Future<void> loadMostReadStories() async {
    if (_isLoadingMostRead) return;

    _isLoadingMostRead = true;
    notifyListeners();

    try {
      _mostReadStories = await _apiService.getMostReadStories();
    } catch (e) {
      debugPrint('Error loading most read stories: $e');
    } finally {
      _isLoadingMostRead = false;
      notifyListeners();
    }
  }

  // Load selected columns
  Future<void> loadSelectedColumns() async {
    if (_isLoadingColumns) return;

    _isLoadingColumns = true;
    notifyListeners();

    try {
      _selectedColumns = (await _apiService.getSelectedColumns()).cast<ColumnModel>();
    } catch (e) {
      debugPrint('Error loading selected columns: $e');
    } finally {
      _isLoadingColumns = false;
      notifyListeners();
    }
  }

  // Load sections
  Future<List<NewsSection>> loadSections() async {
    if (_isLoadingSections) return _sections;

    _isLoadingSections = true;
    notifyListeners();

    try {
      _sections = await _apiService.getSections();
      return _sections;
    } catch (e) {
      debugPrint('Error loading sections: $e');
      return _sections;
    } finally {
      _isLoadingSections = false;
      notifyListeners();
    }
  }

  // Load news with pagination
  Future<List<NewsArticle>> loadNews({
    String? sectionId,
    bool refresh = false,
  }) async {
    final key = sectionId ?? 'all';
    
    if (refresh) {
      _currentPages[key] = 1;
      _hasMoreData[key] = true;
    }

    final currentPage = _currentPages[key] ?? 1;
    final hasMore = _hasMoreData[key] ?? true;

    if (!hasMore) return [];

    try {
      final news = await _apiService.getNews(
        sectionId: sectionId,
        currentPage: currentPage,
      );

      _currentPages[key] = currentPage + 1;
      _hasMoreData[key] = news.isNotEmpty;

      return news;
    } catch (e) {
      debugPrint('Error loading news: $e');
      return [];
    }
  }

  // Get news detail
  Future<NewsArticle?> getNewsDetail(String cdate, String id) async {
    try {
      return await _apiService.getNewsDetail(cdate, id);
    } catch (e) {
      debugPrint('Error loading news detail: $e');
      return null;
    }
  }

  // Refresh all home data
  Future<void> refreshAllData() async {
    await Future.wait([
      loadMainStories(),
      loadTopStories(),
      loadMostReadStories(),
      loadSelectedColumns(),
    ]);
  }

  // Clear data
  void clearData() {
    _mainStories.clear();
    _topStories.clear();
    _mostReadStories.clear();
    _selectedColumns.clear();
    _sections.clear();
    _currentPages.clear();
    _hasMoreData.clear();
    notifyListeners();
  }
}