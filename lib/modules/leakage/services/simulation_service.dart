import 'dart:math';

import '../data/leakage_repository.dart';
import '../models/alert.dart';
import '../models/reading.dart';
import 'baseline_service.dart';
import 'detection_engine.dart';
import 'explainer.dart';

enum LeakScenario {
  continuousLeak('Continuous leak'),
  suddenBurst('Sudden burst'),
  creepingLeak('Creeping leak'),
  seasonalSpike('Seasonal spike'),
  normalUsage('Normal usage');

  final String label;
  const LeakScenario(this.label);
}

class SimulationOutcome {
  final Reading latestReading;
  final DetectionResult result;
  final Alert? alert;

  const SimulationOutcome({
    required this.latestReading,
    required this.result,
    this.alert,
  });

  bool get anomalyRaised => alert != null;
}

class SimulationService {
  final BaselineService baseline;
  final LeakageRepository repository;
  final DetectionEngine _engine;
  final Explainer _explainer;
  final Random _random;

  SimulationService({
    required this.baseline,
    required this.repository,
    DetectionEngine? engine,
    Explainer? explainer,
    Random? random,
  })  : _engine = engine ?? DetectionEngine(),
        _explainer = explainer ?? Explainer(),
        _random = random ?? Random();

  static const int _windowDays = 7;
  static const double _normalNightShare = 0.08;

  Future<SimulationOutcome> run(LeakScenario scenario, String state) async {
    final householdSize = 4;
    final householdId = 'H-${_random.nextInt(900) + 100}';
    final expected = baseline.expectedHouseholdLPerDay(state, householdSize);

    final series =
        _buildSeries(scenario, state, householdId, householdSize, expected);
    final result = _engine.evaluate(series, expected);

    final latest = series.last;
    final readingId = await repository.insertReading(latest);
    final stored = latest.copyWith(id: readingId);

    Alert? alert;
    if (result.isAnomaly) {
      final draft = Alert(
        readingId: readingId,
        alertType: AlertType.household,
        householdId: householdId,
        state: state,
        detectedAt: DateTime.now(),
        signature: result.signature,
        severity: result.severity,
        baselineL: result.baselineL,
        actualL: result.actualL,
        explanation: _explainer.describe(stored, result),
      );
      final alertId = await repository.insertAlert(draft);
      alert = draft.copyWith(id: alertId);
    }

    return SimulationOutcome(
        latestReading: stored, result: result, alert: alert);
  }

  List<Reading> _buildSeries(LeakScenario scenario, String state,
      String householdId, int householdSize, double expected) {
    final start = DateTime.now().subtract(const Duration(days: _windowDays - 1));
    final readings = <Reading>[];

    for (var day = 0; day < _windowDays; day++) {
      final date = start.add(Duration(days: day));
      final factors = _factors(scenario, day);
      final total = expected * factors.total;
      final night = expected * factors.nightShare;
      readings.add(Reading(
        householdId: householdId,
        state: state,
        householdSize: householdSize,
        readingDate: date,
        dayFlowL: total - night,
        nightFlowL: night,
        scenario: scenario.label,
      ));
    }
    return readings;
  }

  _Factors _factors(LeakScenario scenario, int day) {
    switch (scenario) {
      case LeakScenario.continuousLeak:
        return const _Factors(total: 2.2, nightShare: 0.45);
      case LeakScenario.suddenBurst:
        final isLastDay = day == _windowDays - 1;
        return _Factors(
            total: isLastDay ? 3.6 : 1.0, nightShare: _normalNightShare);
      case LeakScenario.creepingLeak:
        return _Factors(total: 1.0 + day * 0.12, nightShare: _normalNightShare);
      case LeakScenario.seasonalSpike:
        return const _Factors(total: 1.6, nightShare: _normalNightShare);
      case LeakScenario.normalUsage:
        return const _Factors(total: 1.0, nightShare: _normalNightShare);
    }
  }
}

class _Factors {
  final double total;
  final double nightShare;
  const _Factors({required this.total, required this.nightShare});
}
