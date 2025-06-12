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

  Widget _buildHorizontalCard(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(
          horizontal: 8, vertical: 3), // Reduced margins
      elevation: 2.0, // Reduced elevation
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(10), // Reduced padding
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image - Slightly smaller
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: CachedNetworkImage(
                  imageUrl: article.thumbnailPhotoUrl.isNotEmpty
                      ? article.thumbnailPhotoUrl
                      : article.photoUrl,
                  width: 85, // Reduced from 100
                  height: 70, // Reduced from 80
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    width: 85,
                    height: 70,
                    color: Colors.grey[300],
                    child:
                        const Icon(Icons.image, color: Colors.grey, size: 24),
                  ),
                  errorWidget: (context, url, error) => Container(
                    width: 85,
                    height: 70,
                    color: Colors.grey[300],
                    child:
                        const Icon(Icons.error, color: Colors.grey, size: 24),
                  ),
                ),
              ),

              const SizedBox(width: 10), // Reduced spacing

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min, // Important for tight layout
                  children: [
                    // Title - More compact
                    Html(
                      data: article.title,
                      style: {
                        "body": Style(
                          margin: Margins.zero,
                          padding: HtmlPaddings.zero,
                          fontSize: FontSize(13), // Slightly smaller
                          fontWeight: FontWeight.w600, // Less bold
                          fontFamily: 'Tajawal',
                          color: AppTheme.primaryColor,
                          maxLines: 3, // Reduced from 3
                          //textOverflow: TextOverflow.ellipsis,
                          lineHeight:
                              const LineHeight(1.2), // Tighter line height
                        ),
                      },
                    ),

                    if (showDate) ...[
                      const SizedBox(height: 6), // Reduced spacing
                      // Date - More compact
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2), // Smaller padding
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 10, // Smaller icon
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 3),
                            Text(
                              article.publishDateFormatted.isNotEmpty
                                  ? article.publishDateFormatted
                                  : 'منذ قليل',
                              style: TextStyle(
                                fontSize: 10, // Smaller font
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVerticalCard(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(2), // Even tighter margins
      clipBehavior: Clip.antiAlias,
      elevation: 2.0,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image - Taking most of the space
            Expanded(
              flex: 7, // Image takes 70% of the card space
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: article.photoUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: Colors.grey[300],
                      child: const Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.error, size: 20),
                    ),
                  ),
                  // Gradient overlay for text readability
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.6),
                        ],
                        stops: const [0.4, 1.0],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Title section - Taking minimal space
            Expanded(
              flex: 3, // Title takes 30% of the card space
              child: Container(
                padding: const EdgeInsets.all(6),
                child: Html(
                  data: article.title,
                  style: {
                    "body": Style(
                      margin: Margins.zero,
                      padding: HtmlPaddings.zero,
                      fontSize: FontSize(14),
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                      maxLines: 3,
                      textOverflow: TextOverflow.ellipsis,
                      lineHeight: LineHeight(1.1),
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
