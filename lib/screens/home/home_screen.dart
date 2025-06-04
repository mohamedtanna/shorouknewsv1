import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';

import '../../providers/news_provider.dart';
import '../../models/news_model.dart';
import '../../models/column_model.dart';
import '../../widgets/news_card.dart';
import '../../widgets/column_card.dart';
import '../../widgets/ad_banner.dart';
import '../../widgets/section_header.dart';
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

  Future<void> _loadData() async {
    final newsProvider = context.read<NewsProvider>();
    await Future.wait([
      newsProvider.loadMainStories(),
      newsProvider.loadTopStories(),
      newsProvider.loadMostReadStories(),
      newsProvider.loadSelectedColumns(),
    ]);
  }

  Future<void> _refreshData() async {
    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: Consumer<NewsProvider>(
          builder: (context, newsProvider, child) {
            return CustomScrollView(
              controller: _scrollController,
              slivers: [
                // Ad Banner
                const SliverToBoxAdapter(
                  child: AdBanner(adUnit: '/21765378867/ShorouknewsApp_LeaderBoard1'),
                ),
                
                // Main Story Card
                SliverToBoxAdapter(
                  child: _buildMainStoryCard(newsProvider.mainStories),
                ),
                
                // Other Main Stories Grid
                SliverToBoxAdapter(
                  child: _buildMainStoriesGrid(newsProvider.mainStories),
                ),
                
                // Ad Banner
                const SliverToBoxAdapter(
                  child: AdBanner(adUnit: '/21765378867/ShorouknewsApp_Banner1'),
                ),
                
                // Top Stories Section
                SliverToBoxAdapter(
                  child: SectionHeader(
                    title: 'أهم الأخبار',
                    icon: Icons.trending_up,
                    onMorePressed: () => context.go('/news'),
                  ),
                ),
                
                SliverToBoxAdapter(
                  child: _buildTopStoriesList(newsProvider.topStories),
                ),
                
                // Ad Banner
                const SliverToBoxAdapter(
                  child: AdBanner(adUnit: '/21765378867/ShorouknewsApp_Banner2'),
                ),
                
                // Selected Columns Section
                SliverToBoxAdapter(
                  child: SectionHeader(
                    title: 'مقالات مختارة',
                    icon: Icons.article,
                    onMorePressed: () => context.go('/columns'),
                  ),
                ),
                
                SliverToBoxAdapter(
                  child: _buildSelectedColumnsList(newsProvider.selectedColumns),
                ),
                
                // Most Read Section
                SliverToBoxAdapter(
                  child: SectionHeader(
                    title: 'الأكثر قراءة',
                    icon: Icons.visibility,
                  ),
                ),
                
                SliverToBoxAdapter(
                  child: _buildMostReadList(newsProvider.mostReadStories),
                ),
                
                // Bottom spacing
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

  Widget _buildMainStoryCard(List<NewsArticle> mainStories) {
    if (mainStories.isEmpty) {
      return _buildShimmerMainCard();
    }

    final mainStory = mainStories.first;
    
    return Container(
      height: 250,
      margin: const EdgeInsets.all(8),
      child: GestureDetector(
        onTap: () => context.go('/news/${mainStory.cDate}/${mainStory.id}'),
        child: Card(
          margin: EdgeInsets.zero,
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              CachedNetworkImage(
                imageUrl: mainStory.photoUrl,
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Colors.grey[300],
                  child: const Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey[300],
                  child: const Icon(Icons.error),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.7),
                    ],
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
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
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

  Widget _buildMainStoriesGrid(List<NewsArticle> mainStories) {
    if (mainStories.length <= 1) return const SizedBox.shrink();
    
    final otherStories = mainStories.skip(1).take(4).toList();
    
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
          return NewsCard(
            article: story,
            onTap: () => context.go('/news/${story.cDate}/${story.id}'),
          );
        },
      ),
    );
  }

  Widget _buildTopStoriesList(List<NewsArticle> topStories) {
    if (topStories.isEmpty) {
      return _buildShimmerList();
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: topStories.length.clamp(0, 5),
      itemBuilder: (context, index) {
        final story = topStories[index];
        return NewsCard(
          article: story,
          isHorizontal: true,
          onTap: () => context.go('/news/${story.cDate}/${story.id}'),
        );
      },
    );
  }

  Widget _buildSelectedColumnsList(List<ColumnModel> columns) {
    if (columns.isEmpty) {
      return _buildShimmerList();
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: columns.length,
      itemBuilder: (context, index) {
        final column = columns[index];
        return ColumnCard(
          column: column,
          onTap: () => context.go('/column/${column.cDate}/${column.id}'),
        );
      },
    );
  }

  Widget _buildMostReadList(List<NewsArticle> mostReadStories) {
    if (mostReadStories.isEmpty) {
      return _buildShimmerList();
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: mostReadStories.length,
      itemBuilder: (context, index) {
        final story = mostReadStories[index];
        return NewsCard(
          article: story,
          isHorizontal: true,
          onTap: () => context.go('/news/${story.cDate}/${story.id}'),
        );
      },
    );
  }

  Widget _buildShimmerMainCard() {
    return Container(
      height: 250,
      margin: const EdgeInsets.all(8),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Card(
          margin: EdgeInsets.zero,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerList() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 3,
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            height: 100,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(8),
            ),
          );
        },
      ),
    );
  }
}