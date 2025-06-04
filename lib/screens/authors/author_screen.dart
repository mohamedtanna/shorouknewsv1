import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

import '../../models/additional_models.dart';
import '../../widgets/ad_banner.dart';
import '../../widgets/section_header.dart';
import '../../core/theme.dart';
import 'author_module.dart';

class AuthorScreen extends StatefulWidget {
  final String authorId;

  const AuthorScreen({
    super.key,
    required this.authorId,
  });

  @override
  State<AuthorScreen> createState() => _AuthorScreenState();
}

class _AuthorScreenState extends State<AuthorScreen>
    with TickerProviderStateMixin {
  final AuthorModule _authorModule = AuthorModule();
  final RefreshController _refreshController = RefreshController();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  // Data
  AuthorModel? _author;
  List<ColumnModel> _columns = [];
  AuthorStats? _authorStats;
  AuthorSocialLinks? _socialLinks;

  // State
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMoreData = true;
  String? _errorMessage;
  int _currentPage = 1;
  
  // Search and filters
  AuthorSearchFilters _filters = AuthorSearchFilters();
  bool _showFilters = false;

  // Animations
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // UI State
  bool _isSearchExpanded = false;
  bool _showStats = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initializeModule();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _refreshController.dispose();
    _scrollController.dispose();
    _searchController.dispose();
    _authorModule.dispose();
    super.dispose();
  }

  void _setupAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
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
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
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

      // Load author details
      final author = await _authorModule.getAuthor(widget.authorId);
      
      // Load columns
      final columns = await _authorModule.getAuthorColumns(
        widget.authorId,
        page: 1,
        filters: _filters,
      );

      // Load additional data
      final stats = await _authorModule.getAuthorStats(widget.authorId);
      final socialLinks = await _authorModule.getAuthorSocialLinks(widget.authorId);

      if (mounted) {
        setState(() {
          _author = author;
          _columns = columns;
          _authorStats = stats;
          _socialLinks = socialLinks;
          _currentPage = 1;
          _hasMoreData = columns.length >= 10;
          _isLoading = false;
        });

        _fadeController.forward();
        _slideController.forward();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'فشل في تحميل بيانات الكاتب';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadMoreData() async {
    if (_isLoadingMore || !_hasMoreData) return;

    try {
      setState(() => _isLoadingMore = true);

      final newColumns = await _authorModule.getAuthorColumns(
        widget.authorId,
        page: _currentPage + 1,
        filters: _filters,
      );

      if (mounted) {
        setState(() {
          _columns.addAll(newColumns);
          _currentPage++;
          _hasMoreData = newColumns.length >= 10;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingMore = false);
        _showMessage('فشل في تحميل المزيد من المقالات');
      }
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      _loadMoreData();
    }
  }

  Future<void> _onRefresh() async {
    _authorModule.clearCache();
    await _loadData();
    _refreshController.refreshCompleted();
  }

  void _onLoadMore() async {
    await _loadMoreData();
    _refreshController.loadComplete();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }

  Future<void> _toggleFavorite() async {
    try {
      await _authorModule.toggleFavoriteAuthor(widget.authorId);
      await HapticFeedback.lightImpact();
      
      final isFavorite = _authorModule.isAuthorFavorite(widget.authorId);
      _showMessage(isFavorite ? 'تم إضافة الكاتب للمفضلة' : 'تم إزالة الكاتب من المفضلة');
      
      setState(() {}); // Refresh to update favorite icon
    } catch (e) {
      _showMessage('فشل في تحديث المفضلة');
    }
  }

  Future<void> _shareAuthor() async {
    if (_author == null) return;

    try {
      await _authorModule.shareAuthor(_author!);
    } catch (e) {
      _showMessage('فشل في مشاركة الكاتب');
    }
  }

  void _applyFilters() {
    setState(() {
      _showFilters = false;
      _currentPage = 1;
      _columns.clear();
    });
    _loadData();
  }

  void _resetFilters() {
    setState(() {
      _filters = AuthorSearchFilters();
      _searchController.clear();
      _showFilters = false;
    });
    _applyFilters();
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
    return AppBar(
      title: Text(_author?.arName ?? 'الكاتب'),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => context.go('/columns'),
      ),
      actions: [
        if (_author != null) ...[
          IconButton(
            icon: Icon(
              _authorModule.isAuthorFavorite(widget.authorId)
                  ? Icons.favorite
                  : Icons.favorite_border,
              color: _authorModule.isAuthorFavorite(widget.authorId)
                  ? Colors.red
                  : null,
            ),
            onPressed: _toggleFavorite,
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareAuthor,
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'search':
                  setState(() {
                    _isSearchExpanded = !_isSearchExpanded;
                  });
                  break;
                case 'filters':
                  setState(() {
                    _showFilters = !_showFilters;
                  });
                  break;
                case 'stats':
                  setState(() {
                    _showStats = !_showStats;
                  });
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'search',
                child: Row(
                  children: [
                    Icon(Icons.search),
                    SizedBox(width: 8),
                    Text('البحث'),
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
              const PopupMenuItem(
                value: 'stats',
                child: Row(
                  children: [
                    Icon(Icons.analytics),
                    SizedBox(width: 8),
                    Text('الإحصائيات'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ],
      bottom: _isSearchExpanded ? _buildSearchBar() : null,
    );
  }

  PreferredSizeWidget _buildSearchBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(60),
      child: Container(
        padding: const EdgeInsets.all(8),
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'البحث في مقالات الكاتب...',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _searchController.clear();
                _filters = _filters.copyWith(searchQuery: '');
                _applyFilters();
              },
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
          onSubmitted: (query) {
            _filters = _filters.copyWith(searchQuery: query);
            _applyFilters();
          },
        ),
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('جاري تحميل بيانات الكاتب...'),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_errorMessage != null) {
      return _buildErrorWidget();
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: SmartRefresher(
          controller: _refreshController,
          enablePullDown: true,
          enablePullUp: _hasMoreData,
          onRefresh: _onRefresh,
          onLoading: _onLoadMore,
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              // Ad Banner
              const SliverToBoxAdapter(
                child: AdBanner(adUnit: '/21765378867/ShorouknewsApp_LeaderBoard2'),
              ),

              // Breadcrumb
              SliverToBoxAdapter(
                child: _buildBreadcrumb(),
              ),

              // Filters Panel
              if (_showFilters)
                SliverToBoxAdapter(
                  child: _buildFiltersPanel(),
                ),

              // Author Info
              SliverToBoxAdapter(
                child: _buildAuthorInfo(),
              ),

              // Statistics Panel
              if (_showStats && _authorStats != null)
                SliverToBoxAdapter(
                  child: _buildStatsPanel(),
                ),

              // Columns Section Header
              SliverToBoxAdapter(
                child: SectionHeader(
                  title: 'أحدث مقالات الكاتب',
                  icon: Icons.article,
                  subtitle: '${_columns.length} مقال',
                ),
              ),

              // Columns List
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (index < _columns.length) {
                      return _buildColumnCard(_columns[index]);
                    } else if (_isLoadingMore) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }
                    return null;
                  },
                  childCount: _columns.length + (_isLoadingMore ? 1 : 0),
                ),
              ),

              // Empty State
              if (_columns.isEmpty && !_isLoading)
                const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Column(
                        children: [
                          Icon(
                            Icons.article_outlined,
                            size: 64,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'لا توجد مقالات لهذا الكاتب',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // Bottom spacing
              const SliverToBoxAdapter(
                child: SizedBox(height: 80),
              ),
            ],
          ),
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
          GestureDetector(
            onTap: () => context.go('/columns'),
            child: const Text(
              'رأي ومقالات',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
          if (_author != null) ...[
            const Text(' > ', style: TextStyle(fontWeight: FontWeight.bold)),
            Text(
              _author!.arName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFiltersPanel() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'فلاتر البحث',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
              TextButton(
                onPressed: _resetFilters,
                child: const Text('إعادة تعيين'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Sort options
          const Text('ترتيب بواسطة:', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: AuthorColumnSortBy.values.map((sortBy) {
              return ChoiceChip(
                label: Text(_getSortByLabel(sortBy)),
                selected: _filters.sortBy == sortBy,
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _filters = _filters.copyWith(sortBy: sortBy);
                    });
                  }
                },
              );
            }).toList(),
          ),
          
          const SizedBox(height: 12),
          
          // Sort direction
          SwitchListTile(
            title: const Text('ترتيب تصاعدي'),
            value: _filters.ascending,
            onChanged: (value) {
              setState(() {
                _filters = _filters.copyWith(ascending: value);
              });
            },
          ),
          
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _applyFilters,
                  child: const Text('تطبيق الفلاتر'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getSortByLabel(AuthorColumnSortBy sortBy) {
    switch (sortBy) {
      case AuthorColumnSortBy.date:
        return 'التاريخ';
      case AuthorColumnSortBy.title:
        return 'العنوان';
      case AuthorColumnSortBy.views:
        return 'المشاهدات';
      case AuthorColumnSortBy.rating:
        return 'التقييم';
    }
  }

  Widget _buildAuthorInfo() {
    if (_author == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Author Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.tertiaryColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                // Author Avatar
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                  child: ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: _author!.photoUrl,
                      fit: BoxFit.cover,
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
                
                // Author Name and Quick Stats
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _author!.arName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      if (_authorStats != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          '${_authorStats!.totalColumns} مقال',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Author Description
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _author!.description,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.6,
                    color: Colors.black87,
                  ),
                ),
                
                // Social Links
                if (_socialLinks?.hasAnyLink == true) ...[
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: _socialLinks!.availableLinks.map((link) {
                      return InkWell(
                        onTap: () => _authorModule.openExternalLink(link['url']),
                        child: Chip(
                          avatar: Icon(
                            _getSocialIcon(link['type']),
                            size: 16,
                          ),
                          label: Text(
                            link['label'],
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getSocialIcon(String type) {
    switch (type) {
      case 'facebook':
        return Icons.facebook;
      case 'twitter':
        return Icons.alternate_email;
      case 'instagram':
        return Icons.camera_alt;
      case 'linkedin':
        return Icons.work;
      case 'website':
        return Icons.web;
      case 'email':
        return Icons.email;
      default:
        return Icons.link;
    }
  }

  Widget _buildStatsPanel() {
    if (_authorStats == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'إحصائيات الكاتب',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              _buildStatItem(
                'المقالات',
                _authorStats!.totalColumns.toString(),
                Icons.article,
              ),
              _buildStatItem(
                'المشاهدات',
                _formatNumber(_authorStats!.totalViews),
                Icons.visibility,
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          Row(
            children: [
              _buildStatItem(
                'التقييم',
                '${_authorStats!.averageRating.toStringAsFixed(1)} ⭐',
                Icons.star,
              ),
              _buildStatItem(
                'آخر نشر',
                _formatDate(_authorStats!.lastPublished),
                Icons.schedule,
              ),
            ],
          ),
          
          // Top Topics
          if (_authorStats!.topTopics.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              'المواضيع الأكثر تناولاً:',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _authorStats!.topTopics.take(5).map((topic) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    topic,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
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
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColumnCard(ColumnModel column) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Card(
        elevation: 2,
        child: InkWell(
          onTap: () => context.go('/column/${column.cDate}/${column.id}'),
          onLongPress: () => _showColumnPreview(column),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        column.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        switch (value) {
                          case 'preview':
                            _showColumnPreview(column);
                            break;
                          case 'share':
                            _shareColumn(column);
                            break;
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'preview',
                          child: Row(
                            children: [
                              Icon(Icons.visibility, size: 20),
                              SizedBox(width: 8),
                              Text('معاينة'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'share',
                          child: Row(
                            children: [
                              Icon(Icons.share, size: 20),
                              SizedBox(width: 8),
                              Text('مشاركة'),
                            ],
                          ),
                        ),
                      ],
                      child: Icon(
                        Icons.more_vert,
                        color: Colors.grey[400],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 8),
                
                Text(
                  column.summary,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                
                const SizedBox(height: 12),
                
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.tertiaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 12,
                            color: AppTheme.tertiaryColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            column.creationDateFormatted,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.tertiaryColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'اضغط للقراءة',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 12,
                      color: Colors.grey[400],
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

  Future<void> _shareColumn(ColumnModel column) async {
    try {
      final shareText = '''
📝 ${column.title}

بقلم: ${_author?.arName ?? 'غير محدد'}

${column.summary}

اقرأ المقال كاملاً على تطبيق الشروق

#الشروق #مقال #رأي
      ''';

      await Share.share(
        shareText,
        subject: column.title,
      );

      // Log analytics
      await _authorModule._firebaseService.logEvent('column_shared_from_author', {
        'column_id': column.id,
        'author_id': widget.authorId,
        'column_title': column.title,
      });
    } catch (e) {
      _showMessage('فشل في مشاركة المقال');
    }
  }

  Widget? _buildFloatingActionButton() {
    if (_columns.isEmpty) return null;

    return FloatingActionButton.extended(
      onPressed: () {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      },
      backgroundColor: AppTheme.tertiaryColor,
      icon: const Icon(Icons.keyboard_arrow_up, color: Colors.white),
      label: const Text(
        'أعلى الصفحة',
        style: TextStyle(color: Colors.white),
      ),
    );
  }

  // Additional helper methods for enhanced functionality
  void _showColumnPreview(ColumnModel column) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.symmetric(vertical: 10),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        column.title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundImage: _author?.photoUrl != null
                                ? CachedNetworkImageProvider(_author!.photoUrl)
                                : null,
                            child: _author?.photoUrl == null
                                ? const Icon(Icons.person)
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _author?.arName ?? 'غير محدد',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  column.creationDateFormatted,
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 20),
                      
                      Text(
                        column.summary,
                        style: const TextStyle(
                          fontSize: 16,
                          height: 1.6,
                        ),
                      ),
                      
                      const SizedBox(height: 30),
                      
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            context.go('/column/${column.cDate}/${column.id}');
                          },
                          child: const Text('قراءة المقال كاملاً'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Error handling with retry mechanism
  void _handleError(String operation, dynamic error) {
    debugPrint('Error in $operation: $error');
    
    String userMessage;
    switch (operation) {
      case 'load_author':
        userMessage = 'فشل في تحميل بيانات الكاتب';
        break;
      case 'load_columns':
        userMessage = 'فشل في تحميل مقالات الكاتب';
        break;
      case 'favorite':
        userMessage = 'فشل في تحديث المفضلة';
        break;
      case 'share':
        userMessage = 'فشل في مشاركة الكاتب';
        break;
      default:
        userMessage = 'حدث خطأ غير متوقع';
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(userMessage),
        backgroundColor: Colors.red,
        action: operation.contains('load') ? SnackBarAction(
          label: 'إعادة المحاولة',
          textColor: Colors.white,
          onPressed: _loadData,
        ) : null,
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'غير محدد';
    
    final now = DateTime.now();
    final difference = now.difference(date).inDays;
    
    if (difference == 0) {
      return 'اليوم';
    } else if (difference == 1) {
      return 'أمس';
    } else if (difference < 7) {
      return 'منذ $difference أيام';
    } else if (difference < 30) {
      return 'منذ ${(difference / 7).round()} أسبوع';
    } else if (difference < 365) {
      return 'منذ ${(difference / 30).round()} شهر';
    } else {
      return 'منذ ${(difference / 365).round()} سنة';
    }
  }
}