import 'package:flutter_test/flutter_test.dart';
import 'package:mysumber/modules/leakage/models/alert.dart';
import 'package:mysumber/modules/leakage/models/reading.dart';
import 'package:mysumber/modules/leakage/services/detection_engine.dart';

const double baseline = 1000;

Reading _reading(double total, double night) => Reading(
      householdId: 'H-001',
      state: 'Selangor',
      householdSize: 4,
      readingDate: DateTime(2026, 1, 1),
      dayFlowL: total - night,
      nightFlowL: night,
      scenario: 'test',
    );

List<Reading> _flat(double total, double night, {int days = 7}) =>
    List.generate(days, (_) => _reading(total, night));

void main() {
  final engine = DetectionEngine();

  test('normal usage raises no anomaly', () {
    final result = engine.evaluate(_flat(1000, 80), baseline);
    expect(result.isAnomaly, isFalse);
  });

  test('sudden burst is detected as high severity', () {
    final series = _flat(1000, 80, days: 6)..add(_reading(3600, 80));
    final result = engine.evaluate(series, baseline);
    expect(result.signature, LeakSignature.suddenBurst);
    expect(result.severity, Severity.high);
  });

  test('continuous leak needs sustained high usage and high night flow', () {
    final result = engine.evaluate(_flat(2200, 450), baseline);
    expect(result.signature, LeakSignature.continuousLeak);
    expect(result.nightFlowElevated, isTrue);
  });

  test('creeping leak is detected from a rising trend', () {
    final series =
        List.generate(7, (i) => _reading(1000 + i * 120, 80));
    final result = engine.evaluate(series, baseline);
    expect(result.signature, LeakSignature.creepingLeak);
    expect(result.severity, Severity.medium);
  });

  test('flat moderate elevation is treated as a seasonal spike', () {
    final result = engine.evaluate(_flat(1600, 80), baseline);
    expect(result.signature, LeakSignature.seasonalSpike);
    expect(result.severity, Severity.low);
  });
}
