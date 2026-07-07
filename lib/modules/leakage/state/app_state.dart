import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../electricity/models/electricity_models.dart';
import '../../electricity/services/electricity_data_service.dart';
import '../data/leakage_repository.dart';
import '../../../config.dart';
import '../models/ai_summary.dart';
import '../models/alert.dart';
import '../models/report.dart';
import '../models/service_review.dart';
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
  List<ServiceReview> _reviews = [];
  AiSummary? _latestSummary;
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
  List<ServiceReview> get reviews => _reviews;
  AiSummary? get latestSummary => _latestSummary;
  bool get loading => _loading;

  Set<int> reviewedAlertIds(String email) => _reviews
      .where((r) => r.consumerEmail == email && r.alertId != null)
      .map((r) => r.alertId!)
      .toSet();

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
    await _seedDemoDataIfNeeded();
    await _seedReviewsIfNeeded();
    _loading = false;
    notifyListeners();
  }

  Future<void> _seedDemoDataIfNeeded() async {
    await _seedWaterIfNeeded();
    await _seedElectricityIfNeeded();
  }

  Future<void> _seedWaterIfNeeded() async {
    final waterAlerts = _alerts.where((a) => !a.isElectricity).toList();
    final waterAlertIds =
        waterAlerts.map((a) => a.id).whereType<int>().toSet();
    final hasWaterReports =
        _reports.any((r) => waterAlertIds.contains(r.alertId));
    if (hasWaterReports) return;

    final now = DateTime.now();

    Future<int> aid(int idx, Alert Function() build) async {
      if (idx < waterAlerts.length && waterAlerts[idx].id != null) {
        return waterAlerts[idx].id!;
      }
      return repository.insertAlert(build());
    }

    final w1 = await aid(0, () => Alert(
          alertType: AlertType.nrwHotspot,
          state: 'Selangor',
          detectedAt: now.subtract(const Duration(days: 1)),
          signature: LeakSignature.nrwHotspot,
          severity: Severity.high,
          explanation: 'High NRW detected in Selangor water distribution network.',
          status: AlertStatus.pending,
          producedMld: 3200,
          billedMld: 2100,
          lossMld: 1100,
          lossPct: 34.4,
          dataYear: 2024,
        ));
    await repository.insertReport(Report(
      alertId: w1,
      workerName: 'Worker',
      findings: 'Pipe burst detected at main junction.',
      actionTaken: 'Temporary bypass installed at Km 12.',
      outcome: ReportOutcome.notFixed,
      createdAt: now.subtract(const Duration(days: 1)),
      updatedAt: now.subtract(const Duration(days: 1)),
    ));

    final w2 = await aid(1, () => Alert(
          alertType: AlertType.nrwHotspot,
          state: 'Kedah',
          detectedAt: now.subtract(const Duration(days: 3)),
          signature: LeakSignature.nrwHotspot,
          severity: Severity.medium,
          explanation: 'NRW loss above threshold in Kedah.',
          status: AlertStatus.resolved,
          producedMld: 1800,
          billedMld: 1500,
          lossMld: 300,
          lossPct: 16.7,
          dataYear: 2024,
        ));
    await repository.insertReport(Report(
      alertId: w2,
      workerName: 'Admin',
      findings: 'Leaking valve replaced at distribution point B.',
      actionTaken: 'Valve replaced and pressure test completed.',
      outcome: ReportOutcome.fixed,
      createdAt: now.subtract(const Duration(days: 3)),
      updatedAt: now.subtract(const Duration(days: 3)),
    ));

    final w3 = await aid(2, () => Alert(
          alertType: AlertType.nrwHotspot,
          state: 'Johor',
          detectedAt: now.subtract(const Duration(days: 5)),
          signature: LeakSignature.nrwHotspot,
          severity: Severity.low,
          explanation: 'Minor NRW variance detected in Johor.',
          status: AlertStatus.resolved,
          producedMld: 2500,
          billedMld: 2350,
          lossMld: 150,
          lossPct: 6.0,
          dataYear: 2024,
        ));
    await repository.insertReport(Report(
      alertId: w3,
      workerName: 'Worker',
      findings: 'No visible leak found. Meter recalibrated.',
      actionTaken: 'Meter recalibration completed.',
      outcome: ReportOutcome.fixed,
      createdAt: now.subtract(const Duration(days: 5)),
      updatedAt: now.subtract(const Duration(days: 5)),
    ));

    await refresh();
  }

  Future<void> _seedElectricityIfNeeded() async {
    final elecAlerts = _alerts.where((a) => a.isElectricity).toList();
    final elecAlertIds =
        elecAlerts.map((a) => a.id).whereType<int>().toSet();
    final hasElecReports =
        _reports.any((r) => elecAlertIds.contains(r.alertId));
    if (hasElecReports) return;

    final now = DateTime.now();

    Future<int> aid(int idx, Alert Function() build) async {
      if (idx < elecAlerts.length && elecAlerts[idx].id != null) {
        return elecAlerts[idx].id!;
      }
      return repository.insertAlert(build());
    }

    final e1 = await aid(0, () => Alert(
          alertType: AlertType.electricityHotspot,
          state: 'Kelantan',
          detectedAt: now.subtract(const Duration(days: 2)),
          signature: LeakSignature.electricityHotspot,
          severity: Severity.medium,
          explanation: 'Above-average electricity loss detected in Kelantan grid.',
          status: AlertStatus.resolved,
          producedMld: 8500,
          billedMld: 7200,
          lossMld: 1300,
          lossPct: 15.3,
          dataYear: 2024,
        ));
    await repository.insertReport(Report(
      alertId: e1,
      workerName: 'Admin',
      findings: 'No findings after on-site check.',
      actionTaken: 'Meter readings verified against billing records.',
      outcome: ReportOutcome.fixed,
      createdAt: now.subtract(const Duration(days: 2)),
      updatedAt: now.subtract(const Duration(days: 2)),
    ));

    final e2 = await aid(1, () => Alert(
          alertType: AlertType.electricityHotspot,
          state: 'Kelantan',
          detectedAt: now.subtract(const Duration(days: 2)),
          signature: LeakSignature.electricityHotspot,
          severity: Severity.high,
          explanation: 'Suspected meter tampering pattern in Kelantan substation.',
          status: AlertStatus.notFixed,
          producedMld: 9200,
          billedMld: 7000,
          lossMld: 2200,
          lossPct: 23.9,
          dataYear: 2024,
        ));
    await repository.insertReport(Report(
      alertId: e2,
      workerName: 'Worker',
      findings: 'extrcityuyhj — logged by field worker.',
      actionTaken: 'Flagged for re-inspection next cycle.',
      outcome: ReportOutcome.notFixed,
      createdAt: now.subtract(const Duration(days: 2)),
      updatedAt: now.subtract(const Duration(days: 2)),
    ));

    final e3 = await aid(2, () => Alert(
          alertType: AlertType.electricityHotspot,
          state: 'Terengganu',
          detectedAt: now.subtract(const Duration(days: 4)),
          signature: LeakSignature.electricityHotspot,
          severity: Severity.low,
          explanation: 'Minor distribution loss in Terengganu zone.',
          status: AlertStatus.resolved,
          producedMld: 7100,
          billedMld: 6600,
          lossMld: 500,
          lossPct: 7.0,
          dataYear: 2024,
        ));
    await repository.insertReport(Report(
      alertId: e3,
      workerName: 'Worker',
      findings: 'Replaced faulty valve at station 3.',
      actionTaken: 'Distribution cable splice repaired at substation.',
      outcome: ReportOutcome.fixed,
      createdAt: now.subtract(const Duration(days: 4)),
      updatedAt: now.subtract(const Duration(days: 4)),
    ));

    await refresh();
  }

  Future<void> refresh() async {
    _alerts = await repository.alerts();
    _reports = await repository.reports();
    _reviews = await repository.reviews();
    _latestSummary = await repository.latestAiSummary();
    notifyListeners();
  }

  Future<void> submitReview(ServiceReview review) async {
    await repository.insertReview(review);
    await refresh();
  }

  Future<bool> generateAiSummary() async {
    try {
      if (_reviews.isEmpty) return false;

      final reviewsText = _reviews.take(50).toList().asMap().entries.map((e) {
        final r = e.value;
        final tags = r.tags.isEmpty ? 'none' : r.tags.join(', ');
        final comment = r.comment.isEmpty ? 'No comment' : r.comment;
        return 'Review ${e.key + 1}: ${r.stars}/5 stars. Tags: $tags. Comment: "$comment"';
      }).join('\n');

      final response = await http.post(
        Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
        headers: {
          'Authorization': 'Bearer ${GroqConfig.apiKey}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': 'llama3-8b-8192',
          'messages': [
            {
              'role': 'system',
              'content':
                  'You are a professional service quality analyst for a Malaysian water and electricity utility company. Analyze repair service reviews. Always respond with valid JSON in this exact format: {"summary": "2-3 sentence overall assessment", "pros": ["pro 1", "pro 2", "pro 3"], "cons": ["con 1", "con 2"]}. Keep each pro/con under 5 words.',
            },
            {
              'role': 'user',
              'content':
                  'Analyze these ${_reviews.length} repair service reviews from mySumber customers:\n\n$reviewsText\n\nProvide a balanced assessment focusing on repair quality and customer experience.',
            },
          ],
          'response_format': {'type': 'json_object'},
          'max_tokens': 512,
          'temperature': 0.3,
        }),
      );

      if (response.statusCode != 200) return false;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final content =
          data['choices'][0]['message']['content'] as String;
      final result = jsonDecode(content) as Map<String, dynamic>;

      await repository.insertAiSummary(
        summaryText: result['summary'] as String? ?? '',
        pros: List<String>.from(result['pros'] ?? []),
        cons: List<String>.from(result['cons'] ?? []),
        reviewCount: _reviews.length,
      );

      await refresh();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _seedReviewsIfNeeded() async {
    final existing = await repository.reviews();
    if (existing.isNotEmpty) return;

    final now = DateTime.now();
    final seeds = [
      ServiceReview(
        consumerEmail: 'ahmad@example.com',
        stars: 5,
        tags: ['Fast Response', 'Perfectly Fixed', 'Professional'],
        comment: 'Technician arrived within 2 hours and fixed the burst pipe completely. Very impressed with the speed and quality!',
        createdAt: now.subtract(const Duration(days: 1)),
      ),
      ServiceReview(
        consumerEmail: 'siti@example.com',
        stars: 4,
        tags: ['Perfectly Fixed', 'Great Attitude'],
        comment: 'Good service overall. The leak was fully resolved. Slight delay but the work quality was excellent.',
        createdAt: now.subtract(const Duration(days: 2)),
      ),
      ServiceReview(
        consumerEmail: 'razif@example.com',
        stars: 2,
        tags: ['Still Leaking', 'Slow Response'],
        comment: 'Still a small drip after the repair. Called back and was told they would return next week. Disappointing.',
        createdAt: now.subtract(const Duration(days: 3)),
      ),
      ServiceReview(
        consumerEmail: 'nurul@example.com',
        stars: 5,
        tags: ['Fast Response', 'Thorough Check', 'Professional'],
        comment: 'Outstanding! The team did a thorough inspection of the whole pipe system and found an additional hidden crack.',
        createdAt: now.subtract(const Duration(days: 4)),
      ),
      ServiceReview(
        consumerEmail: 'hafiz@example.com',
        stars: 3,
        tags: ['Slow Response', 'Poor Fix'],
        comment: 'Waited 3 days for someone to come. The fix seemed rushed — hoping it holds up over the next few weeks.',
        createdAt: now.subtract(const Duration(days: 5)),
      ),
      ServiceReview(
        consumerEmail: 'mei@example.com',
        stars: 5,
        tags: ['Perfectly Fixed', 'Great Attitude', 'Fast Response'],
        comment: 'Excellent experience. The worker explained everything clearly and showed me the repaired section before leaving.',
        createdAt: now.subtract(const Duration(days: 6)),
      ),
      ServiceReview(
        consumerEmail: 'rajan@example.com',
        stars: 1,
        tags: ['Overcharged', 'Unprofessional'],
        comment: 'Was charged extra fees not mentioned in the initial quote. When I asked, the worker was rude. Will escalate.',
        createdAt: now.subtract(const Duration(days: 7)),
      ),
      ServiceReview(
        consumerEmail: 'lily@example.com',
        stars: 4,
        tags: ['Fast Response', 'Thorough Check'],
        comment: 'Quick response and the repair looks solid. Happy with the service, just wished they cleaned up after.',
        createdAt: now.subtract(const Duration(days: 8)),
      ),
    ];

    for (final r in seeds) {
      await repository.insertReview(r);
    }
    await refresh();
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
