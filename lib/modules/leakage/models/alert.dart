class AlertStatus {
  static const pending = 'pending';
  static const investigating = 'investigating';
  static const resolved = 'resolved';
  static const notFixed = 'not_fixed';
  static const dismissed = 'dismissed';

  static const all = [pending, investigating, resolved, notFixed, dismissed];
  static const unresolved = [pending, investigating, notFixed];

  static String label(String status) {
    switch (status) {
      case pending:
        return 'Pending';
      case investigating:
        return 'Investigating';
      case resolved:
        return 'Resolved';
      case notFixed:
        return 'Not fixed';
      case dismissed:
        return 'Dismissed';
      default:
        return status;
    }
  }
}

class AlertType {
  static const nrwHotspot = 'nrw_hotspot';
  static const household = 'household';
}

class LeakSignature {
  static const continuousLeak = 'Continuous leak';
  static const suddenBurst = 'Sudden burst';
  static const creepingLeak = 'Creeping leak';
  static const seasonalSpike = 'Seasonal spike';
  static const nrwHotspot = 'NRW hotspot';
}

class Severity {
  static const low = 'low';
  static const medium = 'medium';
  static const high = 'high';

  static String label(String severity) {
    switch (severity) {
      case high:
        return 'High severity';
      case medium:
        return 'Medium severity';
      case low:
        return 'Low severity';
      default:
        return severity;
    }
  }
}

class Alert {
  final int? id;
  final int? readingId;
  final String alertType;
  final String? householdId;
  final String state;
  final DateTime detectedAt;
  final String signature;
  final String severity;
  final double baselineL;
  final double actualL;
  final String explanation;
  final String status;
  final bool isDeleted;
  final double? producedMld;
  final double? billedMld;
  final double? lossMld;
  final double? lossPct;
  final int? dataYear;

  const Alert({
    this.id,
    this.readingId,
    required this.alertType,
    this.householdId,
    required this.state,
    required this.detectedAt,
    required this.signature,
    required this.severity,
    this.baselineL = 0,
    this.actualL = 0,
    required this.explanation,
    this.status = AlertStatus.pending,
    this.isDeleted = false,
    this.producedMld,
    this.billedMld,
    this.lossMld,
    this.lossPct,
    this.dataYear,
  });

  bool get isNrw => alertType == AlertType.nrwHotspot;
  double get ratio => baselineL == 0 ? 0 : actualL / baselineL;
  bool get isUnresolved => AlertStatus.unresolved.contains(status);

  String get title => isNrw ? state : '$state · ${householdId ?? ''}';

  Map<String, Object?> toMap() => {
        'id': id,
        'reading_id': readingId,
        'alert_type': alertType,
        'household_id': householdId,
        'state': state,
        'detected_at': detectedAt.toIso8601String(),
        'signature': signature,
        'severity': severity,
        'baseline_l': baselineL,
        'actual_l': actualL,
        'explanation': explanation,
        'status': status,
        'is_deleted': isDeleted ? 1 : 0,
        'produced_mld': producedMld,
        'billed_mld': billedMld,
        'loss_mld': lossMld,
        'loss_pct': lossPct,
        'data_year': dataYear,
      };

  factory Alert.fromMap(Map<String, Object?> map) => Alert(
        id: map['id'] as int?,
        readingId: map['reading_id'] as int?,
        alertType: map['alert_type'] as String,
        householdId: map['household_id'] as String?,
        state: map['state'] as String,
        detectedAt: DateTime.parse(map['detected_at'] as String),
        signature: map['signature'] as String,
        severity: map['severity'] as String,
        baselineL: (map['baseline_l'] as num?)?.toDouble() ?? 0,
        actualL: (map['actual_l'] as num?)?.toDouble() ?? 0,
        explanation: map['explanation'] as String,
        status: map['status'] as String,
        isDeleted: (map['is_deleted'] as int) == 1,
        producedMld: (map['produced_mld'] as num?)?.toDouble(),
        billedMld: (map['billed_mld'] as num?)?.toDouble(),
        lossMld: (map['loss_mld'] as num?)?.toDouble(),
        lossPct: (map['loss_pct'] as num?)?.toDouble(),
        dataYear: map['data_year'] as int?,
      );

  Alert copyWith({int? id, String? status, bool? isDeleted}) => Alert(
        id: id ?? this.id,
        readingId: readingId,
        alertType: alertType,
        householdId: householdId,
        state: state,
        detectedAt: detectedAt,
        signature: signature,
        severity: severity,
        baselineL: baselineL,
        actualL: actualL,
        explanation: explanation,
        status: status ?? this.status,
        isDeleted: isDeleted ?? this.isDeleted,
        producedMld: producedMld,
        billedMld: billedMld,
        lossMld: lossMld,
        lossPct: lossPct,
        dataYear: dataYear,
      );
}
