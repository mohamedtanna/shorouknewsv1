import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:shorouk_news/models/new_model.dart';
import '../../../core/theme.dart';
import 'package:shimmer/shimmer.dart'; // Import Shimmer for placeholder

class HorizontalNewsCard extends StatelessWidget {
  final NewsArticle article;
  final bool showDate;
  final bool isColumn;

  const HorizontalNewsCard({
    super.key,
    required this.article,
    this.showDate = true,
    this.isColumn = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(isColumn
          ? '/column/${article.cDate}/${article.id}'
          : '/news/${article.cDate}/${article.id}'),
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 6), // Removed horizontal margin
        clipBehavior: Clip.antiAlias,
        elevation: AppTheme.elevationSmall,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusDefault),
        ),
        child: Column( // Changed from Row to Column
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with AspectRatio
            AspectRatio(
              aspectRatio: 16 / 9,
              child: CachedNetworkImage(
                imageUrl: article.thumbnailPhotoUrl.isNotEmpty
                    ? article.thumbnailPhotoUrl
                    : article.photoUrl,
                fit: BoxFit.cover,
                filterQuality: FilterQuality.high,
                placeholder: (context, url) => Shimmer.fromColors( // Consistent shimmer
                  baseColor: AppTheme.dividerColor,
                  highlightColor: AppTheme.surfaceVariant,
                  child: Container(color: AppTheme.backgroundColor),
                ),
                errorWidget: (context, url, error) => Container(
                  color: AppTheme.surfaceVariant, // Consistent error display
                  child: const Icon(Icons.broken_image_outlined, color: AppTheme.textDisabledColor, size: 40),
                ),
              ),
            ),
            // Content Area
            Padding(
              padding: const EdgeInsets.all(12.0), // Uniform padding
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    article.title,
                    style: const TextStyle(
                      fontSize: 17, // Slightly larger for list items
                      fontWeight: FontWeight.bold, // Bold title
                      color: AppTheme.textPrimaryColor,
                      fontFamily: 'Cairo',
                      height: 1.3,
                    ),
                    maxLines: 2, // Limit to 2 lines
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.start, // For RTL
                  ),
                  const SizedBox(height: 8), // Spacing
                  // Row for date and columnist (if applicable)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (showDate)
                        Expanded( // Expanded to allow date to take available space before columnist
                          child: Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 15, // Slightly smaller icon
                                color: AppTheme.textSecondaryColor,
                              ),
                              const SizedBox(width: 4),
                              Flexible( // Flexible for long dates
                                child: Text(
                                  article.lastModificationDateFormatted.isNotEmpty
                                      ? article.lastModificationDateFormatted
                                      : article.publishDateFormatted.isNotEmpty
                                          ? article.publishTimeFormatted.isNotEmpty
                                              ? '${article.publishDateFormatted} - ${article.publishTimeFormatted}'
                                              : article.publishDateFormatted
                                          : 'منذ قليل',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textSecondaryColor,
                                    fontFamily: 'Cairo',
                                  ),
                                  overflow: TextOverflow.ellipsis, // Handle long dates
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (isColumn && article.editorAndSource.isNotEmpty)
                        Flexible( // Flexible for columnist name
                          child: Text(
                            article.editorAndSource,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.primaryColor, // Use theme's primary color for emphasis
                              fontWeight: FontWeight.w600, // Slightly bolder
                              fontFamily: 'Cairo',
                            ),
                            textAlign: TextAlign.end, // Align to end for RTL
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
