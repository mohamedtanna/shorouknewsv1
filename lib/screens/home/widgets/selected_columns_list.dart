import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:shorouk_news/models/new_model.dart'; // For NewsArticle
// For ColumnModel - ensure this path is correct
import '../../../core/theme.dart';
import '../../../providers/news_provider.dart';
import './horizontal_news_card.dart'; // Import the HorizontalNewsCard

class SelectedColumnsList extends StatelessWidget {
  final NewsProvider newsProvider;

  const SelectedColumnsList({
    super.key,
    required this.newsProvider,
  });

  @override
  Widget build(BuildContext context) {
    if (newsProvider.isLoadingColumns && newsProvider.selectedColumns.isEmpty) {
      // Assuming _buildShimmerVerticalList is generic enough or create a specific one
      return _buildShimmerVerticalList(itemCount: 3); // Or a more appropriate count like 3
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
      itemCount: newsProvider.selectedColumns.length.clamp(0, 3), // As per original logic
      itemBuilder: (context, index) {
        final column = newsProvider.selectedColumns[index];
        // Adapt ColumnModel to NewsArticle for HorizontalNewsCard
        final article = NewsArticle(
          id: column.id,
          cDate: column.cDate,
          title: column.title,
          summary: column.summary,
          body: '', // Body might not be needed for card display
          photoUrl: column.columnistPhotoUrl, // Or a more relevant image if available
          thumbnailPhotoUrl: column.columnistPhotoUrl,
          sectionId: '', // Or map appropriately if needed
          sectionArName: column.columnistArName, // Used as a subtitle
          publishDate: column.creationDate,
          publishDateFormatted: column.creationDateFormattedDateTime,
          publishTimeFormatted: '', // Adjust if time is available and needed
          lastModificationDate: column.creationDate, // Or appropriate date
          lastModificationDateFormatted: column.creationDateFormattedDateTime,
          editorAndSource: column.columnistArName, // Display columnist name
          canonicalUrl: column.canonicalUrl,
          relatedPhotos: [], // Empty or map if available
          relatedNews: [],   // Empty or map if available
        );
        return HorizontalNewsCard(article: article, showDate: true, isColumn: true);
      },
    );
  }

  Widget _buildShimmerVerticalList({int itemCount = 3}) { // Defaulted to 3
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
