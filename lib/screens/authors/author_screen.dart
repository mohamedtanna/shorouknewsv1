import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For HapticFeedback
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart'; // For SmartRefresher
import 'package:shimmer/shimmer.dart'; // For loading shimmer
// Added import for Share
import 'package:shorouk_news/models/new_model.dart';
import 'package:shorouk_news/widgets/news_card.dart';

import '../../models/additional_models.dart'; // Contains AuthorModel and other models
import '../../models/column_model.dart';
// import '../../widgets/ad_banner.dart';
import '../../widgets/section_header.dart';
import '../../core/theme.dart';
import 'author_module.dart'; // Contains AuthorModule and its models like AuthorStats etc.

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
  final int _pageSize = 10; // Page size for fetching columns

  // Search and filters
  AuthorSearchFilters _filters = AuthorSearchFilters();
  bool _showFilters = false;

  // Animations
  late AnimationController _fadeController;
  late AnimationController _slideController; // For search bar or filter panel
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // UI State
  bool _isSearchExpanded = false;
  bool _showStats = false; // To toggle stats panel visibility

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initializeModuleAndLoadData(); // Combined for clarity
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
      duration: const Duration(milliseconds: 300), // Faster for search/filter panel
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut));
    _slideAnimation = Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero)
        .animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));
  }

  Future<void> _initializeModuleAndLoadData() async {
    await _authorModule.initialize(); // Initialize module first
    await _loadData(isInitialLoad: true); // Then load data
  }

  Future<void> _loadData({bool refresh = false, bool isInitialLoad = false}) async {
    if (!mounted) return;
    setState(() {
      _isLoading = isInitialLoad || refresh; // Show main loader only on initial or refresh
      _errorMessage = null;
      if (refresh) {
         _currentPage = 1;
         _columns.clear();
         _hasMoreData = true;
      }
    });

    try {
      // Fetch all data concurrently
      final results = await Future.wait([
        _authorModule.getAuthor(widget.authorId, useCache: !refresh),
        _authorModule.getAuthorColumns(
          widget.authorId,
          page: 1, // Always fetch page 1 on initial load/refresh
          pageSize: _pageSize,
          filters: _filters,
          useCache: !refresh,
        ),
        _authorModule.getAuthorStats(widget.authorId, useCache: !refresh),
        _authorModule.getAuthorSocialLinks(widget.authorId, useCache: !refresh),
      ]);

      if (mounted) {
        setState(() {
          _author = results[0] as AuthorModel?;
          _columns = results[1] as List<ColumnModel>;
          _authorStats = results[2] as AuthorStats?;
          _socialLinks = results[3] as AuthorSocialLinks?;
          _currentPage = 1; // Reset current page after initial load/refresh
          _hasMoreData = _columns.length >= _pageSize;
          _isLoading = false; // Stop main loader
        });
        _fadeController.forward(from: 0.0); // Restart fade animation
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'فشل في تحميل بيانات الكاتب: ${e.toString()}';
          _isLoading = false;
        });
        debugPrint("Error in _loadData for author ${widget.authorId}: $e");
      }
    }
  }

  Future<void> _loadMoreData() async {
    if (_isLoadingMore || !_hasMoreData || !mounted) return;

    setState(() => _isLoadingMore = true);
    
    try {
      final newColumns = await _authorModule.getAuthorColumns(
        widget.authorId,
        page: _currentPage + 1, // Fetch next page
        pageSize: _pageSize,
        filters: _filters,
      );

      if (mounted) {
        setState(() {
          _columns.addAll(newColumns);
          _currentPage++;
          _hasMoreData = newColumns.length >= _pageSize;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingMore = false);
        _showMessage('فشل في تحميل المزيد من المقالات', isError: true);
        debugPrint("Error in _loadMoreData for author ${widget.authorId}: $e");
      }
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent * 0.8 && // Trigger a bit earlier
        !_isLoading && !_isLoadingMore && _hasMoreData) {
      _loadMoreData();
    }
  }

  Future<void> _onRefresh() async {
    _authorModule.clearCache(); // Clear module specific cache on pull-to-refresh
    await _loadData(refresh: true);
    if (mounted) _refreshController.refreshCompleted();
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red[700] : AppTheme.primaryColor,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _toggleFavorite() async {
    if (_author == null) return;
    try {
      await HapticFeedback.lightImpact();
      await _authorModule.toggleFavoriteAuthor(widget.authorId);
      if (mounted) {
         final isFavorite = _authorModule.isAuthorFavorite(widget.authorId);
        _showMessage(isFavorite ? 'تم إضافة الكاتب للمفضلة' : 'تم إزالة الكاتب من المفضلة');
        setState(() {}); // Rebuild to update favorite icon
      }
    } catch (e) {
      _showMessage('فشل في تحديث المفضلة', isError: true);
    }
  }

  Future<void> _shareAuthor() async {
    if (_author == null) return;
    try {
      await _authorModule.shareAuthor(_author!);
    } catch (e) {
      _showMessage('فشل في مشاركة الكاتب', isError: true);
    }
  }

  void _applyFiltersAndSearch() { 
    if (mounted) {
      setState(() {
        _showFilters = false; 
        _isSearchExpanded = false; 
        _currentPage = 1;
        _columns.clear();
      });
    }
    _loadData(refresh: true); 
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _isLoading && _columns.isEmpty && _author == null 
          ? _buildLoadingWidget() 
          : _buildContent(),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(_author?.arName ?? 'الكاتب'),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/authors');
          } 
        },
      ),
      actions: [
        if (_author != null) ...[
          IconButton(
            icon: Icon(
              _authorModule.isAuthorFavorite(widget.authorId)
                  ? Icons.favorite_rounded 
                  : Icons.favorite_border_outlined,
              color: _authorModule.isAuthorFavorite(widget.authorId)
                  ? Colors.redAccent
                  : null,
            ),
            tooltip: 'إضافة للمفضلة',
            onPressed: _toggleFavorite,
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: 'مشاركة الكاتب',
            onPressed: _shareAuthor,
          ),
          PopupMenuButton<String>(
            tooltip: 'خيارات إضافية',
            onSelected: (value) {
              if (mounted) {
                setState(() {
                  switch (value) {
                    case 'search':
                      _isSearchExpanded = !_isSearchExpanded;
                      if (_isSearchExpanded) {
                        _slideController.forward();
                      } else {
                        _slideController.reverse();
                      }
                      _showFilters = false; 
                      break;
                    case 'filters':
                      _showFilters = !_showFilters;
                       if (_showFilters) {
                         _slideController.forward();
                       } else {
                         _slideController.reverse();
                       }
                      _isSearchExpanded = false; 
                      break;
                    case 'stats':
                      _showStats = !_showStats;
                      break;
                  }
                });
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'search',
                child: Row(children: [ Icon(Icons.search_outlined), SizedBox(width: 8), Text('البحث في المقالات')]),
              ),
              const PopupMenuItem(
                value: 'filters',
                child: Row(children: [ Icon(Icons.filter_alt_outlined), SizedBox(width: 8), Text('فرز وتصفية')]),
              ),
              PopupMenuItem(
                value: 'stats',
                child: Row(children: [ Icon(_showStats ? Icons.analytics_rounded : Icons.analytics_outlined), const SizedBox(width: 8), Text(_showStats ? 'إخفاء الإحصائيات' : 'عرض الإحصائيات')]),
              ),
            ],
          ),
        ],
      ],
      bottom: (_isSearchExpanded || _showFilters) ? _buildSearchOrFilterBar() : null,
    );
  }
  
  PreferredSizeWidget _buildSearchOrFilterBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(60), 
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
          color: Theme.of(context).appBarTheme.backgroundColor?.withAlpha(25), // Corrected: withOpacity to withAlpha
          child: _isSearchExpanded ? _buildColumnSearchBar() : (_showFilters ? _buildFilterChipsBar() : const SizedBox.shrink()),
        ),
      ),
    );
  }


  Widget _buildColumnSearchBar() { 
    return TextField(
      controller: _searchController,
      autofocus: true,
      decoration: InputDecoration(
        hintText: 'البحث في مقالات ${_author?.arName ?? "الكاتب"}...',
        prefixIcon: const Icon(Icons.search, size: 20),
        suffixIcon: _searchController.text.isNotEmpty ? IconButton(
          icon: const Icon(Icons.clear, size: 20),
          onPressed: () {
            _searchController.clear();
            _filters = _filters.copyWith(searchQuery: ''); 
            _applyFiltersAndSearch();
          },
        ) : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
        filled: true,
        fillColor: Theme.of(context).scaffoldBackgroundColor,
        contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      ),
      onChanged: (query) {
      },
      onSubmitted: (query) {
        _filters = _filters.copyWith(searchQuery: query);
        _applyFiltersAndSearch();
      },
    );
  }
  
  Widget _buildFilterChipsBar() { 
     return ListView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(vertical: 8.0), // Added padding
      children: AuthorColumnSortBy.values.map((sortBy) {
        bool isSelected = _filters.sortBy == sortBy;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: ChoiceChip(
            label: Text(_getSortByLabel(sortBy)),
            selected: isSelected,
            onSelected: (selected) {
              if (selected) {
                if (mounted) {
                  setState(() {
                    if (_filters.sortBy == sortBy) { 
                      _filters = _filters.copyWith(sortBy: sortBy, ascending: !_filters.ascending);
                    } else {
                      _filters = _filters.copyWith(sortBy: sortBy, ascending: false); 
                    }
                  });
                }
                _applyFiltersAndSearch();
              }
            },
            avatar: isSelected ? Icon(_filters.ascending ? Icons.arrow_upward : Icons.arrow_downward, size: 16) : null,
            selectedColor: AppTheme.tertiaryColor.withAlpha(50), // Corrected: withOpacity to withAlpha
            backgroundColor: Theme.of(context).chipTheme.backgroundColor,
            labelStyle: TextStyle(fontSize: 13, color: isSelected ? AppTheme.tertiaryColor : null),
          ),
        );
      }).toList(),
    );
  }


  Widget _buildLoadingWidget() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const CircleAvatar(radius: 40, backgroundColor: Colors.white),
              const SizedBox(width: 16),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(height: 20, width: 150, color: Colors.white, margin: const EdgeInsets.only(bottom: 8), decoration: BoxDecoration(borderRadius: BorderRadius.circular(4))),
                Container(height: 14, width: 100, color: Colors.white, decoration: BoxDecoration(borderRadius: BorderRadius.circular(4))),
              ])),
            ]),
            const SizedBox(height: 16),
            Container(height: 60, width: double.infinity, color: Colors.white, decoration: BoxDecoration(borderRadius: BorderRadius.circular(8))),
            const SizedBox(height: 24),
            Container(height: 24, width: 200, color: Colors.white, margin: const EdgeInsets.only(bottom: 16), decoration: BoxDecoration(borderRadius: BorderRadius.circular(4))),
            ...List.generate(3, (index) => Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Container(height: 120, width: double.infinity, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8))),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_errorMessage != null && _author == null) { 
      return _buildErrorWidget();
    }
    if (_author == null) return const SizedBox.shrink(); 

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        // Corrected: position was _slideAnimation, but this is for the whole content.
        // The search/filter bar uses _slideAnimation. For general content, it's usually not slid.
        // If you intend to slide the whole content, keep it. Otherwise, remove.
        // For now, assuming the slide is for the search/filter bar, not the main content.
        position: Tween<Offset>(begin: Offset.zero, end: Offset.zero).animate(_slideController), // No slide for main content
        child: SmartRefresher(
          controller: _refreshController,
          enablePullDown: true,
          enablePullUp: _hasMoreData && !_isLoadingMore, 
          header: const WaterDropHeader(waterDropColor: AppTheme.primaryColor), 
          footer: CustomFooter(
            builder: (BuildContext context, LoadStatus? mode) {
              Widget body;
              if (mode == LoadStatus.idle) {
                body = const Text("اسحب للأعلى لتحميل المزيد");
              } else if (mode == LoadStatus.loading) {
                body = const CircularProgressIndicator(strokeWidth: 2.0, color: AppTheme.primaryColor);
              } else if (mode == LoadStatus.failed) {
                body = const Text("فشل التحميل! انقر لإعادة المحاولة");
              } else if (mode == LoadStatus.canLoading) {
                body = const Text("اترك للتحميل");
              } else { 
                body = const Text("لا يوجد المزيد من المقالات");
              }
              return SizedBox(height: 55.0, child: Center(child: body));
            },
          ),
          onRefresh: _onRefresh,
          onLoading: _loadMoreData, 
          child: CustomScrollView(
            controller: _scrollController,
              slivers: [
                // const SliverToBoxAdapter(
                //   child: AdBanner(adUnit: '/21765378867/ShorouknewsApp_LeaderBoard2'),
                // ),
              SliverToBoxAdapter(child: _buildBreadcrumb()),
              SliverToBoxAdapter(child: _buildAuthorInfo()),
              if (_showStats && _authorStats != null)
                SliverToBoxAdapter(child: _buildStatsPanel()),
              SliverToBoxAdapter(
                child: SectionHeader(
                  title: 'مقالات الكاتب',
                  icon: Icons.article_outlined,
                  subtitle: '${_authorStats?.totalColumns ?? _columns.length} مقال',
                ),
              ),
              if (_columns.isEmpty && !_isLoadingMore) 
                 SliverFillRemaining( 
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.article_outlined, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                             _filters.searchQuery != null && _filters.searchQuery!.isNotEmpty ?
                             'لا توجد مقالات تطابق بحثك' :
                            'لا توجد مقالات لهذا الكاتب حالياً',
                            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      return _buildColumnCard(_columns[index]);
                    },
                    childCount: _columns.length,
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 80)), 
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded, size: 70, color: Colors.red[600]),
            const SizedBox(height: 20),
            Text(
              _errorMessage ?? 'حدث خطأ غير متوقع.',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.black87),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة المحاولة'),
              onPressed: () => _loadData(refresh: true),
               style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor, foregroundColor: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBreadcrumb() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).canvasColor,
        border: const Border(bottom: BorderSide(color: AppTheme.tertiaryColor, width: 4)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.go('/home'),
            child: const Text('الرئيسية', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
          ),
          const Text(' > ', style: TextStyle(fontWeight: FontWeight.bold)),
          GestureDetector(
            onTap: () => context.go('/authors'), 
            child: const Text('الكتّاب', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
          ),
          if (_author != null) ...[
            const Text(' > ', style: TextStyle(fontWeight: FontWeight.bold)),
            Expanded(child: Text(_author!.arName, style: const TextStyle(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
          ],
        ],
      ),
    );
  }
  
  String _getSortByLabel(AuthorColumnSortBy sortBy) {
    switch (sortBy) {
      case AuthorColumnSortBy.date: return 'الأحدث';
      case AuthorColumnSortBy.title: return 'العنوان';
      case AuthorColumnSortBy.views: return 'الأكثر قراءة';
      case AuthorColumnSortBy.rating: return 'التقييم الأعلى';
    }
  }

  Widget _buildAuthorInfo() {
    if (_author == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundImage: _author!.photoUrl.isNotEmpty 
                        ? CachedNetworkImageProvider(_author!.photoUrl) 
                        : null,
                    onBackgroundImageError: (_,__){}, 
                    child: _author!.photoUrl.isEmpty 
                        ? const Icon(Icons.person_outline, size: 40) 
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _author!.arName,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: AppTheme.primaryColor),
                        ),
                        if (_authorStats != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              '${_authorStats!.totalColumns} مقال  •  ${_formatNumber(_authorStats!.totalViews)} مشاهدة',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[700]),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              if (_author!.description.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  _author!.description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5, color: Colors.grey[800]),
                  maxLines: 3, 
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (_socialLinks?.hasAnyLink == true) ...[
                const Divider(height: 24, thickness: 0.8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  alignment: WrapAlignment.center,
                  children: _socialLinks!.availableLinks.map((link) {
                    return ActionChip(
                      avatar: Icon(_getSocialIcon(link['type'] as String), size: 18, color: AppTheme.tertiaryColor),
                      label: Text(link['label'] as String, style: const TextStyle(fontSize: 12)),
                      onPressed: () => _authorModule.openExternalLink(link['url'] as String),
                      backgroundColor: AppTheme.tertiaryColor.withAlpha(30), 
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  IconData _getSocialIcon(String type) {
    switch (type.toLowerCase()) {
      case 'facebook': return Icons.facebook_rounded;
      case 'twitter': return Icons.flutter_dash_rounded; 
      case 'instagram': return Icons.camera_alt_outlined;
      case 'linkedin': return Icons.work_outline_rounded;
      case 'website': return Icons.language_rounded;
      case 'email': return Icons.email_outlined;
      default: return Icons.link_rounded;
    }
  }

  Widget _buildStatsPanel() {
    if (_authorStats == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Card(
        elevation: 2,
        color: AppTheme.primaryColor.withAlpha(20), 
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'إحصائيات الكاتب',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppTheme.primaryColor, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem('المقالات', _authorStats!.totalColumns.toString(), Icons.article_outlined),
                  _buildStatItem('المشاهدات', _formatNumber(_authorStats!.totalViews), Icons.visibility_outlined),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem('متوسط التقييم', '${_authorStats!.averageRating.toStringAsFixed(1)} ⭐', Icons.star_border_outlined),
                  _buildStatItem('آخر نشر', _formatDate(_authorStats!.lastPublished), Icons.schedule_outlined),
                ],
              ),
              if (_authorStats!.topTopics.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text('أبرز المواضيع:', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6, runSpacing: 6,
                  children: _authorStats!.topTopics.map((topic) => Chip(
                      label: Text(topic, style: const TextStyle(fontSize: 11)), 
                      backgroundColor: AppTheme.tertiaryColor.withAlpha(50), 
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  )).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppTheme.primaryColor, size: 26),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.secondaryColor)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[700]), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildColumnCard(ColumnModel column) {
    final tempArticleForCard = NewsArticle(
      id: column.id,
      cDate: column.cDate,
      title: column.title,
      summary: column.summary,
      body: '', 
      photoUrl: column.columnistPhotoUrl, 
      thumbnailPhotoUrl: column.columnistPhotoUrl,
      sectionId: '', 
      sectionArName: column.columnistArName, 
      publishDate: column.creationDate,
      publishDateFormatted: column.creationDateFormatted,
      publishTimeFormatted: '', 
      lastModificationDate: column.creationDate,
      lastModificationDateFormatted: column.creationDateFormattedDateTime,
      editorAndSource: column.columnistArName,
      canonicalUrl: column.canonicalUrl,
      relatedPhotos: [],
      relatedNews: [],
    );

    return NewsCard(
      article: tempArticleForCard,
      isHorizontal: true, 
      onTap: () => context.go('/column/${column.cDate}/${column.id}'),
      showDate: true, 
    );
  }


  Widget? _buildFloatingActionButton() {
    if (_columns.isEmpty && !_isLoading) return null; 
    bool showFab = _scrollController.hasClients && _scrollController.offset > 300;

    return AnimatedOpacity(
      opacity: showFab ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 300),
      child: FloatingActionButton.small( 
        onPressed: () {
          _scrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        },
        backgroundColor: AppTheme.tertiaryColor,
        tooltip: 'العودة للأعلى',
        child: const Icon(Icons.arrow_upward_rounded, color: Colors.white),
      ),
    );
  }
  
  void _showColumnPreview(ColumnModel column) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6, 
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => ClipRRect(
           borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: Container(
            color: Theme.of(context).scaffoldBackgroundColor,
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          column.title,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: AppTheme.primaryColor),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundImage: _author?.photoUrl != null && _author!.photoUrl.isNotEmpty
                                  ? CachedNetworkImageProvider(_author!.photoUrl)
                                  : null,
                              onBackgroundImageError: (_,__){},
                              child: (_author?.photoUrl == null || _author!.photoUrl.isEmpty)
                                  ? const Icon(Icons.person_outline, size: 20)
                                  : null,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _author?.arName ?? column.columnistArName, 
                                    style: Theme.of(context).textTheme.titleMedium,
                                  ),
                                  Text(
                                    column.creationDateFormattedDateTime,
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        Text(
                          column.summary.isNotEmpty ? column.summary : "لا يتوفر ملخص لهذا المقال.",
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.6),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.read_more_outlined),
                            label: const Text('قراءة المقال كاملاً'),
                            onPressed: () {
                              Navigator.pop(context); 
                              context.go('/column/${column.cDate}/${column.id}');
                            },
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12)
                            ),
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
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) return '${(number / 1000000).toStringAsFixed(1)} مليون';
    if (number >= 1000) return '${(number / 1000).toStringAsFixed(number % 1000 == 0 ? 0 : 1)} ألف';
    return number.toString();
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'غير محدد';
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inSeconds < 60) return 'الآن';
    if (difference.inMinutes < 60) return 'منذ ${difference.inMinutes} د';
    if (difference.inHours < 24) return 'منذ ${difference.inHours} س';
    if (difference.inDays == 1) return 'أمس';
    if (difference.inDays < 7) return 'منذ ${difference.inDays} أيام';
    if (difference.inDays < 30) return 'منذ ${(difference.inDays / 7).floor()} أسابيع'; // Corrected typo
    if (difference.inDays < 365) return 'منذ ${(difference.inDays / 30).floor()} شهر';
    return 'منذ ${(difference.inDays / 365).floor()} سنة';
  }
}
