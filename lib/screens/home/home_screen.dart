import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';

// Provider for fetching news and column data
import '../../providers/news_provider.dart';

// Data models for news articles and columns
import '../../models/news_model.dart';
import '../../models/column_model.dart'; // Assuming this model exists for columns

// Reusable widgets for displaying content and ads
import '../../widgets/news_card.dart'; // Displays individual news articles
import '../../widgets/column_card.dart'; // Displays individual columns (ensure this widget exists)
import '../../widgets/ad_banner.dart'; // Displays advertisements
import '../../widgets/section_header.dart'; // Displays titles for content sections

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
    // Fetch initial data after the first frame is rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  /// Fetches all necessary data for the home screen.
  /// This includes main stories, top stories, most read stories, and selected columns.
  Future<void> _loadData({bool refresh = false}) async {
    // Access the NewsProvider from the widget tree
    final newsProvider = context.read<NewsProvider>();
    if (refresh) {
      // If refreshing, clear existing data and reload everything
      // The provider's refreshAllData should handle individual loading states.
      await newsProvider.refreshAllData();
    } else {
      // Initial load or if data is not yet available
      // Check if data needs to be loaded to avoid redundant calls if already loaded.
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

  /// Handles the pull-to-refresh action.
  Future<void> _refreshData() async {
    await _loadData(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // The main body of the home screen
      body: RefreshIndicator(
        onRefresh: _refreshData, // Callback for pull-to-refresh
        color: AppTheme.primaryColor, // Color of the refresh indicator
        child: Consumer<NewsProvider>(
          // Listens to changes in NewsProvider and rebuilds the UI accordingly
          builder: (context, newsProvider, child) {
            return CustomScrollView(
              controller: _scrollController, // Controller for scroll-related actions
              slivers: [
                // Top Advertisement Banner
                const SliverToBoxAdapter(
                  child: AdBanner(adUnit: '/21765378867/ShorouknewsApp_LeaderBoard1'),
                ),

                // Main Story Card (Top-most prominent story)
                SliverToBoxAdapter(
                  child: _buildMainStoryCard(newsProvider),
                ),

                // Grid of other Main Stories (Typically 2-4 additional main stories)
                SliverToBoxAdapter(
                  child: _buildMainStoriesGrid(newsProvider),
                ),

                // Second Advertisement Banner
                const SliverToBoxAdapter(
                  child: AdBanner(adUnit: '/21765378867/ShorouknewsApp_Banner1'),
                ),

                // Top Stories Section
                SliverToBoxAdapter(
                  child: SectionHeader(
                    title: 'أهم الأخبار', // "Top News"
                    icon: Icons.trending_up,
                    onMorePressed: () => context.go('/news'), // Navigate to full news list
                  ),
                ),
                SliverToBoxAdapter(
                  child: _buildTopStoriesList(newsProvider),
                ),

                // Third Advertisement Banner
                const SliverToBoxAdapter(
                  child: AdBanner(adUnit: '/21765378867/ShorouknewsApp_Banner2'),
                ),

                // Selected Columns Section
                SliverToBoxAdapter(
                  child: SectionHeader(
                    title: 'مقالات مختارة', // "Selected Columns"
                    icon: Icons.article_outlined, // Using outlined version
                    onMorePressed: () => context.go('/columns'), // Navigate to full columns list
                  ),
                ),
                SliverToBoxAdapter(
                  child: _buildSelectedColumnsList(newsProvider),
                ),

                // Most Read Stories Section
                SliverToBoxAdapter(
                  child: SectionHeader(
                    title: 'الأكثر قراءة', // "Most Read"
                    icon: Icons.visibility_outlined, // Using outlined version
                    // Optionally add onMorePressed if there's a dedicated "Most Read" screen
                  ),
                ),
                SliverToBoxAdapter(
                  child: _buildMostReadList(newsProvider),
                ),
                
                // Ad Banner (MPU or similar)
                const SliverToBoxAdapter(
                  child: AdBanner(adUnit: '/21765378867/ShorouknewsApp_MPU1'),
                ),

                // Bottom spacing to ensure content isn't cut off by navigation bars etc.
                const SliverToBoxAdapter(
                  child: SizedBox(height: 20),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// Builds the main story card.
  /// Displays the first article from `mainStories` list.
  Widget _buildMainStoryCard(NewsProvider newsProvider) {
    // Show shimmer if loading, otherwise display the card or an empty box.
    if (newsProvider.isLoadingMainStories && newsProvider.mainStories.isEmpty) {
      return _buildShimmerMainCard();
    }
    if (newsProvider.mainStories.isEmpty) {
      return const SizedBox.shrink(); // Return an empty box if no stories
    }

    final mainStory = newsProvider.mainStories.first;

    return Container(
      height: 250, // Fixed height for the main story card
      margin: const EdgeInsets.all(8),
      child: GestureDetector(
        onTap: () => context.go('/news/${mainStory.cDate}/${mainStory.id}'),
        child: Card(
          margin: EdgeInsets.zero,
          clipBehavior: Clip.antiAlias, // Ensures content respects card's rounded corners
          elevation: 4.0, // Adds a subtle shadow
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
          child: Stack(
            // Stack allows overlaying text on the image
            children: [
              // Background Image
              Positioned.fill(
                child: CachedNetworkImage(
                  imageUrl: mainStory.photoUrl,
                  fit: BoxFit.cover, // Cover the entire card area
                  placeholder: (context, url) => Shimmer.fromColors(
                    baseColor: Colors.grey[300]!,
                    highlightColor: Colors.grey[100]!,
                    child: Container(color: Colors.white),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey[300],
                    child: const Icon(Icons.broken_image, color: Colors.grey, size: 50),
                  ),
                ),
              ),
              // Gradient overlay for better text readability
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
              // Story Title
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: Text(
                  mainStory.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20, // Slightly larger font for main story
                    fontWeight: FontWeight.bold,
                    shadows: [ // Text shadow for better contrast
                      Shadow(blurRadius: 2.0, color: Colors.black54, offset: Offset(1,1))
                    ]
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

  /// Builds a grid for other main stories (excluding the first one).
  Widget _buildMainStoriesGrid(NewsProvider newsProvider) {
    // Show shimmer if loading, otherwise display the grid or an empty box.
    if (newsProvider.isLoadingMainStories && newsProvider.mainStories.length <= 1) {
       // Show shimmer for the grid if main stories are loading and only the main one might be present
      return _buildShimmerGrid(itemCount: 2);
    }
    if (newsProvider.mainStories.length <= 1) {
      return const SizedBox.shrink(); // No other stories to display
    }

    // Take up to 4 stories, skipping the first one (already shown in _buildMainStoryCard)
    final otherStories = newsProvider.mainStories.skip(1).take(4).toList();
    if (otherStories.isEmpty) return const SizedBox.shrink();


    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: GridView.builder(
        shrinkWrap: true, // Important for GridView inside CustomScrollView
        physics: const NeverScrollableScrollPhysics(), // Disable GridView's own scrolling
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, // Two items per row
          childAspectRatio: 0.85, // Adjust for desired card proportions (width/height)
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: otherStories.length,
        itemBuilder: (context, index) {
          final story = otherStories[index];
          // Using the standard NewsCard for these items
          return NewsCard(
            article: story,
            onTap: () => context.go('/news/${story.cDate}/${story.id}'),
            // isHorizontal: false, // Vertical card for grid
          );
        },
      ),
    );
  }

  /// Builds a horizontal list for top stories.
  Widget _buildTopStoriesList(NewsProvider newsProvider) {
    // Show shimmer if loading, otherwise display the list or an empty box.
    if (newsProvider.isLoadingTopStories && newsProvider.topStories.isEmpty) {
      return _buildShimmerHorizontalList();
    }
    if (newsProvider.topStories.isEmpty) {
      return const Center(child: Padding(padding: EdgeInsets.all(16.0), child: Text('لا توجد أخبار هامة حالياً.')));
    }

    return SizedBox(
      height: 130, // Fixed height for horizontal list items
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        itemCount: newsProvider.topStories.length.clamp(0, 5), // Show up to 5 top stories
        itemBuilder: (context, index) {
          final story = newsProvider.topStories[index];
          return SizedBox(
            width: 280, // Width of each card in the horizontal list
            child: NewsCard(
              article: story,
              isHorizontal: true, // Use horizontal layout for NewsCard
              onTap: () => context.go('/news/${story.cDate}/${story.id}'),
            ),
          );
        },
      ),
    );
  }

  /// Builds a list for selected columns.
  Widget _buildSelectedColumnsList(NewsProvider newsProvider) {
    // Show shimmer if loading, otherwise display the list or an empty box.
    if (newsProvider.isLoadingColumns && newsProvider.selectedColumns.isEmpty) {
      return _buildShimmerVerticalList(itemCount: 2);
    }
    if (newsProvider.selectedColumns.isEmpty) {
      return const Center(child: Padding(padding: EdgeInsets.all(16.0), child: Text('لا توجد مقالات مختارة حالياً.')));
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: newsProvider.selectedColumns.length.clamp(0, 3), // Show up to 3 columns
      itemBuilder: (context, index) {
        final column = newsProvider.selectedColumns[index];
        // Ensure ColumnCard widget exists and is correctly implemented
        return ColumnCard(
          column: column,
          onTap: () => context.go('/column/${column.cDate}/${column.id}'),
        );
      },
    );
  }

  /// Builds a list for most read stories.
  Widget _buildMostReadList(NewsProvider newsProvider) {
    // Show shimmer if loading, otherwise display the list or an empty box.
    if (newsProvider.isLoadingMostRead && newsProvider.mostReadStories.isEmpty) {
      return _buildShimmerVerticalList(itemCount: 3);
    }
    if (newsProvider.mostReadStories.isEmpty) {
      return const Center(child: Padding(padding: EdgeInsets.all(16.0), child: Text('لا توجد أخبار رائجة حالياً.')));
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: newsProvider.mostReadStories.length.clamp(0,5), // Show up to 5 most read
      itemBuilder: (context, index) {
        final story = newsProvider.mostReadStories[index];
        return NewsCard(
          article: story,
          isHorizontal: true, // Horizontal layout for list items
          onTap: () => context.go('/news/${story.cDate}/${story.id}'),
          showDate: false, // Date might be less relevant for "most read" in this compact view
        );
      },
    );
  }

  // --- Shimmer Placeholder Widgets ---

  /// Builds a shimmer placeholder for the main story card.
  Widget _buildShimmerMainCard() {
    return Container(
      height: 250,
      margin: const EdgeInsets.all(8),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Card(
          margin: EdgeInsets.zero,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
          child: Container(color: Colors.white),
        ),
      ),
    );
  }

  /// Builds a shimmer placeholder for a grid of items.
  Widget _buildShimmerGrid({int itemCount = 2}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.85,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: itemCount,
        itemBuilder: (context, index) {
          return Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Card(
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
              child: Container(color: Colors.white),
            ),
          );
        },
      ),
    );
  }

  /// Builds a shimmer placeholder for a horizontal list.
  Widget _buildShimmerHorizontalList({int itemCount = 3}) {
    return SizedBox(
      height: 130,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        itemCount: itemCount,
        itemBuilder: (context, index) {
          return Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: SizedBox(
              width: 280,
              child: Card(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                child: Container(color: Colors.white),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Builds a shimmer placeholder for a vertical list.
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
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
            child: Container(
              height: 100, // Typical height for a list item card
              color: Colors.white,
            ),
          ),
        );
      },
    );
  }
}
