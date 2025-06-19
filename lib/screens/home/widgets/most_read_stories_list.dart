import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:shorouk_news/models/new_model.dart';
import '../../../core/theme.dart';
import '../../../providers/news_provider.dart';
import './horizontal_news_card.dart';

class MostReadStoriesList extends StatelessWidget {
  final NewsProvider newsProvider;

  const MostReadStoriesList({
    super.key,
    required this.newsProvider,
  });

  @override
  Widget build(BuildContext context) {
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
        return HorizontalNewsCard(article: story, showDate: false);
      },
    );
  }

  Widget _buildShimmerVerticalList({int itemCount = 3}) {
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
