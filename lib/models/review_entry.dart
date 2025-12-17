class ReviewEntry {
  final int pk;
  final ReviewFields fields;

  ReviewEntry({
    required this.pk,
    required this.fields,
  });

  factory ReviewEntry.fromJson(Map<String, dynamic> json) {
    return ReviewEntry(
      pk: json['pk'],
      fields: ReviewFields.fromJson(json['fields']),
    );
  }
}

class ReviewFields {
  final int rating;
  final String comment;
  final String targetType;
  final String targetName;
  final DateTime createdAt;
  final DateTime updatedAt;

  ReviewFields({
    required this.rating,
    required this.comment,
    required this.targetType,
    required this.targetName,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ReviewFields.fromJson(Map<String, dynamic> json) {
    return ReviewFields(
      rating: json['rating'] ?? 0,
      comment: json['comment'] ?? '',
      targetType: json['target_type'] ?? '',
      targetName: json['target_name'] ?? '',
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
    );
  }
}
