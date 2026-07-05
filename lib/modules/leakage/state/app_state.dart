import 'package:flutter/foundation.dart';

import '../data/leakage_repository.dart';
import '../models/alert.dart';
import '../models/report.dart';
import '../services/baseline_service.dart';
import '../services/explainer.dart';
import '../services/nrw_service.dart';
import '../services/simulation_service.dart';

class AppState extends ChangeNotifier {
  final BaselineService baseline;
  final NrwService nrw;
  final LeakageRepository repository;
  final SimulationService simulation;
  final Explainer explainer;

  List<Alert> _alerts = [];
  List<Report> _reports = [];
  bool _loading = true;

  AppState({
    required this.baseline,
    required this.nrw,
    required this.repository,
    required this.simulation,
    Explainer? explainer,
  }) : explainer = explainer ?? Explainer();

  String get workerName => 'Worker X';
  List<Alert> get alerts => _alerts;
  List<Report> get reports => _reports;
  bool get loading => _loading;

  List<Alert> get unresolvedAlerts =>
      _bySeverity(_alerts.where((a) => a.isUnresolved));
  List<Alert> get resolvedAlerts =>
      _bySeverity(_alerts.where((a) => a.status == AlertStatus.resolved));

  static const _severityRank = {
    Severity.high: 3,
    Severity.medium: 2,
    Severity.low: 1,
  };

  double _magnitude(Alert a) => a.isNrw ? (a.lossPct ?? 0) : a.ratio;

  List<Alert> _bySeverity(Iterable<Alert> source) {
    final list = source.toList();
    list.sort((a, b) {
      final rank = (_severityRank[b.severity] ?? 0)
          .compareTo(_severityRank[a.severity] ?? 0);
      if (rank != 0) return rank;
      return _magnitude(b).compareTo(_magnitude(a));
    });
    return list;
  }

  Future<void> init() async {
    await baseline.load();
    await nrw.load();
    await refresh();
    _loading = false;
    notifyListeners();
  }

  Future<void> refresh() async {
    _alerts = await repository.alerts(includeDismissed: false);
    _reports = await repository.reports();
    notifyListeners();
  }

  Future<int> runAnalysis() async {
    final existing = await repository.nrwAlertStates();
    final results = nrw.analyse();
    var added = 0;
    for (final r in results) {
      if (existing.contains(r.state)) continue;
      final alert = Alert(
        alertType: AlertType.nrwHotspot,
        state: r.state,
        detectedAt: DateTime.now(),
        signature: LeakSignature.nrwHotspot,
        severity: r.severity,
        explanation: explainer.describeNrw(r, nrw.nationalLossPct),
        producedMld: r.producedMld,
        billedMld: r.billedMld,
        lossMld: r.lossMld,
        lossPct: r.lossPct,
        dataYear: r.year,
      );
      await repository.insertAlert(alert);
      added++;
    }
    await refresh();
    return added;
  }

  Future<SimulationOutcome> simulate(LeakScenario scenario, String state) async {
    final outcome = await simulation.run(scenario, state);
    await refresh();
    return outcome;
  }

  Future<void> updateAlertStatus(int alertId, String status) async {
    await repository.updateAlertStatus(alertId, status);
    await refresh();
  }

  Future<void> saveReport(Report report) async {
    if (report.id == null) {
      await repository.insertReport(report);
    } else {
      await repository.updateReport(report);
    }
    await refresh();
  }
}
