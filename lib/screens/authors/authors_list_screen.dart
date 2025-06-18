import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:shimmer/shimmer.dart';

import '../../models/additional_models.dart';
// import '../../widgets/ad_banner.dart';
import '../../widgets/section_header.dart';
import '../../widgets/section_app_bar.dart';
import '../../core/theme.dart';
import 'author_module.dart';
import 'package:intl/intl.dart';

class AuthorsListScreen extends StatefulWidget {
  const AuthorsListScreen({super.key});

  @override
  State<AuthorsListScreen> createState() => _AuthorsListScreenState();
}

class _AuthorsListScreenState extends State<AuthorsListScreen>
    with TickerProviderStateMixin {
  final AuthorModule _authorModule = AuthorModule();
  final RefreshController _refreshController = RefreshController();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchTextController = TextEditingController();

  // Data
  List<AuthorModel> _allAuthors = [];
  List<AuthorModel> _filteredAuthors = [];
  List<AuthorModel> _favoriteAuthors = [];
  List<AuthorModel> _recentlyViewedAuthors = [];
  final Map<String, AuthorStats> _authorsStats = {};

  // State
  bool _isLoading = true;
  bool _isSearching = false;
  String? _errorMessage;
  String _searchQuery = '';
  AuthorSortBy _sortBy = AuthorSortBy.name;
  bool _sortAscending = true;
  AuthorViewMode _viewMode = AuthorViewMode.grid;

  // Animations
  late AnimationController _fadeController;
  late AnimationController _searchAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _searchAnimation;

  // UI State
  bool _showSearchBar = false;
  bool _showFavorites = false;
  bool _showRecent = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initializeModule();
    _searchTextController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _searchAnimationController.dispose();
    _refreshController.dispose();
    _scrollController.dispose();
    _searchTextController.dispose();
    _authorModule.dispose();
    super.dispose();
  }

  void _setupAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _searchAnimationController = AnimationController(
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

    _searchAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _searchAnimationController,
      curve: Curves.easeInOut,
    ));
  }

  Future<void> _initializeModule() async {
    await _authorModule.initialize();
    await _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        _allAuthors = await _authorModule.getAllAuthors();
      } catch (_) {
        // Fallback to mock data if API fails
        await _loadMockAuthors();
      }
      
      // Load favorites and recent authors
      await _loadFavoriteAuthors();
      await _loadRecentlyViewedAuthors();
      
      // Load statistics for each author
      await _loadAuthorsStatistics();

      if (mounted) {
        setState(() {
          _filteredAuthors = List.from(_allAuthors);
          _isLoading = false;
        });

        _fadeController.forward();
        _applySorting();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'فشل في تحميل قائمة الكتّاب';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadMockAuthors() async {
    // Mock data - in real app, this would come from API
    _allAuthors = [
      AuthorModel(
        id: '1',
        arName: 'أحمد محمد',
        enName: 'Ahmed Mohamed',
        description: 'كاتب صحفي متخصص في الشؤون السياسية والاقتصادية',
        photoUrl: 'https://example.com/author1.jpg',
      ),
      AuthorModel(
        id: '2',
        arName: 'فاطمة علي',
        enName: 'Fatma Ali',
        description: 'محررة في قسم الثقافة والفنون',
        photoUrl: 'https://example.com/author2.jpg',
      ),
      AuthorModel(
        id: '3',
        arName: 'محمد إبراهيم',
        enName: 'Mohamed Ibrahim',
        description: 'كاتب متخصص في الشؤون الرياضية',
        photoUrl: 'https://example.com/author3.jpg',
      ),
      AuthorModel(
        id: '4',
        arName: 'سارة أحمد',
        enName: 'Sara Ahmed',
        description: 'محررة الشؤون الاجتماعية والصحة',
        photoUrl: 'https://example.com/author4.jpg',
      ),
      AuthorModel(
        id: '5',
        arName: 'خالد عبدالله',
        enName: 'Khaled Abdullah',
        description: 'كاتب في الشؤون التكنولوجية والعلمية',
        photoUrl: 'https://example.com/author5.jpg',
      ),
    ];
  }

  Future<void> _loadFavoriteAuthors() async {
    try {
      _favoriteAuthors = await _authorModule.getFavoriteAuthors();
    } catch (e) {
      debugPrint('Error loading favorite authors: $e');
    }
  }

  Future<void> _loadRecentlyViewedAuthors() async {
    try {
      final recentIds = _authorModule.getRecentlyVisitedAuthors(limit: 5);
      _recentlyViewedAuthors = [];
      
      for (final id in recentIds) {
        try {
          final author = await _authorModule.getAuthor(id);
          _recentlyViewedAuthors.add(author);
        } catch (e) {
          // Skip if author not found
        }
      }
    } catch (e) {
      debugPrint('Error loading recently viewed authors: $e');
    }
  }

  Future<void> _loadAuthorsStatistics() async {
    try {
      for (final author in _allAuthors) {
        final stats = await _authorModule.getAuthorStats(author.id);
        _authorsStats[author.id] = stats;
      }
    } catch (e) {
      debugPrint('Error loading authors statistics: $e');
    }
  }

  void _onSearchChanged() {
    final query = _searchTextController.text;
    setState(() {
      _searchQuery = query;
      _isSearching = query.isNotEmpty;
    });
    _filterAuthors();
  }

  void _filterAuthors() {
    setState(() {
      if (_searchQuery.isEmpty) {
        _filteredAuthors = List.from(_allAuthors);
      } else {
        _filteredAuthors = _allAuthors.where((author) {
          return author.arName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                 author.description.toLowerCase().contains(_searchQuery.toLowerCase());
        }).toList();
      }
    });
    _applySorting();
  }

  void _applySorting() {
    setState(() {
      _filteredAuthors.sort((a, b) {
        int comparison = 0;
        
        switch (_sortBy) {
          case AuthorSortBy.name:
            comparison = a.arName.compareTo(b.arName);
            break;
          case AuthorSortBy.articles:
            final statsA = _authorsStats[a.id];
            final statsB = _authorsStats[b.id];
            comparison = (statsA?.totalColumns ?? 0).compareTo(statsB?.totalColumns ?? 0);
            break;
          case AuthorSortBy.popularity:
            final statsA = _authorsStats[a.id];
            final statsB = _authorsStats[b.id];
            comparison = (statsA?.totalViews ?? 0).compareTo(statsB?.totalViews ?? 0);
            break;
          case AuthorSortBy.recent:
            final statsA = _authorsStats[a.id];
            final statsB = _authorsStats[b.id];
            final dateA = statsA?.lastPublished ?? DateTime(2000);
            final dateB = statsB?.lastPublished ?? DateTime(2000);
            comparison = dateA.compareTo(dateB);
            break;
        }

        return _sortAscending ? comparison : -comparison;
      });
    });
  }

  Future<void> _onRefresh() async {
    _authorModule.clearCache();
    await _loadData();
    _refreshController.refreshCompleted();
  }

  void _toggleSearch() {
    setState(() {
      _showSearchBar = !_showSearchBar;
    });
    
    if (_showSearchBar) {
      _searchAnimationController.forward();
    } else {
      _searchAnimationController.reverse();
      _searchTextController.clear();
    }
  }

  void _showSortDialog() {
    showDialog(

      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ترتيب الكتّاب'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ...AuthorSortBy.values.map((sortBy) => RadioListTile<AuthorSortBy>(
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

  String _getSortByLabel(AuthorSortBy sortBy) {
    switch (sortBy) {
      case AuthorSortBy.name:
        return 'الاسم';
      case AuthorSortBy.articles:
        return 'عدد المقالات';
      case AuthorSortBy.popularity:
        return 'الشعبية';
      case AuthorSortBy.recent:
        return 'الأحدث نشراً';
    }
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
      body: _isLoading ? _buildLoadingWidget() : _buildContent(),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return SectionAppBar(
      title: const Text('الكتّاب'),
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
                  _viewMode = _viewMode == AuthorViewMode.grid 
                      ? AuthorViewMode.list 
                      : AuthorViewMode.grid;
                });
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
                  Icon(_viewMode == AuthorViewMode.grid ? Icons.list : Icons.grid_view),
                  const SizedBox(width: 8),
                  Text(_viewMode == AuthorViewMode.grid ? 'عرض قائمة' : 'عرض شبكة'),
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
      bottom: _showSearchBar ? _buildSearchBar() : null,
    );
  }

  PreferredSizeWidget _buildSearchBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(60),
      child: AnimatedBuilder(
        animation: _searchAnimation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, -60 * (1 - _searchAnimation.value)),
            child: Container(
              padding: const EdgeInsets.all(8),
              child: TextField(
                controller: _searchTextController,
                decoration: InputDecoration(
                  hintText: 'البحث عن كاتب...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchTextController.clear();
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
        },
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
          ...List.generate(6, (index) => _buildShimmerAuthorCard()),
        ],
      ),
    );
  }

  Widget _buildShimmerAuthorCard() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
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
                        width: 200,
                        height: 12,
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

            // Quick Stats
            SliverToBoxAdapter(
              child: _buildQuickStats(),
            ),

            // Favorite Authors Section
            if (_showFavorites && _favoriteAuthors.isNotEmpty)
              SliverToBoxAdapter(
                child: _buildFavoriteAuthorsSection(),
              ),

            // Recently Viewed Section
            if (_showRecent && _recentlyViewedAuthors.isNotEmpty)
              SliverToBoxAdapter(
                child: _buildRecentAuthorsSection(),
              ),

            // All Authors Section
            SliverToBoxAdapter(
              child: SectionHeader(
                title: _isSearching ? 'نتائج البحث' : 'جميع الكتّاب',
                subtitle: '${_filteredAuthors.length} كاتب',
                icon: Icons.people,
              ),
            ),

            // Authors List/Grid
            if (_viewMode == AuthorViewMode.grid)
              SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.8,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (index < _filteredAuthors.length) {
                      return _buildAuthorGridCard(_filteredAuthors[index]);
                    }
                    return null;
                  },
                  childCount: _filteredAuthors.length,
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (index < _filteredAuthors.length) {
                      return _buildAuthorListCard(_filteredAuthors[index]);
                    }
                    return null;
                  },
                  childCount: _filteredAuthors.length,
                ),
              ),

            // Empty State
            if (_filteredAuthors.isEmpty && !_isLoading)
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
            onPressed: _loadData,
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
          const Text(
            'الكتّاب',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
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
            'إجمالي الكتّاب',
            _allAuthors.length.toString(),
            Icons.people,
          ),
          _buildStatItem(
            'المفضلة',
            _favoriteAuthors.length.toString(),
            Icons.favorite,
          ),
          _buildStatItem(
            'المشاهدة مؤخراً',
            _recentlyViewedAuthors.length.toString(),
            Icons.history,
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
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFavoriteAuthorsSection() {
    return Column(
      children: [
        SectionHeader(
          title: 'الكتّاب المفضلون',
          icon: Icons.favorite,
          subtitle: '${_favoriteAuthors.length} كاتب',
        ),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _favoriteAuthors.length,
            itemBuilder: (context, index) {
              return _buildHorizontalAuthorCard(_favoriteAuthors[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRecentAuthorsSection() {
    return Column(
      children: [
        SectionHeader(
          title: 'مشاهدة مؤخراً',
          icon: Icons.history,
          subtitle: '${_recentlyViewedAuthors.length} كاتب',
        ),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _recentlyViewedAuthors.length,
            itemBuilder: (context, index) {
              return _buildHorizontalAuthorCard(_recentlyViewedAuthors[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHorizontalAuthorCard(AuthorModel author) {
    final stats = _authorsStats[author.id];
    
    return Container(
      width: 100,
      margin: const EdgeInsets.only(left: 12),
      child: GestureDetector(
        onTap: () => context.push('/author/${author.id}'),
        child: Column(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.tertiaryColor, width: 2),
              ),
              child: ClipOval(
                child: CachedNetworkImage(
                  imageUrl: author.photoUrl,
                  fit: BoxFit.cover,
                  filterQuality: FilterQuality.high,
                  placeholder: (context, url) => Container(
                    color: Colors.grey[300],
                    child: const Icon(Icons.person),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey[300],
                    child: const Icon(Icons.person),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              author.arName,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (stats != null) ...[
              const SizedBox(height: 4),
              Text(
                '${stats.totalColumns} مقال',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAuthorGridCard(AuthorModel author) {
    final stats = _authorsStats[author.id];
    final isFavorite = _authorModule.isAuthorFavorite(author.id);
    
    return Container(
      margin: const EdgeInsets.all(8),
      child: Card(
        elevation: 2,
        child: InkWell(
          onTap: () => context.push('/author/${author.id}'),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                // Author Photo
                Stack(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: CachedNetworkImage(
                          imageUrl: author.photoUrl,
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
                    
                    // Favorite indicator
                    if (isFavorite)
                      Positioned(
                        top: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.favorite,
                            size: 12,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Author Name
                Text(
                  author.arName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                
                const SizedBox(height: 4),
                
                // Articles count
                if (stats != null)
                  Text(
                    '${stats.totalColumns} مقال',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                
                const SizedBox(height: 8),
                
                // Description
                Expanded(
                  child: Text(
                    author.description,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[700],
                      height: 1.3,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

Widget _buildAuthorListCard(AuthorModel author) {
    final stats = _authorsStats[author.id];
    final isFavorite = _authorModule.isAuthorFavorite(author.id);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        elevation: 2,
        child: InkWell(
          onTap: () => context.push('/author/${author.id}'),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Author Photo
                Stack(
                  children: [
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: CachedNetworkImage(
                          imageUrl: author.photoUrl,
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
                    
                    // Favorite indicator
                    if (isFavorite)
                      Positioned(
                        top: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.favorite,
                            size: 12,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
                
                const SizedBox(width: 16),
                
                // Author Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name and Stats Row
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              author.arName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (stats != null) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.tertiaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${stats.totalColumns} مقال',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.tertiaryColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // Description
                      Text(
                        author.description,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      
                      if (stats != null && stats.lastPublished != null) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 14,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'آخر مقال: ${_formatDate(stats.lastPublished!)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                
                // Action Buttons
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: isFavorite ? Colors.red : Colors.grey,
                      ),
                      onPressed: () async {
                        HapticFeedback.lightImpact();
                        if (isFavorite) {
                          await _authorModule.toggleFavoriteAuthor(author.id);
                          _showMessage('تم إزالة ${author.arName} من المفضلة');
                        } else {
                          await _authorModule.toggleFavoriteAuthor(author.id);
                          _showMessage('تم إضافة ${author.arName} إلى المفضلة');
                        }
                        await _loadFavoriteAuthors();
                        setState(() {});
                      },
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Colors.grey[600],
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

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _isSearching ? Icons.search_off : Icons.people_outline,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _isSearching 
                  ? 'لا توجد نتائج للبحث'
                  : 'لا يوجد كتّاب',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _isSearching 
                  ? 'جرب البحث باستخدام كلمات أخرى'
                  : 'سيتم عرض قائمة الكتّاب هنا',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            if (_isSearching) ...[
              const SizedBox(height: 24),
              OutlinedButton.icon(
                icon: const Icon(Icons.clear),
                label: const Text('مسح البحث'),
                onPressed: () {
                  _searchTextController.clear();
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

  String _formatDate(DateTime date) {
    return DateFormat('yyyy/MM/dd HH:mm', 'ar').format(date);
  }
}

// Enums
enum AuthorSortBy {
  name,
  articles,
  popularity,
  recent,
}

enum AuthorViewMode {
  grid,
  list,
}
