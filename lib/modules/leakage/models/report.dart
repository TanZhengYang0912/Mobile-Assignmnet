class ReportOutcome {
  static const fixed = 'fixed';
  static const notFixed = 'not_fixed';

  static String label(String outcome) {
    switch (outcome) {
      case fixed:
        return 'Fixed';
      case notFixed:
        return 'Not fixed';
      default:
        return outcome;
    }
  }
}

class Report {
  final int? id;
  final int alertId;
  final String workerName;
  final String findings;
  final String actionTaken;
  final String outcome;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDeleted;

  const Report({
    this.id,
    required this.alertId,
    required this.workerName,
    required this.findings,
    required this.actionTaken,
    required this.outcome,
    required this.createdAt,
    required this.updatedAt,
    this.isDeleted = false,
  });

  bool get isFixed => outcome == ReportOutcome.fixed;

  Map<String, Object?> toMap() => {
        'id': id,
        'alert_id': alertId,
        'worker_name': workerName,
        'findings': findings,
        'action_taken': actionTaken,
        'outcome': outcome,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
        'is_deleted': isDeleted ? 1 : 0,
      };

  factory Report.fromMap(Map<String, Object?> map) => Report(
        id: map['id'] as int?,
        alertId: map['alert_id'] as int,
        workerName: map['worker_name'] as String,
        findings: map['findings'] as String,
        actionTaken: map['action_taken'] as String,
        outcome: map['outcome'] as String,
        createdAt: DateTime.parse(map['created_at'] as String),
        updatedAt: DateTime.parse(map['updated_at'] as String),
        isDeleted: (map['is_deleted'] as int) == 1,
      );

  Report copyWith({
    int? id,
    String? findings,
    String? actionTaken,
    String? outcome,
    DateTime? updatedAt,
    bool? isDeleted,
  }) =>
      Report(
        id: id ?? this.id,
        alertId: alertId,
        workerName: workerName,
        findings: findings ?? this.findings,
        actionTaken: actionTaken ?? this.actionTaken,
        outcome: outcome ?? this.outcome,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        isDeleted: isDeleted ?? this.isDeleted,
      );
}
