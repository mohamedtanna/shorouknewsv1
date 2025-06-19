import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

// Provider for fetching news and column data
import '../../providers/news_provider.dart';
import '../../providers/weather_provider.dart';

// Data models for news articles and columns
// import 'package:shorouk_news/models/new_model.dart'; // No longer directly used here
import '../../widgets/weather_widget.dart';

// Reusable widgets for displaying content and ads
//import 'package:shorouk_news/widgets/news_card.dart';
//import '../../widgets/section_header.dart';

// Theme and styling for the application
import '../../core/theme.dart';
import './widgets/home_section_header.dart';
import './widgets/main_featured_story.dart';
import './widgets/main_stories_grid.dart';
import './widgets/top_stories_list.dart';
import './widgets/selected_columns_list.dart';
import './widgets/most_read_stories_list.dart';

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
      context.read<WeatherProvider>().requestWeatherForCurrentLocation();
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
    // final theme = Theme.of(context); // Unused

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
                  child: MainFeaturedStory(newsProvider: newsProvider),
                ),

                // Grid of Main Stories - 2x2 grid layout like in screenshots
                SliverToBoxAdapter(
                  child: MainStoriesGrid(newsProvider: newsProvider),
                ),

                // Top Stories Section with blue header
                SliverToBoxAdapter(
                  child: HomeSectionHeader(
                    title: 'أهم الأخبار',
                    icon: Icons.trending_up,
                    onMorePressed: () => context.push('/news'),
                  ),
                ),
                SliverToBoxAdapter(
                  child: TopStoriesList(newsProvider: newsProvider),
                ),

                // Selected Columns Section with blue header
                SliverToBoxAdapter(
                  child: HomeSectionHeader(
                    title: 'مقالات مختارة',
                    icon: Icons.article_outlined,
                    onMorePressed: () => context.push('/columns'),
                  ),
                ),
                SliverToBoxAdapter(
                  child: SelectedColumnsList(newsProvider: newsProvider),
                ),

                // Weather widget before most read section
                SliverToBoxAdapter(
                  child: Consumer<WeatherProvider>(
                    builder: (context, weatherProvider, child) {
                      if (weatherProvider.isLoading) {
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      return WeatherWidget(info: weatherProvider.info);
                    },
                  ),
                ),

                // Most Read Stories Section with blue header
                SliverToBoxAdapter(
                  child: HomeSectionHeader(
                    title: 'الأكثر قراءة',
                    icon: Icons.visibility_outlined,
                  ),
                ),
                SliverToBoxAdapter(
                  child: MostReadStoriesList(newsProvider: newsProvider),
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
}
