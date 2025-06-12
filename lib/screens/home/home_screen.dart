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
import 'package:shorouk_news/widgets/news_card.dart';
import '../../widgets/section_header.dart';

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
      body: RefreshIndicator(
        onRefresh: _refreshData,
        color: AppTheme.primaryColor,
        child: Consumer<NewsProvider>(
          builder: (context, newsProvider, child) {
            return CustomScrollView(
              controller: _scrollController,
              slivers: [
                // Main Story Card
                SliverToBoxAdapter(
                  child: _buildMainStoryCard(newsProvider, theme),
                ),

                // Grid of other Main Stories
                SliverToBoxAdapter(
                  child: _buildMainStoriesGrid(newsProvider),
                ),

                // Top Stories Section
                SliverToBoxAdapter(
                  child: Padding(
                    padding: AppTheme.paddingMedium
                        .copyWith(bottom: AppTheme.paddingSmall.bottom),
                    child: SectionHeader(
                      title: 'أهم الأخبار',
                      icon: Icons.trending_up,
                      onMorePressed: () => context.push('/news'),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: _buildTopStoriesList(newsProvider),
                ),

                // Selected Columns Section
                SliverToBoxAdapter(
                  child: Padding(
                    padding: AppTheme.paddingMedium
                        .copyWith(bottom: AppTheme.paddingSmall.bottom),
                    child: SectionHeader(
                      title: 'مقالات مختارة',
                      icon: Icons.article_outlined,
                      onMorePressed: () => context.push('/columns'),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: _buildSelectedColumnsList(newsProvider),
                ),

                // Most Read Stories Section
                SliverToBoxAdapter(
                  child: Padding(
                    padding: AppTheme.paddingMedium
                        .copyWith(bottom: AppTheme.paddingSmall.bottom),
                    child: const SectionHeader(
                      title: 'الأكثر قراءة',
                      icon: Icons.visibility_outlined,
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: _buildMostReadList(newsProvider),
                ),

                // Bottom spacing
                SliverToBoxAdapter(
                  child: AppTheme.verticalSpaceMedium,
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildMainStoryCard(NewsProvider newsProvider, ThemeData theme) {
    if (newsProvider.isLoadingMainStories && newsProvider.mainStories.isEmpty) {
      return _buildShimmerMainCard();
    }
    if (newsProvider.mainStories.isEmpty) {
      return const SizedBox.shrink();
    }

    final mainStory = newsProvider.mainStories.first;

    return Container(
      height: 240, // Slightly increased for better readability
      margin: AppTheme.marginMedium.copyWith(top: AppTheme.marginSmall.top),
      child: GestureDetector(
        onTap: () => context.push('/news/${mainStory.cDate}/${mainStory.id}'),
        child: Card(
          margin: EdgeInsets.zero,
          clipBehavior: Clip.antiAlias,
          elevation: AppTheme.elevationMedium,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: CachedNetworkImage(
                  imageUrl: mainStory.photoUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Shimmer.fromColors(
                    baseColor: AppTheme.dividerColor,
                    highlightColor: AppTheme.surfaceVariant,
                    child: Container(color: AppTheme.backgroundColor),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: AppTheme.surfaceVariant,
                    child: Icon(
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
                        AppTheme.shadowLight,
                        AppTheme.shadowDark,
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: AppTheme.paddingMedium.bottom,
                left: AppTheme.paddingMedium.left,
                right: AppTheme.paddingMedium.right,
                child: Text(
                  mainStory.title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: AppTheme.textOnPrimary,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        blurRadius: 3.0,
                        color: AppTheme.shadowDark,
                        offset: const Offset(1, 1),
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
      return _buildShimmerGrid(itemCount: 2);
    }
    if (newsProvider.mainStories.length <= 1) {
      return const SizedBox.shrink();
    }

    final otherStories = newsProvider.mainStories.skip(1).take(4).toList();
    if (otherStories.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: AppTheme.marginMedium,
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75,
          crossAxisSpacing: AppTheme.radiusSmall,
          mainAxisSpacing: AppTheme.radiusSmall,
        ),
        itemCount: otherStories.length,
        itemBuilder: (context, index) {
          final story = otherStories[index];
          return NewsCard(
            article: story,
            onTap: () => context.push('/news/${story.cDate}/${story.id}'),
          );
        },
      ),
    );
  }

  Widget _buildTopStoriesList(NewsProvider newsProvider) {
    if (newsProvider.isLoadingTopStories && newsProvider.topStories.isEmpty) {
      return _buildShimmerHorizontalList();
    }
    if (newsProvider.topStories.isEmpty) {
      return Center(
        child: Padding(
          padding: AppTheme.paddingLarge,
          child: Text(
            'لا توجد أخبار هامة حالياً.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondaryColor,
                ),
          ),
        ),
      );
    }

    return SizedBox(
      height: 140, // Increased for better content visibility
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: AppTheme.paddingSmall,
        itemCount: newsProvider.topStories.length.clamp(0, 5),
        itemBuilder: (context, index) {
          final story = newsProvider.topStories[index];
          return SizedBox(
            width: 280, // Increased width for better readability
            child: NewsCard(
              article: story,
              isHorizontal: true,
              onTap: () => context.push('/news/${story.cDate}/${story.id}'),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSelectedColumnsList(NewsProvider newsProvider) {
    if (newsProvider.isLoadingColumns && newsProvider.selectedColumns.isEmpty) {
      return _buildShimmerVerticalList(itemCount: 2);
    }
    if (newsProvider.selectedColumns.isEmpty) {
      return Center(
        child: Padding(
          padding: AppTheme.paddingLarge,
          child: Text(
            'لا توجد مقالات مختارة حالياً.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondaryColor,
                ),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: AppTheme.paddingSmall,
      itemCount: newsProvider.selectedColumns.length.clamp(0, 3),
      itemBuilder: (context, index) {
        final column = newsProvider.selectedColumns[index];
        return NewsCard(
          article: NewsArticle(
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
          ),
          isHorizontal: true,
          onTap: () => context.push('/column/${column.cDate}/${column.id}'),
          showDate: true,
        );
      },
    );
  }

  Widget _buildMostReadList(NewsProvider newsProvider) {
    if (newsProvider.isLoadingMostRead &&
        newsProvider.mostReadStories.isEmpty) {
      return _buildShimmerVerticalList(itemCount: 3);
    }
    if (newsProvider.mostReadStories.isEmpty) {
      return Center(
        child: Padding(
          padding: AppTheme.paddingLarge,
          child: Text(
            'لا توجد أخبار رائجة حالياً.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondaryColor,
                ),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: AppTheme.paddingSmall,
      itemCount: newsProvider.mostReadStories.length.clamp(0, 5),
      itemBuilder: (context, index) {
        final story = newsProvider.mostReadStories[index];
        return NewsCard(
          article: story,
          isHorizontal: true,
          onTap: () => context.push('/news/${story.cDate}/${story.id}'),
          showDate: false,
        );
      },
    );
  }

  // Shimmer widgets using theme colors and spacing
  Widget _buildShimmerMainCard() {
    return Container(
      height: 240,
      margin: AppTheme.marginMedium.copyWith(top: AppTheme.marginSmall.top),
      child: Shimmer.fromColors(
        baseColor: AppTheme.dividerColor,
        highlightColor: AppTheme.surfaceVariant,
        child: Card(
          margin: EdgeInsets.zero,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          ),
          child: Container(color: AppTheme.backgroundColor),
        ),
      ),
    );
  }

  Widget _buildShimmerGrid({int itemCount = 2}) {
    return Container(
      margin: AppTheme.marginMedium,
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75,
          crossAxisSpacing: AppTheme.radiusSmall,
          mainAxisSpacing: AppTheme.radiusSmall,
        ),
        itemCount: itemCount,
        itemBuilder: (context, index) {
          return Shimmer.fromColors(
            baseColor: AppTheme.dividerColor,
            highlightColor: AppTheme.surfaceVariant,
            child: Card(
              clipBehavior: Clip.antiAlias,
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

  Widget _buildShimmerHorizontalList({int itemCount = 3}) {
    return SizedBox(
      height: 140,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: AppTheme.paddingSmall,
        itemCount: itemCount,
        itemBuilder: (context, index) {
          return Shimmer.fromColors(
            baseColor: AppTheme.dividerColor,
            highlightColor: AppTheme.surfaceVariant,
            child: SizedBox(
              width: 280,
              child: Card(
                margin: EdgeInsets.symmetric(
                    horizontal: AppTheme.marginSmall.horizontal / 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                ),
                child: Container(color: AppTheme.backgroundColor),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildShimmerVerticalList({int itemCount = 3}) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: AppTheme.dividerColor,
          highlightColor: AppTheme.surfaceVariant,
          child: Card(
            margin: AppTheme.marginMedium.copyWith(
              top: AppTheme.marginSmall.top,
              bottom: AppTheme.marginSmall.bottom,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            ),
            child: Container(
              height: 100, // Slightly increased for better proportions
              color: AppTheme.backgroundColor,
            ),
          ),
        );
      },
    );
  }
}
