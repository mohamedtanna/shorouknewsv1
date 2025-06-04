// For @required if using older Flutter versions, or for debugPrint

/// Represents a single opinion column or article.
///
/// This model includes details about the column's content, its author (columnist),
/// and publication dates.
class ColumnModel {
  final String id; // Unique identifier for the column
  final String cDate; // A date string, possibly used as part of a URL or key
  final String title; // The title of the column
  final String body; // The main HTML content of the column
  final String summary; // A brief summary or excerpt of the column
  final String columnistId; // Identifier for the columnist/author
  final String columnistArName; // Arabic name of the columnist
  final String columnistPhotoUrl; // URL for the columnist's photo
  final String creationDate; // Raw string representation of the creation date
  final String creationDateFormatted; // Formatted date string (e.g., "dd MMM yyyy")
  final String creationDateFormattedDateTime; // Formatted date and time string
  final String canonicalUrl; // The canonical web URL for this column

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

  /// Creates a [ColumnModel] instance from a JSON map.
  ///
  /// Handles potential null values from the JSON by providing default empty strings.
  factory ColumnModel.fromJson(Map<String, dynamic> json) {
    return ColumnModel(
      id: json['ID']?.toString() ?? '',
      cDate: json['CDate']?.toString() ?? '',
      title: json['Title'] as String? ?? '',
      body: json['Body'] as String? ?? '',
      summary: json['Summary'] as String? ?? '',
      columnistId: json['ColumnistID']?.toString() ?? '',
      columnistArName: json['ColumnistAr_Name'] as String? ?? '',
      columnistPhotoUrl: json['ColumnistPhotoUrl'] as String? ?? '',
      creationDate: json['CreationDate'] as String? ?? '',
      creationDateFormatted: json['CreationDate_FormattedDate'] as String? ?? '',
      creationDateFormattedDateTime: json['CreationDate_FormattedDateTime'] as String? ?? '',
      canonicalUrl: json['CanonicalUrl'] as String? ?? '',
    );
  }

  /// Converts this [ColumnModel] instance to a JSON map.
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

  // Optional: Add a copyWith method if you need to create modified copies of ColumnModel instances.
  ColumnModel copyWith({
    String? id,
    String? cDate,
    String? title,
    String? body,
    String? summary,
    String? columnistId,
    String? columnistArName,
    String? columnistPhotoUrl,
    String? creationDate,
    String? creationDateFormatted,
    String? creationDateFormattedDateTime,
    String? canonicalUrl,
  }) {
    return ColumnModel(
      id: id ?? this.id,
      cDate: cDate ?? this.cDate,
      title: title ?? this.title,
      body: body ?? this.body,
      summary: summary ?? this.summary,
      columnistId: columnistId ?? this.columnistId,
      columnistArName: columnistArName ?? this.columnistArName,
      columnistPhotoUrl: columnistPhotoUrl ?? this.columnistPhotoUrl,
      creationDate: creationDate ?? this.creationDate,
      creationDateFormatted: creationDateFormatted ?? this.creationDateFormatted,
      creationDateFormattedDateTime: creationDateFormattedDateTime ?? this.creationDateFormattedDateTime,
      canonicalUrl: canonicalUrl ?? this.canonicalUrl,
    );
  }

  // Optional: Add Equatable for value comparison if needed, or override == and hashCode.
  // @override
  // bool operator ==(Object other) =>
  //     identical(this, other) ||
  //     other is ColumnModel &&
  //         runtimeType == other.runtimeType &&
  //         id == other.id &&
  //         cDate == other.cDate &&
  //         title == other.title; // Compare other relevant fields

  // @override
  // int get hashCode => id.hashCode ^ cDate.hashCode ^ title.hashCode; // Combine hashes of relevant fields
}
