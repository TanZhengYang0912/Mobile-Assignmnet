import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../theme/tokens.dart';
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
          backgroundColor: AppColors.adminPrimary,
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
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: Text(alert.title),
        backgroundColor: AppColors.adminPrimary,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Pill(Severity.label(alert.severity),
                      color: severityColor(alert.severity)),
                  const SizedBox(width: 8),
                  Pill(AlertStatus.label(alert.status),
                      color: statusColor(alert.status)),
                ]),
                const SizedBox(height: 8),
                Text(alert.title,
                    style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 4),
                Text(subtitle,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          const SizedBox(height: 10),
          AppCard(
            child: alertEvidence(context, app, alert),
          ),
          const SizedBox(height: 10),
          AppCard(
            background: const Color(0xFFF0FDF4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.lightbulb_outline,
                    size: 18, color: AppColors.adminPrimary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(alert.explanation,
                      style: const TextStyle(
                          fontSize: 13,
                          height: 1.5,
                          color: AppColors.textPrimary)),
                ),
              ],
            ),
          ),
          if (reports.isNotEmpty) ...[
            const SizedBox(height: 16),
            const SectionLabel('INVESTIGATION REPORTS'),
            const SizedBox(height: 8),
            _reportsList(context, reports),
          ],
          const SizedBox(height: 10),
          _gateButton(app, alert),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _reportsList(BuildContext context, List<Report> reports) {
    return Column(
      children: [
        for (final report in reports) ...[
          AppCard(
            padding: EdgeInsets.zero,
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              leading: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: (report.isFixed ? AppColors.success : AppColors.warning)
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  report.isFixed
                      ? Icons.check_circle_outline
                      : Icons.build_outlined,
                  color:
                      report.isFixed ? AppColors.success : AppColors.warning,
                  size: 18,
                ),
              ),
              title: Text('Report · ${ReportOutcome.label(report.outcome)}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14)),
              subtitle: Text(
                  report.findings.isEmpty
                      ? 'No findings recorded'
                      : report.findings,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary)),
              trailing: const Icon(Icons.chevron_right,
                  color: AppColors.textTertiary),
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => ReportViewScreen(report: report))),
            ),
          ),
          const SizedBox(height: 8),
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
    return OutlinedButton.icon(
      onPressed: _busy ? null : () => _toggleGate(app, alert),
      icon: _busy
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2))
          : Icon(isFaults ? Icons.undo : Icons.block,
              color: isFaults ? AppColors.adminPrimary : AppColors.critical),
      label: Text(
        isFaults ? 'Restore to Pending' : 'Mark as Fault',
        style: TextStyle(
            color: isFaults ? AppColors.adminPrimary : AppColors.critical,
            fontWeight: FontWeight.w600),
      ),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        side: BorderSide(
            color: isFaults ? AppColors.adminPrimary : AppColors.critical),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}
