import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/alert.dart';
import '../models/report.dart';
import '../services/nrw_service.dart';
import '../state/app_state.dart';
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
        appBar: AppBar(title: const Text('Alert')),
        body: const Center(child: Text('This alert is no longer available.')),
      );
    }
    final alert = match.first;
    final reports = _reportsFor(app, alertId);
    final date = DateFormat('d MMM y').format(alert.detectedAt);
    final subtitle = alert.isNrw
        ? 'NRW hotspot · ${alert.dataYear} data · flagged $date'
        : 'Household ${alert.householdId} · flagged $date';

    return Scaffold(
      appBar: AppBar(title: Text(alert.state)),
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
          if (alert.isNrw) _nrwEvidence(context, app, alert)
          else _householdEvidence(alert),
          const SizedBox(height: 16),
          _assessment(alert),
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

  Widget _nrwEvidence(BuildContext context, AppState app, Alert alert) {
    final billedShare =
        (alert.billedMld! / alert.producedMld! * 100).clamp(0, 100).round();
    final lostShare = 100 - billedShare;
    final trend = app.nrw.trendFor(alert.state);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Water balance (${alert.dataYear})',
            style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: _metricCard('Produced', alert.producedMld!, 'MLD')),
          const SizedBox(width: 10),
          Expanded(child: _metricCard('Billed', alert.billedMld!, 'MLD')),
        ]),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(children: [
            Text('Lost',
                style: TextStyle(fontSize: 12, color: Colors.red.shade700)),
            const SizedBox(width: 8),
            Text('${alert.lossMld!.round()}',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.red.shade700)),
            const Spacer(),
            Text('${alert.lossPct!.toStringAsFixed(1)}% · MLD',
                style: TextStyle(fontSize: 13, color: Colors.red.shade700)),
          ]),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Row(children: [
            Expanded(
                flex: billedShare,
                child: Container(height: 14, color: Colors.teal.shade400)),
            Expanded(
                flex: lostShare,
                child: Container(height: 14, color: Colors.red.shade400)),
          ]),
        ),
        const SizedBox(height: 4),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Reaches customers $billedShare%',
              style: const TextStyle(fontSize: 11, color: Colors.black45)),
          Text('Lost $lostShare%',
              style: const TextStyle(fontSize: 11, color: Colors.black45)),
        ]),
        if (trend.length > 1) ...[
          const SizedBox(height: 16),
          Text('Loss trend · ${trend.first.year}–${trend.last.year}',
              style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          SizedBox(
              height: 48,
              child: CustomPaint(
                  size: Size.infinite, painter: _SparklinePainter(trend))),
        ],
      ],
    );
  }

  Widget _householdEvidence(Alert alert) {
    return Column(children: [
      _metricRow('Expected', '${alert.baselineL.round()} L/day'),
      _metricRow('Actual', '${alert.actualL.round()} L/day'),
      _metricRow('Ratio', '${alert.ratio.toStringAsFixed(1)}× average'),
    ]);
  }

  Widget _metricCard(String label, double value, String unit) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blueGrey.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: const TextStyle(fontSize: 12, color: Colors.black54)),
        const SizedBox(height: 2),
        Text('${value.round()} $unit',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
      ]),
    );
  }

  Widget _metricRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: Colors.black54)),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      );

  Widget _assessment(Alert alert) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.blueGrey.shade50,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(Icons.lightbulb_outline, size: 18, color: Colors.teal.shade700),
          const SizedBox(width: 9),
          Expanded(
              child: Text(alert.explanation,
                  style: const TextStyle(fontSize: 13, height: 1.5))),
        ]),
      );

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
      children.add(_primary(context, 'Start investigation', Icons.play_arrow,
          () => _updateStatus(context, app, alert.id!, AlertStatus.investigating)));
    } else if (alert.status == AlertStatus.investigating) {
      children.add(_primary(context, 'Write report', Icons.edit_note, () {
        Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => ReportFormScreen(alert: alert)));
      }));
    } else if (alert.status == AlertStatus.notFixed) {
      children.add(_primary(context, 'Re-investigate', Icons.refresh,
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

class _SparklinePainter extends CustomPainter {
  final List<NrwPoint> points;
  _SparklinePainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;
    final values = points.map((p) => p.lossPct).toList();
    final minV = values.reduce((a, b) => a < b ? a : b);
    final maxV = values.reduce((a, b) => a > b ? a : b);
    final range = (maxV - minV).abs() < 1 ? 1 : maxV - minV;
    final dx = size.width / (points.length - 1);

    final path = Path();
    for (var i = 0; i < points.length; i++) {
      final x = dx * i;
      final y = size.height - ((values[i] - minV) / range) * size.height;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    final paint = Paint()
      ..color = Colors.red.shade400
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawPath(path, paint);

    final last = Offset(size.width,
        size.height - ((values.last - minV) / range) * size.height);
    canvas.drawCircle(last, 3.5, Paint()..color = Colors.red.shade600);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) =>
      oldDelegate.points != points;
}
