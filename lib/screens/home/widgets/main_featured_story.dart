import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import 'package:shorouk_news/models/new_model.dart';
import '../../../core/theme.dart';
import '../../../providers/news_provider.dart';
import 'package:intl/intl.dart'; // For date formatting for the "New" badge

class MainFeaturedStory extends StatelessWidget {
  final NewsProvider newsProvider;

  const MainFeaturedStory({
    super.key,
    required this.newsProvider,
  });

  bool _isNew(NewsArticle article) {
    try {
      // Assuming publishDate is in a format that can be parsed.
      // Example: "yyyy-MM-ddTHH:mm:ssZ" or similar ISO format.
      // Or, if it's already a DateTime object from the model, this parsing is not needed.
      DateTime publishDateTime;
      if (article.publishDate is DateTime) {
        publishDateTime = article.publishDate;
      } else if (article.publishDate is String) {
        // Attempt to parse based on common formats if it's a string
        // This might need adjustment based on the actual format of article.publishDate
        try {
            publishDateTime = DateTime.parse(article.publishDate);
        } catch (e) {
            // Fallback for "dd/MM/yyyy" if parsing as ISO fails
            DateFormat inputFormat = DateFormat("dd/MM/yyyy HH:mm:ss", "en_US"); // Assuming English locale for parsing if applicable
             try {
                publishDateTime = inputFormat.parse(article.publishDate + " 00:00:00"); // Add time if only date
             } catch (e2) {
                print("Error parsing date for 'New' badge: ${article.publishDate} - $e2");
                return false; // Cannot determine if new
             }
        }
      } else {
        return false; // Unknown date type
      }

      // Consider "new" if published within the last 4 hours
      return DateTime.now().difference(publishDateTime).inHours <= 4;
    } catch (e) {
      print("Error processing date for 'New' badge: ${article.publishDate} - $e");
      return false; // If date parsing fails, assume not new
    }
  }

  @override
  Widget build(BuildContext context) {
    if (newsProvider.isLoadingMainStories && newsProvider.mainStories.isEmpty) {
      return _buildShimmerFeaturedCard(context);
    }
    if (newsProvider.mainStories.isEmpty) {
      return const SizedBox.shrink();
    }

    final mainStory = newsProvider.mainStories.first;
    final bool isArticleNew = _isNew(mainStory);

    // Get screen width for full-width design
    double screenWidth = MediaQuery.of(context).size.width;

    return Container(
      // Full width, remove horizontal margin if it was fixed like EdgeInsets.all(8)
      // Margin for top/bottom can remain if desired, or set to zero for true full bleed.
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      height: screenWidth * 0.75, // Example: 75% of screen width, adjust as needed
      child: GestureDetector(
        onTap: () => context.push('/news/${mainStory.cDate}/${mainStory.id}'),
        child: Card(
          margin: EdgeInsets.zero, // Card itself has no margin for full width
          clipBehavior: Clip.antiAlias,
          elevation: AppTheme.elevationSmall, // Can adjust elevation
          // No rounded corners for full-width banner typically, or very slight
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.zero, // No border radius for full width
          ),
          child: Stack(
            fit: StackFit.expand, // Make stack children fill the card
            children: [
              // Image
              CachedNetworkImage(
                imageUrl: mainStory.photoUrl,
                fit: BoxFit.cover, // Cover ensures the image fills the space
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
                    size: 60, // Slightly larger icon for error
                  ),
                ),
              ),
              // Scrim for text readability
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter, // Darker at the bottom
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withOpacity(0.8), // More opaque at bottom
                        Colors.black.withOpacity(0.5),
                        Colors.transparent, // Fades to transparent at top
                      ],
                      stops: const [0.0, 0.4, 0.8], // Adjust stops for gradient spread
                    ),
                  ),
                ),
              ),
              // Content (Text and Badge)
              Positioned(
                bottom: 16,
                left: 16, // Respect LTR/RTL via MediaQuery padding if needed
                right: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, // Align text to start (RTL aware)
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isArticleNew)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor, // Your app's accent color for badge
                          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                        ),
                        child: const Text(
                          'جديد', // "New" in Arabic
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontFamily: 'Cairo', // Your custom font
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    Text(
                      mainStory.title,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22, // Slightly larger font size for featured
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Cairo', // Your custom font
                        shadows: [ // Subtle shadow for better readability
                          Shadow(
                            blurRadius: 5.0,
                            color: Colors.black.withOpacity(0.7),
                            offset: const Offset(1, 1),
                          )
                        ],
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.start, // Ensures RTL/LTR text alignment
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerFeaturedCard(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      height: screenWidth * 0.75, // Match the actual card height
      child: Shimmer.fromColors(
        baseColor: AppTheme.dividerColor,
        highlightColor: AppTheme.surfaceVariant,
        child: Container(
          color: AppTheme.backgroundColor, // Shimmer background
        ),
      ),
    );
  }
}
