import 'package:flutter/foundation.dart';

import '../../electricity/models/electricity_models.dart';
import '../../electricity/services/electricity_data_service.dart';
import '../data/leakage_repository.dart';
import '../models/alert.dart';
import '../models/report.dart';
import '../services/baseline_service.dart';
import '../services/electricity_loss_service.dart';
import '../services/explainer.dart';
import '../services/nrw_service.dart';
import '../services/simulation_service.dart';

class AppState extends ChangeNotifier {
  final BaselineService baseline;
  final NrwService nrw;
  final ElectricityLossService electricityLoss;
  final ElectricityDataService electricityData;
  final LeakageRepository repository;
  final SimulationService simulation;
  final Explainer explainer;

  List<Alert> _alerts = [];
  List<Report> _reports = [];
  List<ElectricityRecord> _electricityRecords = [];
  bool _loading = true;

  AppState({
    required this.baseline,
    required this.nrw,
    required this.repository,
    required this.simulation,
    ElectricityLossService? electricityLoss,
    ElectricityDataService? electricityData,
    Explainer? explainer,
  })  : electricityLoss = electricityLoss ?? ElectricityLossService(),
        electricityData = electricityData ?? ElectricityDataService(),
        explainer = explainer ?? Explainer();

  String get workerName => 'Worker X';
  List<Alert> get alerts => _alerts;
  List<Report> get reports => _reports;
  bool get loading => _loading;

  // --- Per-utility queues, used by the worker Water / Electricity tabs ---
  List<Alert> unresolvedFor(Utility u) =>
      _bySeverity(_alerts.where((a) => a.utility == u && a.isUnresolved));
  List<Alert> resolvedFor(Utility u) => _bySeverity(
      _alerts.where((a) => a.utility == u && a.status == AlertStatus.resolved));

  List<Report> reportsFor(Utility u) {
    final ids = _alerts
        .where((a) => a.utility == u)
        .map((a) => a.id)
        .whereType<int>()
        .toSet();
    return _reports.where((r) => ids.contains(r.alertId)).toList();
  }

  // --- Admin Oversight status groups: optional utility filter, null = all ---
  bool _matchesUtility(Alert a, Utility? utility) =>
      utility == null || a.utility == utility;

  List<Alert> pendingAlerts([Utility? utility]) => _bySeverity(_alerts.where(
      (a) => a.status == AlertStatus.pending && _matchesUtility(a, utility)));

  List<Alert> ongoingAlerts([Utility? utility]) => _bySeverity(_alerts.where(
      (a) =>
          (a.status == AlertStatus.investigating ||
              a.status == AlertStatus.notFixed) &&
          _matchesUtility(a, utility)));

  List<Alert> solvedAlerts([Utility? utility]) => _bySeverity(_alerts.where(
      (a) => a.status == AlertStatus.resolved && _matchesUtility(a, utility)));

  List<Alert> faultAlerts([Utility? utility]) => _bySeverity(_alerts.where(
      (a) => a.status == AlertStatus.faults && _matchesUtility(a, utility)));

  /// Reports for the admin Oversight Reports tab, filtered by the alert's
  /// utility/state and the report's own outcome.
  List<Report> reportsFiltered({Utility? utility, String? state, String? outcome}) {
    final alertById = {
      for (final a in _alerts)
        if (a.id != null) a.id!: a,
    };
    return _reports.where((r) {
      final alert = alertById[r.alertId];
      if (utility != null && (alert == null || alert.utility != utility)) {
        return false;
      }
      if (state != null && (alert == null || alert.state != state)) {
        return false;
      }
      if (outcome != null && r.outcome != outcome) return false;
      return true;
    }).toList();
  }

  // --- "Already reported" sets for the admin Abnormal Production screen ---
  Set<String> get reportedWaterStates =>
      _alerts.where((a) => a.isNrw).map((a) => a.state).toSet();
  Set<String> get reportedElectricityStates =>
      _alerts.where((a) => a.isElectricityHotspot).map((a) => a.state).toSet();
  Set<String> get reportedTamperingKeys => _alerts
      .where((a) => a.isElectricityTampering)
      .map((a) => monthKey(a.detectedAt))
      .toSet();

