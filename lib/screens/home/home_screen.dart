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
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _refreshData,
        color: AppTheme.primaryColor,
        child: Consumer<NewsProvider>(
          builder: (context, newsProvider, child) {
            return CustomScrollView(
              controller: _scrollController,
              slivers: [
                // Main Story Card - Reduced margins
                SliverToBoxAdapter(
                  child: _buildMainStoryCard(newsProvider),
                ),

                // Grid of other Main Stories - Tighter spacing
                SliverToBoxAdapter(
                  child: _buildMainStoriesGrid(newsProvider),
                ),

                // Top Stories Section - Reduced spacing
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
                    child: SectionHeader(
                      title: 'أهم الأخبار',
                      icon: Icons.trending_up,
                      onMorePressed: () => context.go('/news'),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: _buildTopStoriesList(newsProvider),
                ),

                // Selected Columns Section - Reduced spacing
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
                    child: SectionHeader(
                      title: 'مقالات مختارة',
                      icon: Icons.article_outlined,
                      onMorePressed: () => context.go('/columns'),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: _buildSelectedColumnsList(newsProvider),
                ),

                // Most Read Stories Section - Reduced spacing
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
                    child: const SectionHeader(
                      title: 'الأكثر قراءة',
                      icon: Icons.visibility_outlined,
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: _buildMostReadList(newsProvider),
                ),

                // Minimal bottom spacing
                const SliverToBoxAdapter(
                  child: SizedBox(height: 12),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildMainStoryCard(NewsProvider newsProvider) {
    if (newsProvider.isLoadingMainStories && newsProvider.mainStories.isEmpty) {
      return _buildShimmerMainCard();
    }
    if (newsProvider.mainStories.isEmpty) {
      return const SizedBox.shrink();
    }

    final mainStory = newsProvider.mainStories.first;

    return Container(
      height: 220, // Reduced height
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 4), // Tighter margins
      child: GestureDetector(
        onTap: () => context.go('/news/${mainStory.cDate}/${mainStory.id}'),
        child: Card(
          margin: EdgeInsets.zero,
          clipBehavior: Clip.antiAlias,
          elevation: 3.0, // Reduced elevation
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
          child: Stack(
            children: [
              Positioned.fill(
                child: CachedNetworkImage(
                  imageUrl: mainStory.photoUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Shimmer.fromColors(
                    baseColor: Colors.grey[300]!,
                    highlightColor: Colors.grey[100]!,
                    child: Container(color: Colors.white),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey[300],
                    child: const Icon(Icons.broken_image,
                        color: Colors.grey, size: 50),
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
                        Colors.black.withOpacity(0.1),
                        Colors.black.withOpacity(0.7),
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 12, // Reduced padding
                left: 12,
                right: 12,
                child: Text(
                  mainStory.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18, // Slightly smaller font
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        blurRadius: 2.0,
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
      return _buildShimmerGrid(itemCount: 2);
    }
    if (newsProvider.mainStories.length <= 1) {
      return const SizedBox.shrink();
    }

    final otherStories = newsProvider.mainStories.skip(1).take(4).toList();
    if (otherStories.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(
          horizontal: 12, vertical: 8), // Tighter margins
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75, // More vertical space for better content fit
          crossAxisSpacing: 6,
          mainAxisSpacing: 6,
        ),
        itemCount: otherStories.length,
        itemBuilder: (context, index) {
          final story = otherStories[index];
          return NewsCard(
            article: story,
            onTap: () => context.go('/news/${story.cDate}/${story.id}'),
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
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('لا توجد أخبار هامة حالياً.'),
        ),
      );
    }

    return SizedBox(
      height: 120, // Reduced height
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
            horizontal: 8, vertical: 4), // Reduced padding
        itemCount: newsProvider.topStories.length.clamp(0, 5),
        itemBuilder: (context, index) {
          final story = newsProvider.topStories[index];
          return SizedBox(
            width: 260, // Reduced width
            child: NewsCard(
              article: story,
              isHorizontal: true,
              onTap: () => context.go('/news/${story.cDate}/${story.id}'),
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
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('لا توجد مقالات مختارة حالياً.'),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 4), // Added padding
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
          onTap: () => context.go('/column/${column.cDate}/${column.id}'),
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
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('لا توجد أخبار رائجة حالياً.'),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 4), // Added padding
      itemCount: newsProvider.mostReadStories.length.clamp(0, 5),
      itemBuilder: (context, index) {
        final story = newsProvider.mostReadStories[index];
        return NewsCard(
          article: story,
          isHorizontal: true,
          onTap: () => context.go('/news/${story.cDate}/${story.id}'),
          showDate: false,
        );
      },
    );
  }

  // Shimmer widgets with reduced sizes
  Widget _buildShimmerMainCard() {
    return Container(
      height: 220, // Matching reduced height
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Card(
          margin: EdgeInsets.zero,
          clipBehavior: Clip.antiAlias,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
          child: Container(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildShimmerGrid({int itemCount = 2}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75,
          crossAxisSpacing: 6,
          mainAxisSpacing: 6,
        ),
        itemCount: itemCount,
        itemBuilder: (context, index) {
          return Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Card(
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0)),
              child: Container(color: Colors.white),
            ),
          );
        },
      ),
    );
  }

  Widget _buildShimmerHorizontalList({int itemCount = 3}) {
    return SizedBox(
      height: 120, // Matching reduced height
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        itemCount: itemCount,
        itemBuilder: (context, index) {
          return Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: SizedBox(
              width: 260,
              child: Card(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0)),
                child: Container(color: Colors.white),
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
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Card(
            margin: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 4), // Reduced margins
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0)),
            child: Container(
              height: 90, // Reduced height
              color: Colors.white,
            ),
          ),
        );
      },
    );
  }
}
