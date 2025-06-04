class NewsArticle {
  final String id;
  final String cDate;
  final String title;
  final String summary;
  final String body;
  final String photoUrl;
  final String thumbnailPhotoUrl;
  final String sectionId;
  final String sectionArName;
  final String publishDate;
  final String publishDateFormatted;
  final String publishTimeFormatted;
  final String lastModificationDate;
  final String lastModificationDateFormatted;
  final String editorAndSource;
  final String canonicalUrl;
  final List<RelatedPhoto> relatedPhotos;
  final List<RelatedNews> relatedNews;

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

  factory NewsArticle.fromJson(Map<String, dynamic> json) {
    return NewsArticle(
      id: json['ID']?.toString() ?? '',
      cDate: json['CDate']?.toString() ?? '',
      title: json['Title'] ?? '',
      summary: json['Summary'] ?? '',
      body: json['Body'] ?? '',
      photoUrl: json['PhotoUrl'] ?? '',
      thumbnailPhotoUrl: json['ThumbnailPhotoUrl'] ?? '',
      sectionId: json['SectionID']?.toString() ?? '',
      sectionArName: json['SectionAr_Name'] ?? '',
      publishDate: json['PublishDate'] ?? '',
      publishDateFormatted: json['PublishDate_FormattedDate'] ?? '',
      publishTimeFormatted: json['PublishDate_FormattedTime'] ?? '',
      lastModificationDate: json['LastModificationDate'] ?? '',
      lastModificationDateFormatted: json['LastModificationDate_FormattedDateTime'] ?? '',
      editorAndSource: json['EditorAndSource'] ?? '',
      canonicalUrl: json['CanonicalUrl'] ?? '',
      relatedPhotos: (json['RelatedPhotos'] as List<dynamic>?)
          ?.map((photo) => RelatedPhoto.fromJson(photo))
          .toList() ?? [],
      relatedNews: (json['RelatedNews'] as List<dynamic>?)
          ?.map((news) => RelatedNews.fromJson(news))
          .toList() ?? [],
    );
  }

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

class RelatedPhoto {
  final String photoUrl;
  final String thumbnailPhotoUrl;
  final String photoCaption;

  RelatedPhoto({
    required this.photoUrl,
    required this.thumbnailPhotoUrl,
    required this.photoCaption,
  });

  factory RelatedPhoto.fromJson(Map<String, dynamic> json) {
    return RelatedPhoto(
      photoUrl: json['PhotoUrl'] ?? '',
      thumbnailPhotoUrl: json['ThumbnailPhotoUrl'] ?? '',
      photoCaption: json['PhotoCaption'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'PhotoUrl': photoUrl,
      'ThumbnailPhotoUrl': thumbnailPhotoUrl,
      'PhotoCaption': photoCaption,
    };
  }
}

class RelatedNews {
  final String id;
  final String cDate;
  final String title;
  final String thumbnailPhotoUrl;

  RelatedNews({
    required this.id,
    required this.cDate,
    required this.title,
    required this.thumbnailPhotoUrl,
  });

  factory RelatedNews.fromJson(Map<String, dynamic> json) {
    return RelatedNews(
      id: json['ID']?.toString() ?? '',
      cDate: json['CDate']?.toString() ?? '',
      title: json['Title'] ?? '',
      thumbnailPhotoUrl: json['ThumbnailPhotoUrl'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ID': id,
      'CDate': cDate,
      'Title': title,
      'ThumbnailPhotoUrl': thumbnailPhotoUrl,
    };
  }
}

class NewsSection {
  final String id;
  final String arName;
  final String enName;

  NewsSection({
    required this.id,
    required this.arName,
    required this.enName,
  });

  factory NewsSection.fromJson(Map<String, dynamic> json) {
    return NewsSection(
      id: json['ID']?.toString() ?? '',
      arName: json['Ar_Name'] ?? '',
      enName: json['En_Name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ID': id,
      'Ar_Name': arName,
      'En_Name': enName,
    };
  }
}