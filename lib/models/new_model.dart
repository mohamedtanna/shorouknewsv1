// For debugPrint, if needed

/// Represents a single news article with all its details.
class NewsArticle {
  final String id; // Unique ID of the news article
  final String cDate; // A specific date string, often part of API keys or URLs
  final String title; // Title of the article
  final String summary; // A short summary or lead paragraph
  final String body; // The main content of the article, typically HTML
  final String photoUrl; // URL for the main photo of the article
  final String thumbnailPhotoUrl; // URL for a smaller thumbnail version of the photo
  final String sectionId; // ID of the section this article belongs to
  final String sectionArName; // Arabic name of the section
  final String publishDate; // Raw string of the publication date
  final String publishDateFormatted; // User-friendly formatted publication date
  final String publishTimeFormatted; // User-friendly formatted publication time
  final String lastModificationDate; // Raw string of the last modification date
  final String lastModificationDateFormatted; // User-friendly formatted last modification date and time
  final String editorAndSource; // Information about the editor and/or source of the news
  final String canonicalUrl; // The canonical web URL for this article
  final List<RelatedPhoto> relatedPhotos; // List of photos related to the article
  final List<RelatedNews> relatedNews; // List of other news articles related to this one

  NewsArticle({
    required this.id,
    required this.cDate,
    required this.title,
    required this.summary,
    required this.body,
    required this.photoUrl,
    required this.thumbnailPhotoUrl,
    required this.sectionId,
    required this.sectionArName,
    required this.publishDate,
    required this.publishDateFormatted,
    required this.publishTimeFormatted,
    required this.lastModificationDate,
    required this.lastModificationDateFormatted,
    required this.editorAndSource,
    required this.canonicalUrl,
    required this.relatedPhotos,
    required this.relatedNews,
  });

  /// Creates a [NewsArticle] instance from a JSON map.
  factory NewsArticle.fromJson(Map<String, dynamic> json) {
    return NewsArticle(
      id: json['ID']?.toString() ?? '',
      cDate: json['CDate']?.toString() ?? '',
      title: json['Title'] as String? ?? '',
      summary: json['Summary'] as String? ?? '',
      body: json['Body'] as String? ?? '',
      photoUrl: json['PhotoUrl'] as String? ?? '',
      thumbnailPhotoUrl: json['ThumbnailPhotoUrl'] as String? ?? '',
      sectionId: json['SectionID']?.toString() ?? '',
      sectionArName: json['SectionAr_Name'] as String? ?? '',
      publishDate: json['PublishDate'] as String? ?? '',
      publishDateFormatted: json['PublishDate_FormattedDate'] as String? ?? '',
      publishTimeFormatted: json['PublishDate_FormattedTime'] as String? ?? '',
      lastModificationDate: json['LastModificationDate'] as String? ?? '',
      lastModificationDateFormatted: json['LastModificationDate_FormattedDateTime'] as String? ?? '',
      editorAndSource: json['EditorAndSource'] as String? ?? '',
      canonicalUrl: json['CanonicalUrl'] as String? ?? '',
      relatedPhotos: (json['RelatedPhotos'] as List<dynamic>?)
              ?.map((photoJson) => RelatedPhoto.fromJson(photoJson as Map<String, dynamic>))
              .toList() ??
          [],
      relatedNews: (json['RelatedNews'] as List<dynamic>?)
              ?.map((newsJson) => RelatedNews.fromJson(newsJson as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  /// Converts this [NewsArticle] instance to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'ID': id,
      'CDate': cDate,
      'Title': title,
      'Summary': summary,
      'Body': body,
      'PhotoUrl': photoUrl,
      'ThumbnailPhotoUrl': thumbnailPhotoUrl,
      'SectionID': sectionId,
      'SectionAr_Name': sectionArName,
      'PublishDate': publishDate,
      'PublishDate_FormattedDate': publishDateFormatted,
      'PublishDate_FormattedTime': publishTimeFormatted,
      'LastModificationDate': lastModificationDate,
      'LastModificationDate_FormattedDateTime': lastModificationDateFormatted,
      'EditorAndSource': editorAndSource,
      'CanonicalUrl': canonicalUrl,
      'RelatedPhotos': relatedPhotos.map((photo) => photo.toJson()).toList(),
      'RelatedNews': relatedNews.map((news) => news.toJson()).toList(),
    };
  }
}

/// Represents a photo related to a news article.
class RelatedPhoto {
  final String photoUrl; // URL for the full-size photo
  final String thumbnailPhotoUrl; // URL for the thumbnail of the photo
  final String photoCaption; // Caption for the photo

  RelatedPhoto({
    required this.photoUrl,
    required this.thumbnailPhotoUrl,
    required this.photoCaption,
  });

  /// Creates a [RelatedPhoto] instance from a JSON map.
  factory RelatedPhoto.fromJson(Map<String, dynamic> json) {
    return RelatedPhoto(
      photoUrl: json['PhotoUrl'] as String? ?? '',
      thumbnailPhotoUrl: json['ThumbnailPhotoUrl'] as String? ?? '',
      photoCaption: json['PhotoCaption'] as String? ?? '',
    );
  }

  /// Converts this [RelatedPhoto] instance to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'PhotoUrl': photoUrl,
      'ThumbnailPhotoUrl': thumbnailPhotoUrl,
      'PhotoCaption': photoCaption,
    };
  }
}

/// Represents a news article that is related to another news article.
class RelatedNews {
  final String id; // Unique ID of the related news article
  final String cDate; // A specific date string for the related article
  final String title; // Title of the related news article
  final String thumbnailPhotoUrl; // Thumbnail URL for the related news article

  RelatedNews({
    required this.id,
    required this.cDate,
    required this.title,
    required this.thumbnailPhotoUrl,
  });

  /// Creates a [RelatedNews] instance from a JSON map.
  factory RelatedNews.fromJson(Map<String, dynamic> json) {
    return RelatedNews(
      id: json['ID']?.toString() ?? '',
      cDate: json['CDate']?.toString() ?? '',
      title: json['Title'] as String? ?? '',
      thumbnailPhotoUrl: json['ThumbnailPhotoUrl'] as String? ?? '',
    );
  }

  /// Converts this [RelatedNews] instance to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'ID': id,
      'CDate': cDate,
      'Title': title,
      'ThumbnailPhotoUrl': thumbnailPhotoUrl,
    };
  }
}

/// Represents a news section or category.
class NewsSection {
  final String id; // Unique ID of the news section
  final String arName; // Arabic name of the section
  final String enName; // English name of the section (if available)

  NewsSection({
    required this.id,
    required this.arName,
    required this.enName,
  });

  /// Creates a [NewsSection] instance from a JSON map.
  factory NewsSection.fromJson(Map<String, dynamic> json) {
    return NewsSection(
      id: json['ID']?.toString() ?? '',
      arName: json['Ar_Name'] as String? ?? '',
      enName: json['En_Name'] as String? ?? '',
    );
  }

  /// Converts this [NewsSection] instance to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'ID': id,
      'Ar_Name': arName,
      'En_Name': enName,
    };
  }
}
