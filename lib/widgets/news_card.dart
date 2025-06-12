import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_html/flutter_html.dart';

import 'package:shorouk_news/models/new_model.dart';
import '../core/theme.dart';

class NewsCard extends StatelessWidget {
  final NewsArticle article;
  final VoidCallback? onTap;
  final bool isHorizontal;
  final bool showDate;

  const NewsCard({
    super.key,
    required this.article,
    this.onTap,
    this.isHorizontal = false,
    this.showDate = true,
  });

  @override
  Widget build(BuildContext context) {
    if (isHorizontal) {
      return _buildHorizontalCard(context);
    }
    return _buildVerticalCard(context);
  }

  // Horizontal card matching screenshots layout - text on left, image on right
  Widget _buildHorizontalCard(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            bottom: BorderSide(color: AppTheme.dividerColor, width: 1),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Text content on left (RTL layout)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Html(
                    data: article.title,
                    style: {
                      "body": Style(
                        margin: Margins.zero,
                        padding: HtmlPaddings.zero,
                        fontSize: FontSize(16),
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Tajawal',
                        color: AppTheme.textPrimaryColor,
                        maxLines: 3,
                        lineHeight: const LineHeight(1.3),
                      ),
                    },
                  ),

                  if (showDate) ...[
                    const SizedBox(height: 8),
                    // Date with calendar icon like in screenshots
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today,
                          size: 14,
                          color: AppTheme.textSecondaryColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          article.publishDateFormatted.isNotEmpty
                              ? article.publishDateFormatted
                              : 'منذ قليل',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondaryColor,
                            fontFamily: 'Tajawal',
                          ),
                        ),
                      ],
                    ),
                  ],

                  // Author/Source for columns
                  if (article.editorAndSource.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      article.editorAndSource,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Tajawal',
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Image on right (RTL layout)
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: CachedNetworkImage(
                imageUrl: article.thumbnailPhotoUrl.isNotEmpty
                    ? article.thumbnailPhotoUrl
                    : article.photoUrl,
                width: 100,
                height: 80,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  width: 100,
                  height: 80,
                  color: AppTheme.surfaceVariant,
                  child: const Icon(
                    Icons.image,
                    color: AppTheme.textDisabledColor,
                    size: 24,
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  width: 100,
                  height: 80,
                  color: AppTheme.surfaceVariant,
                  child: const Icon(
                    Icons.error,
                    color: AppTheme.textDisabledColor,
                    size: 24,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Vertical card for grid layout
  Widget _buildVerticalCard(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(2),
      clipBehavior: Clip.antiAlias,
      elevation: 2.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image taking most space
            Expanded(
              flex: 7,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: article.photoUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: AppTheme.surfaceVariant,
                      child: const Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: AppTheme.surfaceVariant,
                      child: const Icon(
                        Icons.error,
                        color: AppTheme.textDisabledColor,
                        size: 20,
                      ),
                    ),
                  ),
                  // Gradient overlay for better text readability
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.1),
                          Colors.black.withOpacity(0.6),
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Title section - compact
            Expanded(
              flex: 3,
              child: Container(
                padding: const EdgeInsets.all(8),
                child: Html(
                  data: article.title,
                  style: {
                    "body": Style(
                      margin: Margins.zero,
                      padding: HtmlPaddings.zero,
                      fontSize: FontSize(14),
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimaryColor,
                      maxLines: 3,
                      textOverflow: TextOverflow.ellipsis,
                      lineHeight: const LineHeight(1.2),
                      fontFamily: 'Tajawal',
                    ),
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
