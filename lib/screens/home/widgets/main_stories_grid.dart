import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import 'package:shorouk_news/models/new_model.dart';
import '../../../core/theme.dart';
import '../../../providers/news_provider.dart';

class MainStoriesGrid extends StatelessWidget {
  final NewsProvider newsProvider;

  const MainStoriesGrid({
    super.key,
    required this.newsProvider,
  });

  @override
  Widget build(BuildContext context) {
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
          return _buildGridNewsCard(context, story); // Pass context here
        },
      ),
    );
  }

  Widget _buildGridNewsCard(BuildContext context, NewsArticle story) { // Accept context
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
}
