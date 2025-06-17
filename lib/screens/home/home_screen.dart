import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';

// Provider for fetching news and column data
import '../../providers/news_provider.dart';

// Data models for news articles and columns
import 'package:shorouk_news/models/new_model.dart';

// Reusable widgets for displaying content and ads
//import 'package:shorouk_news/widgets/news_card.dart';
//import '../../widgets/section_header.dart';

// Theme and styling for the application
import '../../core/theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData({bool refresh = false}) async {
    final newsProvider = context.read<NewsProvider>();
    if (refresh) {
      await newsProvider.refreshAllData();
    } else {
      if (newsProvider.mainStories.isEmpty) {
        await newsProvider.loadMainStories();
      }
      if (newsProvider.topStories.isEmpty) {
        await newsProvider.loadTopStories();
      }
      if (newsProvider.mostReadStories.isEmpty) {
        await newsProvider.loadMostReadStories();
      }
      if (newsProvider.selectedColumns.isEmpty) {
        await newsProvider.loadSelectedColumns();
      }
    }
  }

  Future<void> _refreshData() async {
    await _loadData(refresh: true);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: RefreshIndicator(
        onRefresh: _refreshData,
        color: AppTheme.primaryColor,
        child: Consumer<NewsProvider>(
          builder: (context, newsProvider, child) {
            return CustomScrollView(
              controller: _scrollController,
              slivers: [
                // Main Story Section - Large featured story
                SliverToBoxAdapter(
                  child: _buildMainFeaturedStory(newsProvider, theme),
                ),

                // Grid of Main Stories - 2x2 grid layout like in screenshots
                SliverToBoxAdapter(
                  child: _buildMainStoriesGrid(newsProvider),
                ),

                // Top Stories Section with blue header
                SliverToBoxAdapter(
                  child: _buildSectionWithHeader(
                    title: 'أهم الأخبار',
                    icon: Icons.trending_up,
                    onMorePressed: () => context.push('/news'),
                  ),
                ),
                SliverToBoxAdapter(
                  child: _buildTopStoriesList(newsProvider),
                ),

                // Selected Columns Section with blue header
                SliverToBoxAdapter(
                  child: _buildSectionWithHeader(
                    title: 'مقالات مختارة',
                    icon: Icons.article_outlined,
                    onMorePressed: () => context.push('/columns'),
                  ),
                ),
                SliverToBoxAdapter(
                  child: _buildSelectedColumnsList(newsProvider),
                ),

                // Most Read Stories Section with blue header
                SliverToBoxAdapter(
                  child: _buildSectionWithHeader(
                    title: 'الأكثر قراءة',
                    icon: Icons.visibility_outlined,
                  ),
                ),
                SliverToBoxAdapter(
                  child: _buildMostReadList(newsProvider),
                ),

                // Bottom spacing
                SliverToBoxAdapter(
                  child: AppTheme.verticalSpaceLarge,
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSectionWithHeader({
    required String title,
    required IconData icon,
    VoidCallback? onMorePressed,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(
              icon,
              color: AppTheme.tertiaryColor,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Cairo',
                ),
              ),
            ),
            if (onMorePressed != null) ...[
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.tertiaryColor,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                ),
                child: InkWell(
                  onTap: onMorePressed,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'المزيد',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Cairo',
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(
                          Icons.add,
                          color: Colors.white,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMainFeaturedStory(NewsProvider newsProvider, ThemeData theme) {
    if (newsProvider.isLoadingMainStories && newsProvider.mainStories.isEmpty) {
      return _buildShimmerFeaturedCard();
    }
    if (newsProvider.mainStories.isEmpty) {
      return const SizedBox.shrink();
    }

    final mainStory = newsProvider.mainStories.first;

    return Container(
      height: 300,
      margin: const EdgeInsets.all(8),
      child: GestureDetector(
        onTap: () => context.push('/news/${mainStory.cDate}/${mainStory.id}'),
        child: Card(
          margin: EdgeInsets.zero,
          clipBehavior: Clip.antiAlias,
          elevation: AppTheme.elevationMedium,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: CachedNetworkImage(
                  imageUrl: mainStory.photoUrl,
                  fit: BoxFit.cover,
                  filterQuality: FilterQuality.high,
                  placeholder: (context, url) => Shimmer.fromColors(
                    baseColor: AppTheme.dividerColor,
                    highlightColor: AppTheme.surfaceVariant,
                    child: Container(color: AppTheme.backgroundColor),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: AppTheme.surfaceVariant,
                    child: const Icon(
                      Icons.broken_image,
                      color: AppTheme.textDisabledColor,
                      size: 50,
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.3),
                        Colors.black.withOpacity(0.8),
                      ],
                      stops: const [0.0, 0.6, 1.0],
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: Text(
                  mainStory.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Cairo',
                    shadows: [
                      Shadow(
                        blurRadius: 3.0,
                        color: Colors.black54,
                        offset: Offset(1, 1),
                      )
                    ],
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainStoriesGrid(NewsProvider newsProvider) {
    if (newsProvider.isLoadingMainStories &&
        newsProvider.mainStories.length <= 1) {
      return _buildShimmerGrid(itemCount: 4);
    }
    if (newsProvider.mainStories.length <= 1) {
      return const SizedBox.shrink();
    }

    final otherStories = newsProvider.mainStories.skip(1).take(4).toList();
    if (otherStories.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 1.2,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: otherStories.length,
        itemBuilder: (context, index) {
          final story = otherStories[index];
          return _buildGridNewsCard(story);
        },
      ),
    );
  }

  Widget _buildGridNewsCard(NewsArticle story) {
    return GestureDetector(
      onTap: () => context.push('/news/${story.cDate}/${story.id}'),
      child: Card(
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: CachedNetworkImage(
                imageUrl: story.thumbnailPhotoUrl.isNotEmpty
                    ? story.thumbnailPhotoUrl
                    : story.photoUrl,
                fit: BoxFit.cover,
                filterQuality: FilterQuality.high,
                placeholder: (context, url) => Container(
                  color: Colors.grey[300],
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey[300],
                  child: const Icon(Icons.error),
                ),
              ),
            ),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      // ignore: deprecated_member_use
                      Colors.black.withOpacity(0.7),
                    ],
                    stops: const [0.4, 1.0],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 8,
              left: 8,
              right: 8,
              child: Text(
                story.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Cairo',
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopStoriesList(NewsProvider newsProvider) {
    if (newsProvider.isLoadingTopStories && newsProvider.topStories.isEmpty) {
      return _buildShimmerVerticalList(itemCount: 3);
    }
    if (newsProvider.topStories.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Center(
          child: Text(
            'لا توجد أخبار هامة حالياً.',
            style: TextStyle(
              color: AppTheme.textSecondaryColor,
              fontSize: 16,
              fontFamily: 'Cairo',
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      itemCount: newsProvider.topStories.length.clamp(0, 5),
      itemBuilder: (context, index) {
        final story = newsProvider.topStories[index];
        return _buildHorizontalNewsCard(story, showDate: true);
      },
    );
  }

  Widget _buildSelectedColumnsList(NewsProvider newsProvider) {
    if (newsProvider.isLoadingColumns && newsProvider.selectedColumns.isEmpty) {
      return _buildShimmerVerticalList(itemCount: 10);
    }
    if (newsProvider.selectedColumns.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Center(
          child: Text(
            'لا توجد مقالات مختارة حالياً.',
            style: TextStyle(
              color: AppTheme.textSecondaryColor,
              fontSize: 16,
              fontFamily: 'Cairo',
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      itemCount: newsProvider.selectedColumns.length.clamp(0, 3),
      itemBuilder: (context, index) {
        final column = newsProvider.selectedColumns[index];
        final article = NewsArticle(
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
        return _buildHorizontalNewsCard(article, showDate: true, isColumn: true);
      },
    );
  }

  Widget _buildMostReadList(NewsProvider newsProvider) {
    if (newsProvider.isLoadingMostRead &&
        newsProvider.mostReadStories.isEmpty) {
      return _buildShimmerVerticalList(itemCount: 3);
    }
    if (newsProvider.mostReadStories.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Center(
          child: Text(
            'لا توجد أخبار رائجة حالياً.',
            style: TextStyle(
              color: AppTheme.textSecondaryColor,
              fontSize: 16,
              fontFamily: 'Cairo',
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      itemCount: newsProvider.mostReadStories.length.clamp(0, 5),
      itemBuilder: (context, index) {
        final story = newsProvider.mostReadStories[index];
        return _buildHorizontalNewsCard(story, showDate: false);
      },
    );
  }

  Widget _buildHorizontalNewsCard(NewsArticle article,
      {bool showDate = true, bool isColumn = false}) {
    return GestureDetector(
      onTap: () => context.push(isColumn
          ? '/column/${article.cDate}/${article.id}'
          : '/news/${article.cDate}/${article.id}'),
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 4),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image
              ClipRRect(
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                child: CachedNetworkImage(
                  imageUrl: article.thumbnailPhotoUrl.isNotEmpty
                      ? article.thumbnailPhotoUrl
                      : article.photoUrl,
                  width: 100,
                  height: 80,
                  fit: BoxFit.cover,
                  filterQuality: FilterQuality.high,
                  placeholder: (context, url) => Container(
                    width: 100,
                    height: 80,
                    color: Colors.grey[300],
                    child: const Icon(Icons.image, color: Colors.grey),
                  ),
                  errorWidget: (context, url, error) => Container(
                    width: 100,
                    height: 80,
                    color: Colors.grey[300],
                    child: const Icon(Icons.error, color: Colors.grey),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      article.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimaryColor,
                        fontFamily: 'Cairo',
                        height: 1.3,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (showDate) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            article.publishDateFormatted.isNotEmpty
                                ? article.publishDateFormatted
                                : 'منذ قليل',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontFamily: 'Cairo',
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (isColumn && article.editorAndSource.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        article.editorAndSource,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Cairo',
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Shimmer widgets
  Widget _buildShimmerFeaturedCard() {
    return Container(
      height: 300,
      margin: const EdgeInsets.all(8),
      child: Shimmer.fromColors(
        baseColor: AppTheme.dividerColor,
        highlightColor: AppTheme.surfaceVariant,
        child: Card(
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          ),
          child: Container(color: AppTheme.backgroundColor),
        ),
      ),
    );
  }

  Widget _buildShimmerGrid({int itemCount = 4}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 1.2,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: itemCount,
        itemBuilder: (context, index) {
          return Shimmer.fromColors(
            baseColor: AppTheme.dividerColor,
            highlightColor: AppTheme.surfaceVariant,
            child: Card(
              margin: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              ),
              child: Container(color: AppTheme.backgroundColor),
            ),
          );
        },
      ),
    );
  }

  Widget _buildShimmerVerticalList({int itemCount = 20}) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: AppTheme.dividerColor,
          highlightColor: AppTheme.surfaceVariant,
          child: Card(
            margin: const EdgeInsets.symmetric(vertical: 4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            ),
            child: Container(
              height: 100,
              color: AppTheme.backgroundColor,
            ),
          ),
        );
      },
    );
  }
}
