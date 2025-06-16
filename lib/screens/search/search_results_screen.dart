import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart'; // For loading effects

import 'package:shorouk_news/models/new_model.dart';
import '../../widgets/news_card.dart'; // To display each search result
// import '../../widgets/ad_banner.dart';
import '../../core/theme.dart';
import 'search_module.dart'; // To perform the search

class SearchResultsScreen extends StatefulWidget {
  final String query;

  const SearchResultsScreen({super.key, required this.query});

  @override
  State<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen> {
  final SearchModule _searchModule = SearchModule();
  final ScrollController _scrollController = ScrollController();

  List<NewsArticle> _results = [];
  bool _isLoadingFirstLoad = true; // For initial shimmer effect
  bool _isLoadingMore = false; // For loading more results on scroll
  bool _hasMoreData = true; // To know if more pages can be fetched
  String? _error; // To store any error message during fetching
  int _currentPage = 1;
  final int _pageSize = 15; // Number of results to fetch per page

  @override
  void initState() {
    super.initState();
    // Fetch initial results when the screen is created
    _fetchResults(isInitialLoad: true);
    // Add listener to scroll controller for pagination
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchModule.dispose(); // Dispose the module if it has resources
    super.dispose();
  }

  /// Fetches search results from the SearchModule.
  ///
  /// [refresh]: If true, clears existing results and fetches from page 1.
  /// [isInitialLoad]: If true, sets the initial loading state.
  Future<void> _fetchResults(
      {bool refresh = false, bool isInitialLoad = false}) async {
    // Do not fetch if query is empty, show empty state instead
    if (widget.query.trim().isEmpty) {
      if (mounted) {
        setState(() {
          _isLoadingFirstLoad = false;
          _results = [];
          _hasMoreData = false; // No data to fetch for an empty query
        });
      }
      return;
    }

    if (refresh) {
      _currentPage = 1;
      _results.clear(); // Clear previous results on refresh
      _hasMoreData = true; // Reset pagination flag
    }

    if (!mounted) return;
    setState(() {
      if (isInitialLoad || (refresh && _results.isEmpty)) {
        _isLoadingFirstLoad = true;
      }
      if (!isInitialLoad && !refresh) {
        _isLoadingMore = true; // Show loading more indicator
      }
      _error = null; // Clear previous errors
    });

    try {
      final newResults = await _searchModule.performSearch(
        widget.query,
        page: _currentPage,
        pageSize: _pageSize,
      );
      if (mounted) {
        setState(() {
          // If refreshing, replace results. Otherwise, append.
          if (refresh) _results.clear();
          _results.addAll(newResults);
          _hasMoreData =
              newResults.length >= _pageSize; // Update based on fetched count
          _isLoadingFirstLoad = false;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'فشل في تحميل نتائج البحث.';
          debugPrint(
              'Search results error for query "${widget.query}", page $_currentPage: $e');
          _isLoadingFirstLoad = false;
          _isLoadingMore = false;
          // Optionally, if an error occurs loading more, you might want to decrement _currentPage
          // if (refresh == false) _currentPage--;
        });
      }
    }
  }

  /// Listener for scroll events to trigger loading more results.
  void _onScroll() {
    // Check if scrolled to near the bottom, not currently loading, and more data might exist
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 300 &&
        !_isLoadingFirstLoad &&
        !_isLoadingMore &&
        _hasMoreData) {
      _currentPage++;
      _fetchResults(); // Fetch next page
    }
  }

  /// Builds the breadcrumb navigation path.
  Widget _buildBreadcrumb() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).canvasColor, // Use canvasColor for consistency
        border: const Border(
          bottom: BorderSide(color: AppTheme.tertiaryColor, width: 4),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: const Text(
              'الرئيسية',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
          const Text(' > ', style: TextStyle(fontWeight: FontWeight.bold)),
          GestureDetector(
            onTap: () =>
                context.push('/search'), // Navigate back to search input screen
            child: const Text(
              'البحث',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
          const Text(' > ', style: TextStyle(fontWeight: FontWeight.bold)),
          Expanded(
            child: Text(
              'نتائج: "${widget.query}"',
              style: const TextStyle(fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis, // Handle long query texts
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text('نتائج البحث عن: "${widget.query}"',
            style: const TextStyle(fontSize: 18)),
      ),
        body: Column(
          children: [
          // const AdBanner(adUnit: '/21765378867/ShorouknewsApp_LeaderBoard2'),
          _buildBreadcrumb(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () =>
                  _fetchResults(refresh: true, isInitialLoad: true),
              color: AppTheme.primaryColor,
              child: _buildBody(),
            ),
          ),
        ],
      ),
    );
  }

  /// Determines which widget to display based on the current state (loading, error, empty, or results).
  Widget _buildBody() {
    if (_isLoadingFirstLoad) {
      return _buildLoadingShimmer();
    }
    if (_error != null && _results.isEmpty) {
      return _buildErrorWidget();
    }
    if (_results.isEmpty) {
      return _buildEmptyState();
    }
    return _buildResultsList();
  }

  /// Builds the shimmer effect for when results are initially loading.
  Widget _buildLoadingShimmer() {
    return ListView.builder(
      itemCount: 7, // Display a few shimmer placeholders
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                    width: 110,
                    height: 85,
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8))),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Container(
                          height: 16,
                          width: double.infinity,
                          decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4))),
                      const SizedBox(height: 8),
                      Container(
                          height: 12,
                          width: MediaQuery.of(context).size.width * 0.5,
                          decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4))),
                      const SizedBox(height: 8),
                      Container(
                          height: 10,
                          width: MediaQuery.of(context).size.width * 0.3,
                          decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4))),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Builds the widget to display when an error occurs and no results are loaded.
  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off_outlined, color: Colors.red, size: 70),
            const SizedBox(height: 20),
            Text(
              _error ?? 'حدث خطأ أثناء تحميل النتائج.',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: Colors.black87),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة المحاولة'),
              onPressed: () =>
                  _fetchResults(refresh: true, isInitialLoad: true),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the widget to display when no search results are found.
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 20),
            Text(
              'لا توجد نتائج للبحث عن "${widget.query}"',
              style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'يرجى المحاولة باستخدام كلمات بحث مختلفة أو التأكد من الإملاء.',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () =>
                  context.push('/search'), // Navigate back to search input
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.tertiaryColor,
                  foregroundColor: Colors.white),
              child: const Text('العودة إلى شاشة البحث'),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the list of search results.
  Widget _buildResultsList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      itemCount: _results.length +
          (_isLoadingMore
              ? 1
              : 0), // Add one for loading indicator if loading more
      itemBuilder: (context, index) {
        if (index == _results.length) {
          // This is the last item - show loading indicator if there's more data being fetched
          return _isLoadingMore
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20.0),
                  child: Center(
                      child: CircularProgressIndicator(
                          color: AppTheme.primaryColor)),
                )
              : const SizedBox
                  .shrink(); // Or a "No more results" message if _hasMoreData is false
        }
        final article = _results[index];
        return NewsCard(
          article: article,
          isHorizontal:
              true, // Use horizontal card style for search results list
          onTap: () => context.push('/news/${article.cDate}/${article.id}'),
          // Pass the query for potential highlighting if needed
        );
      },
    );
  }
}

// Helper widget for shimmer boxes (can be moved to a common widgets file if used elsewhere)
// ignore: unused_element
class _ShimmerBox extends StatelessWidget {
  final double height;
  final double width;
  const _ShimmerBox({required this.height, required this.width});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
