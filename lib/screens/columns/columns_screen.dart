import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:shimmer/shimmer.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../models/column_model.dart';
import '../../models/additional_models.dart';
// import '../../widgets/ad_banner.dart';
import '../../widgets/section_app_bar.dart';
import '../../widgets/section_header.dart';
import '../../core/theme.dart';
import 'columns_module.dart';
import '../../services/api_service.dart';
import '../../services/cache_manager.dart';
import '../../services/analytics_service.dart';

class ColumnsScreen extends StatefulWidget {
  final String? authorId;
  final String? categoryId;
  
  const ColumnsScreen({
    super.key,
    this.authorId,
    this.categoryId,
  });

  @override
  State<ColumnsScreen> createState() => _ColumnsScreenState();
}

class _ColumnsScreenState extends State<ColumnsScreen>
    with TickerProviderStateMixin {
  final ColumnsModule _columnsModule = ColumnsModule(
    apiService: ApiService(),
    cacheManager: CacheManager(),
    analyticsService: AnalyticsService(),
  );
  final RefreshController _refreshController = RefreshController();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  // Data
  List<ColumnModel> _allColumns = [];
  List<ColumnModel> _filteredColumns = [];
  List<ColumnModel> _selectedColumns = [];
  List<ColumnModel> _favoriteColumns = [];
  List<ColumnModel> _recentColumns = [];
  List<ColumnCategory> _categories = [];
  AuthorModel? _author;
  ColumnStats? _stats;

  // State
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMoreData = true;
  String? _errorMessage;
  String _searchQuery = '';
  ColumnSortBy _sortBy = ColumnSortBy.date;
  bool _sortAscending = false;
  ColumnViewMode _viewMode = ColumnViewMode.list;
  String? _selectedCategoryId;

  // Pagination
  int _currentPage = 1;
  static const int _pageSize = 10;

  // Animations
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // UI State
  bool _showSearchBar = false;
  bool _showFilters = false;
  bool _showFavorites = false;
  bool _showRecent = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initializeModule();
    _searchController.addListener(_onSearchChanged);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _refreshController.dispose();
    _scrollController.dispose();
    _searchController.dispose();
    _columnsModule.dispose();
    super.dispose();
  }

  void _setupAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutQuad,
    ));
  }

  Future<void> _initializeModule() async {
    await _columnsModule.initialize();
    
    // Listen to column events
    _columnsModule.eventStream.listen((event) {
      if (mounted) {
        switch (event.type) {
          case ColumnEventType.favoriteAdded:
          case ColumnEventType.favoriteRemoved:
            _loadFavoriteColumns();
            break;
          case ColumnEventType.viewed:
            _loadRecentColumns();
            break;
          default:
            break;
        }
      }
    });
    
    await _loadData();
  }

  Future<void> _loadData({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _hasMoreData = true;
    }

    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Load author info if needed
      if (widget.authorId != null) {
        await _loadAuthorInfo();
      }

      // Load categories
      await _loadCategories();

      // Load columns based on context
      if (widget.authorId != null) {
        await _loadAuthorColumns();
      } else if (widget.categoryId != null || _selectedCategoryId != null) {
        await _loadCategoryColumns();
      } else {
        await _loadAllColumns();
      }

      // Load additional data
      await Future.wait([
        _loadSelectedColumns(),
        _loadFavoriteColumns(),
        _loadRecentColumns(),
        _loadStatistics(),
      ]);

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        _fadeController.forward();
        _applySorting();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'فشل في تحميل المقالات';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadAuthorInfo() async {
    // In a real app, this would fetch author info
    // For now, we'll create mock data
    if (widget.authorId != null) {
      _author = AuthorModel(
        id: widget.authorId!,
        arName: 'اسم الكاتب',
        enName: 'Author Name',
        description: 'وصف الكاتب',
        photoUrl: 'https://example.com/author.jpg',
      );
    }
  }

  Future<void> _loadCategories() async {
    try {
      _categories = await _columnsModule.getColumnCategories();
    } catch (e) {
      debugPrint('Error loading categories: $e');
    }
  }

  Future<void> _loadAllColumns() async {
    final columns = await _columnsModule.getAllColumns(
      page: _currentPage,
      pageSize: _pageSize,
      forceRefresh: _currentPage == 1,
    );
    
    if (_currentPage == 1) {
      _allColumns = columns;
    } else {
      _allColumns.addAll(columns);
    }
    
    _filteredColumns = List.from(_allColumns);
    _hasMoreData = columns.length >= _pageSize;
  }

  Future<void> _loadAuthorColumns() async {
    if (widget.authorId == null) return;
    
    final columns = await _columnsModule.getColumnsByAuthor(
      widget.authorId!,
      page: _currentPage,
      pageSize: _pageSize,
      forceRefresh: _currentPage == 1,
    );
    
    if (_currentPage == 1) {
      _allColumns = columns;
    } else {
      _allColumns.addAll(columns);
    }
    
    _filteredColumns = List.from(_allColumns);
    _hasMoreData = columns.length >= _pageSize;
  }

  Future<void> _loadCategoryColumns() async {
    final categoryId = _selectedCategoryId ?? widget.categoryId;
    if (categoryId == null) return;
    
    final columns = await _columnsModule.getColumnsByCategory(
      categoryId,
      page: _currentPage,
      pageSize: _pageSize,
      forceRefresh: _currentPage == 1,
    );
    
    if (_currentPage == 1) {
      _allColumns = columns;
    } else {
      _allColumns.addAll(columns);
    }
    
    _filteredColumns = List.from(_allColumns);
    _hasMoreData = columns.length >= _pageSize;
  }

  Future<void> _loadSelectedColumns() async {
    try {
      _selectedColumns = await _columnsModule.getSelectedColumns();
    } catch (e) {
      debugPrint('Error loading selected columns: $e');
    }
  }

  Future<void> _loadFavoriteColumns() async {
    try {
      _favoriteColumns = await _columnsModule.getFavoriteColumns();
    } catch (e) {
      debugPrint('Error loading favorite columns: $e');
    }
  }

  Future<void> _loadRecentColumns() async {
    try {
      _recentColumns = await _columnsModule.getRecentlyViewedColumns(limit: 10);
    } catch (e) {
      debugPrint('Error loading recent columns: $e');
    }
  }

  Future<void> _loadStatistics() async {
    try {
      _stats = await _columnsModule.getColumnStatistics();
    } catch (e) {
      debugPrint('Error loading statistics: $e');
    }
  }

  Future<void> _loadMoreData() async {
    if (_isLoadingMore || !_hasMoreData) return;
    
    setState(() {
      _isLoadingMore = true;
    });
    
    _currentPage++;
    
    try {
      if (widget.authorId != null) {
        await _loadAuthorColumns();
      } else if (_selectedCategoryId != null) {
        await _loadCategoryColumns();
      } else {
        await _loadAllColumns();
      }
    } catch (e) {
      _currentPage--;
      debugPrint('Error loading more columns: $e');
    }
    
    setState(() {
      _isLoadingMore = false;
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreData();
    }
  }

  void _onSearchChanged() {
    final query = _searchController.text;
    setState(() {
      _searchQuery = query;
    });
    _filterColumns();
  }

  void _filterColumns() {
    setState(() {
      if (_searchQuery.isEmpty) {
        _filteredColumns = List.from(_allColumns);
      } else {
        _filteredColumns = _allColumns.where((column) {
          return column.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                 column.columnistArName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                 column.summary.toLowerCase().contains(_searchQuery.toLowerCase());
        }).toList();
      }
    });
    _applySorting();
  }

  void _applySorting() {
    setState(() {
      _filteredColumns.sort((a, b) {
        int comparison = 0;
        
        switch (_sortBy) {
          case ColumnSortBy.date:
            comparison = a.creationDate.compareTo(b.creationDate);
            break;
          case ColumnSortBy.title:
            comparison = a.title.compareTo(b.title);
            break;
          case ColumnSortBy.author:
            comparison = a.columnistArName.compareTo(b.columnistArName);
            break;
          case ColumnSortBy.popularity:
            final aViews = _columnsModule.getColumnViewCount(a.id);
            final bViews = _columnsModule.getColumnViewCount(b.id);
            comparison = aViews.compareTo(bViews);
            break;
        }

        return _sortAscending ? comparison : -comparison;
      });
    });
  }

  Future<void> _onRefresh() async {
    _columnsModule.clearCache();
    await _loadData(refresh: true);
    _refreshController.refreshCompleted();
  }

  void _toggleSearch() {
    setState(() {
      _showSearchBar = !_showSearchBar;
    });
    
    if (_showSearchBar) {
      _slideController.forward();
    } else {
      _slideController.reverse();
      _searchController.clear();
    }
  }

  void _toggleFilters() {
    setState(() {
      _showFilters = !_showFilters;
    });
  }

  void _showSortDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ترتيب المقالات'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ...ColumnSortBy.values.map((sortBy) => RadioListTile<ColumnSortBy>(
              title: Text(_getSortByLabel(sortBy)),
              value: sortBy,
              groupValue: _sortBy,
              onChanged: (value) {
                setState(() {
                  _sortBy = value!;
                });
                _applySorting();
                Navigator.pop(context);
              },
            )),
            const Divider(),
            SwitchListTile(
              title: const Text('ترتيب تصاعدي'),
              value: _sortAscending,
              onChanged: (value) {
                setState(() {
                  _sortAscending = value;
                });
                _applySorting();
                Navigator.pop(context);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  String _getSortByLabel(ColumnSortBy sortBy) {
    switch (sortBy) {
      case ColumnSortBy.date:
        return 'التاريخ';
      case ColumnSortBy.title:
        return 'العنوان';
      case ColumnSortBy.author:
        return 'الكاتب';
      case ColumnSortBy.popularity:
        return 'الأكثر قراءة';
    }
  }

  void _selectCategory(String? categoryId) {
    setState(() {
      _selectedCategoryId = categoryId;
      _currentPage = 1;
      _hasMoreData = true;
    });
    _loadData(refresh: true);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _isLoading && _currentPage == 1 ? _buildLoadingWidget() : _buildContent(),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return SectionAppBar(
      title: Text(_getAppBarTitle()),
      automaticallyImplyLeading: false,
      actions: [
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: _toggleSearch,
        ),
        IconButton(
          icon: const Icon(Icons.sort),
          onPressed: _showSortDialog,
        ),
        PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'view_mode':
                setState(() {
                  _viewMode = _viewMode == ColumnViewMode.list 
                      ? ColumnViewMode.grid 
                      : ColumnViewMode.list;
                });
                break;
              case 'filters':
                _toggleFilters();
                break;
              case 'favorites':
                setState(() {
                  _showFavorites = !_showFavorites;
                });
                break;
              case 'recent':
                setState(() {
                  _showRecent = !_showRecent;
                });
                break;
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'view_mode',
              child: Row(
                children: [
                  Icon(_viewMode == ColumnViewMode.list ? Icons.grid_view : Icons.list),
                  const SizedBox(width: 8),
                  Text(_viewMode == ColumnViewMode.list ? 'عرض شبكة' : 'عرض قائمة'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'filters',
              child: Row(
                children: [
                  Icon(Icons.filter_list),
                  SizedBox(width: 8),
                  Text('الفلاتر'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'favorites',
              child: Row(
                children: [
                  Icon(_showFavorites ? Icons.favorite : Icons.favorite_border),
                  const SizedBox(width: 8),
                  Text(_showFavorites ? 'إخفاء المفضلة' : 'إظهار المفضلة'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'recent',
              child: Row(
                children: [
                  Icon(_showRecent ? Icons.history : Icons.history_outlined),
                  const SizedBox(width: 8),
                  Text(_showRecent ? 'إخفاء الحديثة' : 'إظهار الحديثة'),
                ],
              ),
            ),
          ],
        ),
      ],
      bottom: PreferredSize(
        preferredSize: Size.fromHeight(_showSearchBar ? 120 : (_showFilters ? 60 : 0)),
        child: Column(
          children: [
            if (_showSearchBar) _buildSearchBar(),
            if (_showFilters) _buildFilterBar(),
          ],
        ),
      ),
    );
  }

  String _getAppBarTitle() {
    if (widget.authorId != null && _author != null) {
      return 'مقالات ${_author!.arName}';
    } else if (_selectedCategoryId != null || widget.categoryId != null) {
      final categoryId = _selectedCategoryId ?? widget.categoryId;
      final category = _categories.firstWhere(
        (c) => c.id == categoryId,
        orElse: () => ColumnCategory(id: '', name: 'القسم', columnsCount: 0),
      );
      return category.name;
    }
    return 'رأي ومقالات';
  }

  Widget _buildSearchBar() {
    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        padding: const EdgeInsets.all(8),
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'البحث في المقالات...',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                    },
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
          autofocus: true,
        ),
      ),
    );
  }

  Widget _buildFilterBar() {
    return SizedBox(
      height: 60,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          // All categories
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: FilterChip(
              label: const Text('الكل'),
              selected: _selectedCategoryId == null,
              onSelected: (_) => _selectCategory(null),
              backgroundColor: Colors.grey[200],
              selectedColor: AppTheme.primaryColor.withOpacity(0.2),
              checkmarkColor: AppTheme.primaryColor,
            ),
          ),
          
          // Category filters
          ..._categories.map((category) => Padding(
            padding: const EdgeInsets.only(left: 8),
            child: FilterChip(
              label: Text('${category.name} (${category.columnsCount})'),
              selected: _selectedCategoryId == category.id,
              onSelected: (_) => _selectCategory(category.id),
              backgroundColor: Colors.grey[200],
              selectedColor: AppTheme.primaryColor.withOpacity(0.2),
              checkmarkColor: AppTheme.primaryColor,
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
          children: [
            // const AdBanner(adUnit: '/21765378867/ShorouknewsApp_LeaderBoard2'),
          const SizedBox(height: 16),
          ...List.generate(5, (index) => _buildShimmerColumnCard()),
        ],
      ),
    );
  }

  Widget _buildShimmerColumnCard() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        height: 16,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: 150,
                        height: 12,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        height: 40,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_errorMessage != null) {
      return _buildErrorWidget();
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SmartRefresher(
        controller: _refreshController,
        enablePullDown: true,
        enablePullUp: false,
        onRefresh: _onRefresh,
        child: CustomScrollView(
          controller: _scrollController,
            slivers: [
              // Ad Banner
              // const SliverToBoxAdapter(
              //   child: AdBanner(adUnit: '/21765378867/ShorouknewsApp_LeaderBoard2'),
              // ),

            // Breadcrumb
            SliverToBoxAdapter(
              child: _buildBreadcrumb(),
            ),

            // Author Section (if applicable)
            if (_author != null)
              SliverToBoxAdapter(
                child: _buildAuthorSection(),
              ),

            // Quick Stats
            if (_stats != null && widget.authorId == null)
              SliverToBoxAdapter(
                child: _buildQuickStats(),
              ),

            // Selected Columns Section
            if (_selectedColumns.isNotEmpty && widget.authorId == null)
              SliverToBoxAdapter(
                child: _buildSelectedColumnsSection(),
              ),

            // Favorite Columns Section
            if (_showFavorites && _favoriteColumns.isNotEmpty)
              SliverToBoxAdapter(
                child: _buildFavoriteColumnsSection(),
              ),

            // Recent Columns Section
            if (_showRecent && _recentColumns.isNotEmpty)
              SliverToBoxAdapter(
                child: _buildRecentColumnsSection(),
              ),

            // All Columns Section
            SliverToBoxAdapter(
              child: SectionHeader(
                title: _searchQuery.isNotEmpty ? 'نتائج البحث' : 'جميع المقالات',
                subtitle: '${_filteredColumns.length} مقال',
                icon: Icons.article,
              ),
            ),

            // Columns List/Grid
            if (_viewMode == ColumnViewMode.grid)
              SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.75,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (index < _filteredColumns.length) {
                      return _buildColumnGridCard(_filteredColumns[index]);
                    }
                    return null;
                  },
                  childCount: _filteredColumns.length,
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (index < _filteredColumns.length) {
                      return _buildColumnListCard(_filteredColumns[index]);
                    }
                    return null;
                  },
                  childCount: _filteredColumns.length,
                ),
              ),

            // Loading more indicator
            if (_isLoadingMore)
              SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  alignment: Alignment.center,
                  child: const CircularProgressIndicator(),
                ),
              ),

            // Empty State
            if (_filteredColumns.isEmpty && !_isLoading)
              SliverToBoxAdapter(
                child: _buildEmptyState(),
              ),

            // Bottom spacing
            const SliverToBoxAdapter(
              child: SizedBox(height: 80),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            _errorMessage!,
            style: const TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _loadData(refresh: true),
            child: const Text('إعادة المحاولة'),
          ),
        ],
      ),
    );
  }

  Widget _buildBreadcrumb() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(
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
          if (widget.authorId != null && _author != null) ...[
            GestureDetector(
              onTap: () => context.push('/columns'),
              child: const Text(
                'رأي ومقالات',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
            const Text(' > ', style: TextStyle(fontWeight: FontWeight.bold)),
            Text(
              _author!.arName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ] else if (_selectedCategoryId != null) ...[
            GestureDetector(
              onTap: () {
                setState(() {
                  _selectedCategoryId = null;
                });
                _loadData(refresh: true);
              },
              child: const Text(
                'رأي ومقالات',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
            const Text(' > ', style: TextStyle(fontWeight: FontWeight.bold)),
            Text(
              _categories.firstWhere((c) => c.id == _selectedCategoryId).name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ] else ...[
            const Text(
              'رأي ومقالات',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAuthorSection() {
    if (_author == null) return const SizedBox.shrink();
    
    return Container(
      margin: const EdgeInsets.all(16),
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Author Photo
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.tertiaryColor, width: 3),
                ),
                child: ClipOval(
                  child: CachedNetworkImage(
                    imageUrl: _author!.photoUrl,
                    fit: BoxFit.cover,
                    filterQuality: FilterQuality.high,
                    placeholder: (context, url) => Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.person, size: 40),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.person, size: 40),
                    ),
                  ),
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Author Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _author!.arName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _author!.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                        height: 1.4,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${_allColumns.length} مقال',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.tertiaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStats() {
    if (_stats == null) return const SizedBox.shrink();
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _buildStatItem(
            'إجمالي المقالات',
            _stats!.totalColumns.toString(),
            Icons.article,
          ),
          _buildStatItem(
            'المفضلة',
            _stats!.totalFavorites.toString(),
            Icons.favorite,
          ),
          _buildStatItem(
            'المقروءة',
            _stats!.totalReads.toString(),
            Icons.done_all,
          ),
          _buildStatItem(
            'المشاهدات',
            _formatNumber(_stats!.totalViews),
            Icons.visibility,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedColumnsSection() {
    return Column(
      children: [
        SectionHeader(
          title: 'مقالات مختارة',
          icon: Icons.star,
          subtitle: '${_selectedColumns.length} مقال',
        ),
        SizedBox(
          height: 280,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _selectedColumns.length,
            itemBuilder: (context, index) {
              return _buildHorizontalColumnCard(_selectedColumns[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFavoriteColumnsSection() {
    return Column(
      children: [
        SectionHeader(
          title: 'المقالات المفضلة',
          icon: Icons.favorite,
          subtitle: '${_favoriteColumns.length} مقال',
        ),
        SizedBox(
          height: 280,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _favoriteColumns.length,
            itemBuilder: (context, index) {
              return _buildHorizontalColumnCard(_favoriteColumns[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRecentColumnsSection() {
    return Column(
      children: [
        SectionHeader(
          title: 'مشاهدة مؤخراً',
          icon: Icons.history,
          subtitle: '${_recentColumns.length} مقال',
        ),
        SizedBox(
          height: 280,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _recentColumns.length,
            itemBuilder: (context, index) {
              return _buildHorizontalColumnCard(_recentColumns[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHorizontalColumnCard(ColumnModel column) {
    final isFavorite = _columnsModule.isColumnFavorite(column.id);
    final isRead = _columnsModule.isColumnRead(column.id);
    
    return Container(
      width: 220,
      margin: const EdgeInsets.only(left: 12),
      child: Card(
        elevation: 2,
        child: InkWell(
          onTap: () => context.push('/column/${column.cDate}/${column.id}'),
          borderRadius: BorderRadius.circular(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with author info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.05),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                ),
                child: Row(
                  children: [
                    // Author photo
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.tertiaryColor, width: 2),
                      ),
                      child: ClipOval(
                        child: CachedNetworkImage(
                          imageUrl: column.columnistPhotoUrl,
                          fit: BoxFit.cover,
                          filterQuality: FilterQuality.high,
                          placeholder: (context, url) => Container(
                            color: Colors.grey[300],
                            child: const Icon(Icons.person, size: 20),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: Colors.grey[300],
                            child: const Icon(Icons.person, size: 20),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Author name
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            column.columnistArName,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            _formatDate(DateTime.parse(column.creationDate)),
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Read indicator
                    if (isRead)
                      const Icon(
                        Icons.done_all,
                        size: 16,
                        color: AppTheme.tertiaryColor,
                      ),
                  ],
                ),
              ),
              
              // Title
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  column.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              
              // Summary
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    column.summary,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[700],
                      height: 1.4,
                    ),
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              
              // Actions
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Views count
                    Row(
                      children: [
                        Icon(Icons.visibility, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          _formatNumber(_columnsModule.getColumnViewCount(column.id)),
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                    // Actions
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            isFavorite ? Icons.favorite : Icons.favorite_border,
                            size: 20,
                            color: isFavorite ? Colors.red : Colors.grey,
                          ),
                          onPressed: () => _toggleFavorite(column),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: Icon(
                            Icons.share,
                            size: 20,
                            color: Colors.grey[600],
                          ),
                          onPressed: () => _shareColumn(column),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildColumnGridCard(ColumnModel column) {
    final isFavorite = _columnsModule.isColumnFavorite(column.id);
    final isRead = _columnsModule.isColumnRead(column.id);
    final isBookmarked = _columnsModule.isColumnBookmarked(column.id);
    
    return Container(
      margin: const EdgeInsets.all(8),
      child: Card(
        elevation: 2,
        child: InkWell(
          onTap: () => context.push('/column/${column.cDate}/${column.id}'),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Author info
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.tertiaryColor),
                      ),
                      child: ClipOval(
                        child: CachedNetworkImage(
                          imageUrl: column.columnistPhotoUrl,
                          fit: BoxFit.cover,
                          filterQuality: FilterQuality.high,
                          placeholder: (context, url) => Container(
                            color: Colors.grey[300],
                            child: const Icon(Icons.person, size: 18),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: Colors.grey[300],
                            child: const Icon(Icons.person, size: 18),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            column.columnistArName,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                              _formatDate(DateTime.parse(column.creationDate)),
                            style: TextStyle(
                              fontSize: 9,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isRead)
                      const Icon(
                        Icons.done_all,
                        size: 14,
                        color: AppTheme.tertiaryColor,
                      ),
                  ],
                ),
                
                const SizedBox(height: 8),
                
                // Title
                Text(
                  column.title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                
                const SizedBox(height: 8),
                
                // Summary
                Expanded(
                  child: Text(
                    column.summary,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[700],
                      height: 1.3,
                    ),
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // Bottom row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Views
                    Row(
                      children: [
                        Icon(Icons.visibility, size: 12, color: Colors.grey[600]),
                        const SizedBox(width: 2),
                        Text(
                          _formatNumber(_columnsModule.getColumnViewCount(column.id)),
                          style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                    // Icons
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isFavorite)
                          const Icon(Icons.favorite, size: 14, color: Colors.red),
                        if (isBookmarked)
                          const Icon(Icons.bookmark, size: 14, color: AppTheme.primaryColor),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildColumnListCard(ColumnModel column) {
    final isFavorite = _columnsModule.isColumnFavorite(column.id);
    final isRead = _columnsModule.isColumnRead(column.id);
    final isBookmarked = _columnsModule.isColumnBookmarked(column.id);
    final viewCount = _columnsModule.getColumnViewCount(column.id);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        elevation: 2,
        child: InkWell(
          onTap: () => context.push('/column/${column.cDate}/${column.id}'),
          borderRadius: BorderRadius.circular(8),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isRead 
                      ? Colors.grey[50] 
                      : AppTheme.primaryColor.withOpacity(0.05),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                ),
                child: Row(
                  children: [
                    // Author photo
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppTheme.tertiaryColor,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: CachedNetworkImage(
                          imageUrl: column.columnistPhotoUrl,
                          fit: BoxFit.cover,
                          filterQuality: FilterQuality.high,
                          placeholder: (context, url) => Container(
                            color: Colors.grey[300],
                            child: const Icon(Icons.person, size: 30),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: Colors.grey[300],
                            child: const Icon(Icons.person, size: 30),
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(width: 16),
                    
                    // Column info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title
                          Text(
                            column.title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isRead ? Colors.grey[700] : AppTheme.primaryColor,
                              height: 1.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          
                          const SizedBox(height: 8),
                          
                          // Author and date
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  column.columnistArName,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: AppTheme.tertiaryColor,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                _formatDate(DateTime.parse(column.creationDate)),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Summary
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Text(
                  column.summary,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                    height: 1.5,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              
              // Actions bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)),
                ),
                child: Row(
                  children: [
                    // Stats
                    Row(
                      children: [
                        _buildStatChip(Icons.visibility, _formatNumber(viewCount)),
                        const SizedBox(width: 12),
                        if (isRead)
                          _buildStatChip(Icons.done_all, 'مقروء', color: AppTheme.tertiaryColor),
                      ],
                    ),
                    
                    const Spacer(),
                    
                    // Actions
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                            size: 22,
                            color: isBookmarked ? AppTheme.primaryColor : Colors.grey[600],
                          ),
                          onPressed: () => _toggleBookmark(column),
                          padding: const EdgeInsets.all(8),
                          constraints: const BoxConstraints(),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: Icon(
                            isFavorite ? Icons.favorite : Icons.favorite_border,
                            size: 22,
                            color: isFavorite ? Colors.red : Colors.grey[600],
                          ),
                          onPressed: () => _toggleFavorite(column),
                          padding: const EdgeInsets.all(8),
                          constraints: const BoxConstraints(),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: Icon(
                            Icons.share,
                            size: 22,
                            color: Colors.grey[600],
                          ),
                          onPressed: () => _shareColumn(column),
                          padding: const EdgeInsets.all(8),
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String label, {Color? color}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color ?? Colors.grey[600]),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: color ?? Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _searchQuery.isNotEmpty ? Icons.search_off : Icons.article_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty 
                  ? 'لا توجد نتائج للبحث'
                  : 'لا توجد مقالات',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isNotEmpty 
                  ? 'جرب البحث باستخدام كلمات أخرى'
                  : 'سيتم عرض المقالات هنا',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            if (_searchQuery.isNotEmpty) ...[
              const SizedBox(height: 24),
              OutlinedButton.icon(
                icon: const Icon(Icons.clear),
                label: const Text('مسح البحث'),
                onPressed: () {
                  _searchController.clear();
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget? _buildFloatingActionButton() {
    // Show scroll to top button when scrolled down
    if (_scrollController.hasClients && _scrollController.offset > 500) {
      return FloatingActionButton(
        mini: true,
        backgroundColor: AppTheme.primaryColor,
        onPressed: () {
          _scrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        },
        child: const Icon(Icons.arrow_upward, color: Colors.white),
      );
    }
    return null;
  }

  // Helper methods

  Future<void> _toggleFavorite(ColumnModel column) async {
    HapticFeedback.lightImpact();
    
    final isFavorite = _columnsModule.isColumnFavorite(column.id);
    
    if (isFavorite) {
      await _columnsModule.removeColumnFromFavorites(column.id);
      _showMessage('تم إزالة المقال من المفضلة');
    } else {
      await _columnsModule.addColumnToFavorites(column);
      _showMessage('تم إضافة المقال إلى المفضلة');
    }
    
    await _loadFavoriteColumns();
    setState(() {});
  }

  Future<void> _toggleBookmark(ColumnModel column) async {
    HapticFeedback.lightImpact();
    
    final isBookmarked = _columnsModule.isColumnBookmarked(column.id);
    
    if (isBookmarked) {
      await _columnsModule.removeColumnFromBookmarks(column.id);
      _showMessage('تم إزالة الإشارة المرجعية');
    } else {
      await _columnsModule.addColumnToBookmarks(column);
      _showMessage('تم إضافة إشارة مرجعية');
    }
    
    setState(() {});
  }

  Future<void> _shareColumn(ColumnModel column) async {
    final shareLink = _columnsModule.generateShareLink(column);
    final shareText = 'اقرأ مقال "${column.title}" بقلم ${column.columnistArName}';
    
    try {
      await Share.share('$shareText\n\n$shareLink');
      _columnsModule.logColumnEngagement(column.id, 'share');
    } catch (e) {
      debugPrint('Error sharing column: $e');
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('yyyy/MM/dd HH:mm', 'ar').format(date);
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}م';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}ك';
    }
    return number.toString();
  }
}

// Enums
enum ColumnViewMode {
  list,
  grid,
}
