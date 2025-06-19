import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
// Assuming NewSArticle is NewArticle
import '../../../core/theme.dart';
import '../../../providers/news_provider.dart'; // Required for NewsProvider type

class MainFeaturedStory extends StatelessWidget {
  final NewsProvider newsProvider;

  const MainFeaturedStory({
    super.key,
    required this.newsProvider,
  });

  @override
  Widget build(BuildContext context) {
    if (newsProvider.isLoadingMainStories && newsProvider.mainStories.isEmpty) {
      return _buildShimmerFeaturedCard();
    }
    if (newsProvider.mainStories.isEmpty) {
      return const SizedBox.shrink(); // Or some placeholder if no story
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
}
