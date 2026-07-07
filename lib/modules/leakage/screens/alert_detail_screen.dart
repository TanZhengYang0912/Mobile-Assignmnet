import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/alert.dart';
import '../models/report.dart';
import '../state/app_state.dart';
import 'alert_evidence.dart';
import 'network_error.dart';
import 'report_form_screen.dart';
import 'report_view_screen.dart';
import 'style.dart';

class AlertDetailScreen extends StatelessWidget {
  final int alertId;
  const AlertDetailScreen({super.key, required this.alertId});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final match = app.alerts.where((a) => a.id == alertId);
    if (match.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Alert'),
          backgroundColor: Colors.blue.shade700,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: Text('This alert is no longer available.')),
      );
    }
    final alert = match.first;
    final reports = _reportsFor(app, alertId);
    final date = DateFormat('d MMM y').format(alert.detectedAt);
    final subtitle = alertSubtitle(alert, date);

    return Scaffold(
      appBar: AppBar(
        title: Text(alert.state),
        backgroundColor: Colors.blue.shade700,
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
          _actions(context, app, alert, reports),
        ],
      ),
    );
  }

  Future<void> _updateStatus(
      BuildContext context, AppState app, int alertId, String status) async {
    try {
      await app.updateAlertStatus(alertId, status);
    } catch (_) {
      if (context.mounted) showNetworkErrorSnackBar(context);
    }
  }

  List<Report> _reportsFor(AppState app, int alertId) =>
      app.reports.where((r) => r.alertId == alertId).toList();

  Widget _actions(
      BuildContext context, AppState app, Alert alert, List<Report> reports) {
    final children = <Widget>[];

    for (final report in reports) {
      children.add(Card(
        child: ListTile(
          leading: Icon(
              report.isFixed ? Icons.check_circle_outline : Icons.build_outlined,
              color: report.isFixed ? Colors.green : Colors.orange),
          title: Text('Report · ${ReportOutcome.label(report.outcome)}'),
          subtitle: Text(
              report.findings.isEmpty ? 'No findings recorded' : report.findings),
          trailing: const Text('View'),
          onTap: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => ReportViewScreen(report: report))),
        ),
      ));
      children.add(const SizedBox(height: 12));
    }

    if (alert.status == AlertStatus.pending) {
      children.add(_primary(context, 'Start Investigation', Icons.play_arrow,
          () => _updateStatus(context, app, alert.id!, AlertStatus.investigating)));
    } else if (alert.status == AlertStatus.investigating) {
      children.add(_primary(context, 'Write Report', Icons.edit_note, () {
        Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => ReportFormScreen(alert: alert)));
      }));
    } else if (alert.status == AlertStatus.notFixed) {
      children.add(_primary(context, 'Re-Investigate', Icons.refresh,
          () => _updateStatus(context, app, alert.id!, AlertStatus.investigating)));
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children);
  }

  Widget _primary(
      BuildContext context, String label, IconData icon, VoidCallback onTap) {
    return FilledButton.icon(
      onPressed: onTap,
      icon: Icon(icon),
      label: Text(label),
      style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(46)),
    );
  }
}
