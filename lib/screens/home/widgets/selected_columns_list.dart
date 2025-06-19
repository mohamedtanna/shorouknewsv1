import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:shorouk_news/models/new_model.dart';
import 'package:shorouk_news/models/column_model.dart';
import '../../../core/theme.dart';
import '../../../providers/news_provider.dart';
import './horizontal_news_card.dart';

class SelectedColumnsList extends StatelessWidget {
  final NewsProvider newsProvider;

  const SelectedColumnsList({
    super.key,
    required this.newsProvider,
  });

  @override
  Widget build(BuildContext context) {
    if (newsProvider.isLoadingColumns && newsProvider.selectedColumns.isEmpty) {
      return _buildShimmerVerticalList(itemCount: 3);
    }
    if (newsProvider.selectedColumns.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Center(
          child: Text(
            'لا توجد مقالات مختارة حالياً.',
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
      itemCount: newsProvider.selectedColumns.length.clamp(0, 3),
      itemBuilder: (context, index) {
        final column = newsProvider.selectedColumns[index];
        final article = NewsArticle(
          id: column.id,
          cDate: column.cDate,
          title: column.title,
          summary: column.summary,
          body: '',
          photoUrl: column.columnistPhotoUrl,
          thumbnailPhotoUrl: column.columnistPhotoUrl,
          sectionId: '',
          sectionArName: column.columnistArName,
          publishDate: column.creationDate,
          publishDateFormatted: column.creationDateFormattedDateTime,
          publishTimeFormatted: '',
          lastModificationDate: column.creationDate,
          lastModificationDateFormatted: column.creationDateFormattedDateTime,
          editorAndSource: column.columnistArName,
          canonicalUrl: column.canonicalUrl,
          relatedPhotos: [],
          relatedNews: [],
        );
        return HorizontalNewsCard(article: article, showDate: true, isColumn: true);
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
