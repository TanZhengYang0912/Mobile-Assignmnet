class AiSummary {
  final int? id;
  final String summaryText;
  final List<String> pros;
  final List<String> cons;
  final int reviewCount;
  final DateTime generatedAt;

  const AiSummary({
    this.id,
    required this.summaryText,
    required this.pros,
    required this.cons,
    required this.reviewCount,
    required this.generatedAt,
  });

  factory AiSummary.fromMap(Map<String, dynamic> map) => AiSummary(
        id: map['id'] as int?,
        summaryText: map['summary_text'] as String,
        pros: List<String>.from(map['pros'] ?? []),
        cons: List<String>.from(map['cons'] ?? []),
        reviewCount: map['review_count'] as int,
        generatedAt: DateTime.parse(map['generated_at'] as String),
      );
}