  List<ElectricityRecord> get tamperingCandidates =>
      _electricityRecords.where((r) => r.isAnomaly).toList();

  static String monthKey(DateTime d) => '${d.year}-${d.month}';

  static const _severityRank = {
    Severity.high: 3,
    Severity.medium: 2,
    Severity.low: 1,
  };

  /// Default queue order: latest first, then severity (high → low),
  /// then state name A–Z.
  List<Alert> _bySeverity(Iterable<Alert> source) {
    final list = source.toList();
    list.sort((a, b) {
      final byDate = b.detectedAt.compareTo(a.detectedAt);
      if (byDate != 0) return byDate;
      final bySeverity = (_severityRank[b.severity] ?? 0)
          .compareTo(_severityRank[a.severity] ?? 0);
      if (bySeverity != 0) return bySeverity;
      return a.state.compareTo(b.state);
    });
    return list;
  }

  Future<void> init() async {
    await baseline.load();
    await nrw.load();
    await electricityLoss.load();
    _electricityRecords = await electricityData.loadRecords();
    await refresh();
    _loading = false;
    notifyListeners();
  }

  Future<void> refresh() async {
    _alerts = await repository.alerts();
    _reports = await repository.reports();
    notifyListeners();
  }

  // --- Water: admin reports a per-state NRW hotspot ---
  Future<bool> reportAbnormalState(NrwResult result) async {
    if (reportedWaterStates.contains(result.state)) return false;
    final alert = Alert(
      alertType: AlertType.nrwHotspot,
      state: result.state,
      detectedAt: DateTime.now(),
      signature: LeakSignature.nrwHotspot,
      severity: result.severity,
      explanation: explainer.describeNrw(result, nrw.nationalLossPct),
      producedMld: result.producedMld,
      billedMld: result.billedMld,
      lossMld: result.lossMld,
      lossPct: result.lossPct,
      dataYear: result.year,
    );
    await repository.insertAlert(alert);
    await refresh();
    return true;
  }

  // --- Electricity: admin reports a per-state loss hotspot ---
  Future<bool> reportElectricityState(NrwResult result) async {
    if (reportedElectricityStates.contains(result.state)) return false;
    final alert = Alert(
      alertType: AlertType.electricityHotspot,
      state: result.state,
      detectedAt: DateTime.now(),
      signature: LeakSignature.electricityHotspot,
      severity: result.severity,
      explanation:
          explainer.describeElectricityLoss(result, electricityLoss.nationalLossPct),
      producedMld: result.producedMld,
      billedMld: result.billedMld,
      lossMld: result.lossMld,
      lossPct: result.lossPct,
      dataYear: result.year,
    );
    await repository.insertAlert(alert);
    await refresh();
    return true;
  }

  // --- Electricity: admin reports a national tampering spike (a month) ---
  Future<bool> reportElectricityTampering(ElectricityRecord record) async {
    if (reportedTamperingKeys.contains(monthKey(record.date))) return false;
    final lossPct =
        record.supply == 0 ? 0.0 : record.losses / record.supply * 100;
    final alert = Alert(
      alertType: AlertType.electricityTampering,
      state: 'Malaysia',
      detectedAt: record.date,
      signature: LeakSignature.electricityTampering,
      severity: _tamperingSeverity(lossPct),
      explanation:
          explainer.describeTampering(record.date.year, lossPct, record.losses),
      producedMld: record.supply,
      billedMld: record.consumption,
      lossMld: record.losses,
      lossPct: lossPct,
      dataYear: record.date.year,
    );
    await repository.insertAlert(alert);
    await refresh();
    return true;
  }

  String _tamperingSeverity(double lossPct) {
    if (lossPct > 10) return Severity.high;
    if (lossPct > 6) return Severity.medium;
    return Severity.low;
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
    await repository.insertReport(report);
    await refresh();
  }

  /// All reports including hidden ones, for the admin oversight screen.
  Future<List<Report>> allReportsForOversight() =>
      repository.reports(includeDeleted: true);

  Future<void> setReportHidden(int reportId, bool hidden) async {
    await repository.setReportDeleted(reportId, hidden);
    await refresh();
  }
}
