// Video Model
class VideoModel {
  final String id;
  final String title;
  final String description;
  final String thumbUrl;
  final String publishDate;
  final String publishDateFormatted;
  final String canonicalUrl;

  VideoModel({
    required this.id,
    required this.title,
    required this.description,
    required this.thumbUrl,
    required this.publishDate,
    required this.publishDateFormatted,
    required this.canonicalUrl,
  });

  factory VideoModel.fromJson(Map<String, dynamic> json) {
    return VideoModel(
      id: json['ID']?.toString() ?? '',
      title: json['Title'] ?? '',
      description: json['Description'] ?? '',
      thumbUrl: json['ThumbUrl'] ?? '',
      publishDate: json['PublishDate'] ?? '',
      publishDateFormatted: json['PublishDate_FormattedDate'] ?? '',
      canonicalUrl: json['CanonicalUrl'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ID': id,
      'Title': title,
      'Description': description,
      'ThumbUrl': thumbUrl,
      'PublishDate': publishDate,
      'PublishDate_FormattedDate': publishDateFormatted,
      'CanonicalUrl': canonicalUrl,
    };
  }
}

// Column Model
class ColumnModel {
  final String id;
  final String cDate;
  final String title;
  final String body;
  final String summary;
  final String columnistId;
  final String columnistArName;
  final String columnistPhotoUrl;
  final String creationDate;
  final String creationDateFormatted;
  final String creationDateFormattedDateTime;
  final String canonicalUrl;

  ColumnModel({
    required this.id,
    required this.cDate,
    required this.title,
    required this.body,
    required this.summary,
    required this.columnistId,
    required this.columnistArName,
    required this.columnistPhotoUrl,
    required this.creationDate,
    required this.creationDateFormatted,
    required this.creationDateFormattedDateTime,
    required this.canonicalUrl,
  });

  factory ColumnModel.fromJson(Map<String, dynamic> json) {
    return ColumnModel(
      id: json['ID']?.toString() ?? '',
      cDate: json['CDate']?.toString() ?? '',
      title: json['Title'] ?? '',
      body: json['Body'] ?? '',
      summary: json['Summary'] ?? '',
      columnistId: json['ColumnistID']?.toString() ?? '',
      columnistArName: json['ColumnistAr_Name'] ?? '',
      columnistPhotoUrl: json['ColumnistPhotoUrl'] ?? '',
      creationDate: json['CreationDate'] ?? '',
      creationDateFormatted: json['CreationDate_FormattedDate'] ?? '',
      creationDateFormattedDateTime: json['CreationDate_FormattedDateTime'] ?? '',
      canonicalUrl: json['CanonicalUrl'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ID': id,
      'CDate': cDate,
      'Title': title,
      'Body': body,
      'Summary': summary,
      'ColumnistID': columnistId,
      'ColumnistAr_Name': columnistArName,
      'ColumnistPhotoUrl': columnistPhotoUrl,
      'CreationDate': creationDate,
      'CreationDate_FormattedDate': creationDateFormatted,
      'CreationDate_FormattedDateTime': creationDateFormattedDateTime,
      'CanonicalUrl': canonicalUrl,
    };
  }
}

// Author Model
class AuthorModel {
  final String id;
  final String arName;
  final String enName;
  final String description;
  final String photoUrl;

  AuthorModel({
    required this.id,
    required this.arName,
    required this.enName,
    required this.description,
    required this.photoUrl,
  });

  factory AuthorModel.fromJson(Map<String, dynamic> json) {
    return AuthorModel(
      id: json['ID']?.toString() ?? '',
      arName: json['Ar_Name'] ?? '',
      enName: json['En_Name'] ?? '',
      description: json['Description'] ?? '',
      photoUrl: json['PhotoUrl'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ID': id,
      'Ar_Name': arName,
      'En_Name': enName,
      'Description': description,
      'PhotoUrl': photoUrl,
    };
  }
}

// Settings Model
class NotificationSettings {
  final Map<String, bool> sections;

  NotificationSettings({required this.sections});

  factory NotificationSettings.fromJson(Map<String, dynamic> json) {
    return NotificationSettings(
      sections: Map<String, bool>.from(json['sections'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sections': sections,
    };
  }

  NotificationSettings copyWith({Map<String, bool>? sections}) {
    return NotificationSettings(
      sections: sections ?? this.sections,
    );
  }
}

// Newsletter Subscription Status
enum SubscriptionStatus {
  success(1),
  mailNotApproved(2),
  failGeneral(10),
  failMailExists(11);

  const SubscriptionStatus(this.value);
  final int value;

  static SubscriptionStatus fromValue(int value) {
    return SubscriptionStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => SubscriptionStatus.failGeneral,
    );
  }

  String get message {
    switch (this) {
      case SubscriptionStatus.success:
        return 'شكرا لك، سيصلك بريد إليكتروني للتأكيد';
      case SubscriptionStatus.mailNotApproved:
        return 'هذا البريد يحتاج إلى التأكيد، برجاء فحص بريدك الإليكتروني الآن للتأكيد';
      case SubscriptionStatus.failGeneral:
        return 'حدث خطأ، برجاء المحاولة لاحقا';
      case SubscriptionStatus.failMailExists:
        return 'هذا البريد الإليكتروني مسجل بالفعل';
    }
  }
}