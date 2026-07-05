import 'package:flutter_test/flutter_test.dart';
import 'package:mysumber/modules/leakage/models/alert.dart';
import 'package:mysumber/modules/leakage/models/report.dart';

void main() {
  test('Alert toMap/fromMap round-trips is_deleted as a real boolean', () {
    final alert = Alert(
      alertType: AlertType.nrwHotspot,
      state: 'Perlis',
      detectedAt: DateTime(2026, 7, 5),
      signature: LeakSignature.nrwHotspot,
      severity: Severity.high,
      explanation: 'test',
      isDeleted: true,
    );
    final map = alert.toMap();
    expect(map['is_deleted'], isA<bool>());
    expect(map['is_deleted'], isTrue);
    final restored = Alert.fromMap(map);
    expect(restored.isDeleted, isTrue);
  });

  test('Report toMap/fromMap round-trips is_deleted as a real boolean', () {
    final report = Report(
      alertId: 1,
      workerName: 'Worker X',
      findings: 'findings',
      actionTaken: 'action',
      outcome: ReportOutcome.fixed,
      createdAt: DateTime(2026, 7, 5),
      updatedAt: DateTime(2026, 7, 5),
      isDeleted: true,
    );
    final map = report.toMap();
    expect(map['is_deleted'], isA<bool>());
    expect(map['is_deleted'], isTrue);
    final restored = Report.fromMap(map);
    expect(restored.isDeleted, isTrue);
  });
}
