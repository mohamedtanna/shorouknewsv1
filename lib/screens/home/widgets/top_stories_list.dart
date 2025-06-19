import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/theme.dart';
import '../../../providers/news_provider.dart';
import './horizontal_news_card.dart'; // Import the HorizontalNewsCard

class TopStoriesList extends StatelessWidget {
  final NewsProvider newsProvider;

  const TopStoriesList({
    super.key,
    required this.newsProvider,
  });

  @override
  Widget build(BuildContext context) {
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
        // Use HorizontalNewsCard here
        return HorizontalNewsCard(article: story, showDate: true);
      },
    );
  }

  Widget _buildShimmerVerticalList({int itemCount = 3}) { // Defaulted to 3 as per original usage
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
              height: 100, // Standard height for these shimmer cards
              color: AppTheme.backgroundColor,
            ),
          ),
        );
      },
    );
  }
}
