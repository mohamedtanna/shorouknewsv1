import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:shorouk_news/models/new_model.dart';
import '../../../core/theme.dart';

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
        margin: const EdgeInsets.symmetric(vertical: 4),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image
              ClipRRect(
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                child: CachedNetworkImage(
                  imageUrl: article.thumbnailPhotoUrl.isNotEmpty
                      ? article.thumbnailPhotoUrl
                      : article.photoUrl,
                  width: 100,
                  height: 80,
                  fit: BoxFit.cover,
                  filterQuality: FilterQuality.high,
                  placeholder: (context, url) => Container(
                    width: 100,
                    height: 80,
                    color: Colors.grey[300],
                    child: const Icon(Icons.image, color: Colors.grey),
                  ),
                  errorWidget: (context, url, error) => Container(
                    width: 100,
                    height: 80,
                    color: Colors.grey[300],
                    child: const Icon(Icons.error, color: Colors.grey),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      article.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimaryColor,
                        fontFamily: 'Cairo',
                        height: 1.3,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (showDate) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            article.lastModificationDateFormatted.isNotEmpty
                                ? article.lastModificationDateFormatted
                                : article.publishDateFormatted.isNotEmpty
                                    ? article.publishTimeFormatted.isNotEmpty
                                        ? '${article.publishDateFormatted} - ${article.publishTimeFormatted}'
                                        : article.publishDateFormatted
                                    : 'منذ قليل',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontFamily: 'Cairo',
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (isColumn && article.editorAndSource.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        article.editorAndSource,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Cairo',
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
}
