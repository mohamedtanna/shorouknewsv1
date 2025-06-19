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
      return _buildShimmerGrid(context, itemCount: 4); // Pass context
    }
    if (newsProvider.mainStories.length <= 1) {
      return const SizedBox.shrink();
    }

    final otherStories = newsProvider.mainStories.skip(1).take(4).toList();
    if (otherStories.isEmpty) return const SizedBox.shrink();

    // Calculate childAspectRatio for 16:9 image and some text height
    // This is an approximation. Card height = Image height + Text Area height
    // Image height = cardWidth / (16/9)
    // Let's assume text area height is roughly 70-80 pixels for 2 lines of text + padding
    // childAspectRatio = cardWidth / cardHeight
    // For a 2-column grid, cardWidth is roughly screenWidth / 2.
    // This might need fine-tuning or a more robust way to calculate aspect ratio if text height varies a lot.
    // Or, fix the height of the card and let GridView handle it.
    // For simplicity, let's aim for a common fixed aspect ratio for the card itself.
    // Let image be 16:9. If card width is W, image height is W * 9/16.
    // Add space for text (e.g. 60px). Card height = W * 9/16 + 60.
    // childAspectRatio = W / (W * 9/16 + 60).
    // A common card aspect ratio is around 2/3 or 3/4. Let's try 0.7 for now.
    // This might need adjustment based on visual testing.

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8), // Added vertical margin
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.7, // Adjusted aspect ratio, may need tuning
          crossAxisSpacing: 12, // Increased spacing
          mainAxisSpacing: 12,  // Increased spacing
        ),
        itemCount: otherStories.length,
        itemBuilder: (context, index) {
          final story = otherStories[index];
          return _buildGridNewsCard(context, story);
        },
      ),
    );
  }

  Widget _buildGridNewsCard(BuildContext context, NewsArticle story) {
    return GestureDetector(
      onTap: () => context.push('/news/${story.cDate}/${story.id}'),
      child: Card(
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias, // Important for rounded corners on image
        elevation: AppTheme.elevationSmall, // Consistent elevation
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusDefault), // Consistent radius
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, // Align content to start
          children: [
            // Image with AspectRatio
            AspectRatio(
              aspectRatio: 16 / 9,
              child: CachedNetworkImage(
                imageUrl: story.thumbnailPhotoUrl.isNotEmpty
                    ? story.thumbnailPhotoUrl
                    : story.photoUrl,
                fit: BoxFit.cover,
                filterQuality: FilterQuality.high,
                placeholder: (context, url) => Shimmer.fromColors(
                  baseColor: AppTheme.dividerColor,
                  highlightColor: AppTheme.surfaceVariant,
                  child: Container(color: AppTheme.backgroundColor),
                ),
                errorWidget: (context, url, error) => Container(
                  color: AppTheme.surfaceVariant,
                  child: const Icon(Icons.broken_image_outlined, color: AppTheme.textDisabledColor, size: 40),
                ),
              ),
            ),
            // Text content area
            Padding(
              padding: const EdgeInsets.all(10.0), // Padding for text content
              child: Text(
                story.title,
                style: TextStyle(
                  color: AppTheme.textPrimaryColor, // Use theme color
                  fontSize: 15, // Adjust as needed
                  fontWeight: FontWeight.bold, // Bold title
                  fontFamily: 'Cairo', // Your custom font
                  height: 1.3, // Line height
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.start, // Respect RTL
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerGrid(BuildContext context, {int itemCount = 4}) {
     // Using the same aspect ratio for shimmer cards
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.7, // Match the actual card's aspect ratio
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: itemCount,
        itemBuilder: (context, index) {
          return Shimmer.fromColors(
            baseColor: AppTheme.dividerColor,
            highlightColor: AppTheme.surfaceVariant,
            child: Card(
              margin: EdgeInsets.zero,
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusDefault),
              ),
              child: Column( // Mimic card structure for shimmer
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Container(color: AppTheme.backgroundColor),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(height: 14, width: double.infinity, color: AppTheme.backgroundColor),
                        const SizedBox(height: 6),
                        Container(height: 14, width: MediaQuery.of(context).size.width * 0.3, color: AppTheme.backgroundColor),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
