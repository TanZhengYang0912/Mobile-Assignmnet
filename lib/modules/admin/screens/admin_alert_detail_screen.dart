import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../leakage/models/alert.dart';
import '../../leakage/models/report.dart';
import '../../leakage/screens/alert_evidence.dart';
import '../../leakage/screens/network_error.dart';
import '../../leakage/screens/report_view_screen.dart';
import '../../leakage/screens/style.dart';
import '../../leakage/state/app_state.dart';

/// Admin's read-only view of an alert: full evidence + linked investigation
/// reports, plus the false-positive gate (pending ↔ faults) when applicable.
/// Admin cannot investigate, write a report, or resolve an alert.
class AdminAlertDetailScreen extends StatefulWidget {
  final int alertId;
  const AdminAlertDetailScreen({super.key, required this.alertId});

  @override
  State<AdminAlertDetailScreen> createState() =>
      _AdminAlertDetailScreenState();
}

class _AdminAlertDetailScreenState extends State<AdminAlertDetailScreen> {
  bool _busy = false;

  Future<void> _toggleGate(AppState app, Alert alert) async {
    setState(() => _busy = true);
    final next = alert.status == AlertStatus.pending
        ? AlertStatus.faults
        : AlertStatus.pending;
    try {
      await app.updateAlertStatus(alert.id!, next);
    } catch (_) {
      if (mounted) showNetworkErrorSnackBar(context);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final match = app.alerts.where((a) => a.id == widget.alertId);
    if (match.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Alert'),
          backgroundColor: Colors.teal.shade700,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: Text('This alert is no longer available.')),
      );
    }
    final alert = match.first;
    final reports =
        app.reports.where((r) => r.alertId == widget.alertId).toList();
    final date = DateFormat('d MMM y').format(alert.detectedAt);
    final subtitle = alertSubtitle(alert, date);

    return Scaffold(
      appBar: AppBar(
        title: Text(alert.title),
        backgroundColor: Colors.teal.shade700,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(children: [
            pill(Severity.label(alert.severity), severityColor(alert.severity)),
            const SizedBox(width: 8),
            pill(AlertStatus.label(alert.status), statusColor(alert.status)),
          ]),
          const SizedBox(height: 10),
          Text(subtitle,
              style: const TextStyle(fontSize: 12, color: Colors.black54)),
          const SizedBox(height: 18),
          alertEvidence(context, app, alert),
          const SizedBox(height: 16),
          alertAssessment(alert),
          const SizedBox(height: 20),
          _reportsList(context, reports),
          _gateButton(app, alert),
        ],
      ),
    );
  }

  Widget _reportsList(BuildContext context, List<Report> reports) {
    if (reports.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final report in reports) ...[
          Card(
            child: ListTile(
              leading: Icon(
                  report.isFixed
                      ? Icons.check_circle_outline
                      : Icons.build_outlined,
                  color: report.isFixed ? Colors.green : Colors.orange),
              title: Text('Report · ${ReportOutcome.label(report.outcome)}'),
              subtitle: Text(report.findings.isEmpty
                  ? 'No findings recorded'
                  : report.findings),
              trailing: const Text('View'),
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => ReportViewScreen(report: report))),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _gateButton(AppState app, Alert alert) {
    if (alert.status != AlertStatus.pending &&
        alert.status != AlertStatus.faults) {
      return const SizedBox.shrink();
    }
    final isFaults = alert.status == AlertStatus.faults;
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _busy ? null : () => _toggleGate(app, alert),
        icon: _busy
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2))
            : Icon(isFaults ? Icons.undo : Icons.block),
        label: Text(isFaults ? 'Restore to Pending' : 'Mark as Fault'),
      ),
    );
  }
}
