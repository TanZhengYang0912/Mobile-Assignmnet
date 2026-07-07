class ServiceReview {
  final int? id;
  final int? alertId;
  final String consumerEmail;
  final int stars;
  final List<String> tags;
  final String comment;
  final DateTime createdAt;

  const ServiceReview({
    this.id,
    this.alertId,
    required this.consumerEmail,
    required this.stars,
    this.tags = const [],
    this.comment = '',
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'alert_id': alertId,
        'consumer_email': consumerEmail,
        'stars': stars,
        'tags': tags,
        'comment': comment,
        'created_at': createdAt.toIso8601String(),
      };

  factory ServiceReview.fromMap(Map<String, dynamic> map) => ServiceReview(
        id: map['id'] as int?,
        alertId: map['alert_id'] as int?,
        consumerEmail: map['consumer_email'] as String,
        stars: map['stars'] as int,
        tags: List<String>.from(map['tags'] ?? []),
        comment: map['comment'] as String? ?? '',
        createdAt: DateTime.parse(map['created_at'] as String),
      );
}
