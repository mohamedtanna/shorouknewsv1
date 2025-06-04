import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart'; // For loading suggestions

import '../../core/theme.dart';
import '../../widgets/ad_banner.dart';
import 'search_module.dart'; // Import the module

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final SearchModule _searchModule = SearchModule();

  List<String> _recentSearches = [];
  List<String> _suggestions = [];
  bool _isLoadingRecent = true;
  bool _isLoadingSuggestions = false;
  String _currentSearchTerm = '';

  @override
  void initState() {
    super.initState();
    _loadRecentSearches();
    _searchController.addListener(_onSearchChanged);
    // Request focus on the search field when the screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_searchFocusNode);
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    _searchModule.dispose();
    super.dispose();
  }

  Future<void> _loadRecentSearches() async {
    setState(() => _isLoadingRecent = true);
    final searches = await _searchModule.getRecentSearches();
    if (mounted) {
      setState(() {
        _recentSearches = searches;
        _isLoadingRecent = false;
      });
    }
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();
    if (query.length > 1) { // Start fetching suggestions after 1 character
      if (_currentSearchTerm != query) { // Avoid redundant calls for same term
         _currentSearchTerm = query;
        _fetchSuggestions(query);
      }
    } else {
      setState(() => _suggestions = []);
    }
  }

  // Debounce fetching suggestions to avoid too many API calls
  Future<void> _fetchSuggestions(String query) async {
    setState(() => _isLoadingSuggestions = true);
    // Basic debounce
    await Future.delayed(const Duration(milliseconds: 300));
    if (query == _searchController.text.trim() && query.isNotEmpty) { // Check if query is still the same
      final suggestions = await _searchModule.getSearchSuggestions(query);
      if (mounted) {
        setState(() {
          _suggestions = suggestions;
          _isLoadingSuggestions = false;
        });
      }
    } else if (query.isEmpty) {
       if (mounted) {
        setState(() {
          _suggestions = [];
          _isLoadingSuggestions = false;
        });
      }
    }
  }

  void _performSearch(String query) {
    final trimmedQuery = query.trim();
    if (trimmedQuery.isNotEmpty) {
      _searchFocusNode.unfocus(); // Hide keyboard
      // Add to recent searches before navigating
      _searchModule.addRecentSearch(trimmedQuery).then((_) {
        _loadRecentSearches(); // Refresh recent searches list
      });
      context.goNamed('search-results',
          queryParameters: {'query': trimmedQuery});
    }
  }

  Future<void> _clearRecentSearches() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('مسح سجل البحث'),
          content: const Text('هل أنت متأكد أنك تريد مسح جميع عمليات البحث الأخيرة؟'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('إلغاء'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('مسح', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
    if (confirm == true) {
      await _searchModule.clearRecentSearches();
      _loadRecentSearches(); // Refresh the list
    }
  }
  
  Widget _buildBreadcrumb() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppTheme.tertiaryColor, width: 4),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.go('/home'),
            child: const Text(
              'الرئيسية',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
          const Text(' > ', style: TextStyle(fontWeight: FontWeight.bold)),
          const Text(
            'البحث',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('البحث في الشروق'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
      ),
      body: Column(
        children: [
          const AdBanner(adUnit: '/21765378867/ShorouknewsApp_LeaderBoard2'),
          _buildBreadcrumb(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              autofocus: true, // Automatically focus on the search field
              decoration: InputDecoration(
                hintText: 'ابحث عن أخبار، مقالات، أو كتّاب...',
                prefixIcon: const Icon(Icons.search, color: AppTheme.primaryColor),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _suggestions = []);
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30.0), // More rounded search bar
                  borderSide: BorderSide(color: AppTheme.primaryColor.withOpacity(0.5)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30.0),
                  borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 20.0),
              ),
              onSubmitted: _performSearch,
              textInputAction: TextInputAction.search,
            ),
          ),
          Expanded(
            child: _buildResultsArea(),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsArea() {
    if (_searchController.text.trim().isNotEmpty) {
      // Show suggestions if user is typing
      if (_isLoadingSuggestions) {
        return _buildSuggestionsLoadingShimmer();
      }
      if (_suggestions.isNotEmpty) {
        return _buildSuggestionsList();
      }
      // Optionally, show a "no suggestions" message or just let recent searches show
    }

    // Show recent searches if not typing or no suggestions
    if (_isLoadingRecent) {
      return _buildRecentSearchesLoadingShimmer();
    }
    if (_recentSearches.isNotEmpty) {
      return _buildRecentSearchesList();
    }

    return _buildEmptySearchState();
  }

  Widget _buildSuggestionsLoadingShimmer() {
    return ListView.builder(
      itemCount: 3,
      itemBuilder: (context, index) => Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: ListTile(
          leading: const Icon(Icons.search_outlined, color: Colors.white),
          title: Container(height: 16, width: double.infinity, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildSuggestionsList() {
    return ListView.builder(
      itemCount: _suggestions.length,
      itemBuilder: (context, index) {
        final suggestion = _suggestions[index];
        return ListTile(
          leading: const Icon(Icons.search_outlined, color: AppTheme.tertiaryColor),
          title: Text(suggestion),
          onTap: () {
            _searchController.text = suggestion; // Fill search bar
            _performSearch(suggestion);
          },
        );
      },
    );
  }

  Widget _buildRecentSearchesLoadingShimmer() {
     return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Container(height: 20, width: 120, color: Colors.white), // Shimmer for title
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 3,
          itemBuilder: (context, index) => Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: ListTile(
              leading: const Icon(Icons.history, color: Colors.white),
              title: Container(height: 16, width: double.infinity, color: Colors.white),
              trailing: const Icon(Icons.north_west, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentSearchesList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 0.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'عمليات البحث الأخيرة',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(color: AppTheme.primaryColor, fontWeight: FontWeight.bold),
              ),
              if (_recentSearches.isNotEmpty)
                TextButton(
                  onPressed: _clearRecentSearches,
                  child: const Text('مسح الكل', style: TextStyle(color: Colors.red, fontSize: 13)),
                ),
            ],
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _recentSearches.length,
          itemBuilder: (context, index) {
            final recentSearch = _recentSearches[index];
            return ListTile(
              leading: const Icon(Icons.history, color: Colors.grey),
              title: Text(recentSearch),
              trailing: const Icon(Icons.north_west, color: Colors.grey, size: 18), // Icon to indicate "fill search bar"
              onTap: () {
                _searchController.text = recentSearch; // Fill search bar
                _searchController.selection = TextSelection.fromPosition(TextPosition(offset: _searchController.text.length)); // Move cursor to end
                _performSearch(recentSearch);
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildEmptySearchState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'ابحث عن أي شيء في الشروق',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'يمكنك البحث عن أخبار، مقالات، أو أسماء كتّاب.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}
