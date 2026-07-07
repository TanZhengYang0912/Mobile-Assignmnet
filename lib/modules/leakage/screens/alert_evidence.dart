import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/alert.dart';
import '../services/nrw_service.dart';
import '../state/app_state.dart';

/// Evidence rendering shared between the worker's [AlertDetailScreen] and
/// the admin's read-only alert detail view — the underlying data (water
/// balance, electricity balance, tampering, household usage) doesn't
/// depend on who's viewing it, only the actions below it do.

String alertSubtitle(Alert alert, String date) {
  switch (alert.alertType) {
    case AlertType.nrwHotspot:
      return 'NRW hotspot · ${alert.dataYear} data · flagged $date';
    case AlertType.electricityHotspot:
      return 'Electricity loss hotspot · ${alert.dataYear} data · flagged $date';
    case AlertType.electricityTampering:
      return 'Potential tampering · ${DateFormat('MMM y').format(alert.detectedAt)} · flagged $date';
    default:
      return 'Household ${alert.householdId} · flagged $date';
  }
}

Widget alertEvidence(BuildContext context, AppState app, Alert alert) {
  if (alert.isLossBalance) return _balanceEvidence(app, alert);
  if (alert.isElectricityTampering) return _tamperingEvidence(alert);
  return _householdEvidence(alert);
}

Widget alertAssessment(Alert alert) => Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blueGrey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(Icons.lightbulb_outline, size: 18, color: Colors.blue.shade700),
        const SizedBox(width: 9),
        Expanded(
            child: Text(alert.explanation,
                style: const TextStyle(fontSize: 13, height: 1.5))),
      ]),
    );

Widget _tamperingEvidence(Alert alert) {
  final month = DateFormat('MMMM y').format(alert.detectedAt);
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('National losses · $month',
          style: const TextStyle(fontWeight: FontWeight.w600)),
      const SizedBox(height: 8),
      Row(children: [
        Expanded(child: _metricCard('Supplied', alert.producedMld!, 'GWh')),
        const SizedBox(width: 10),
        Expanded(child: _metricCard('Consumed', alert.billedMld!, 'GWh')),
      ]),
      const SizedBox(height: 10),
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(children: [
          Text('Losses',
              style: TextStyle(fontSize: 12, color: Colors.red.shade700)),
          const SizedBox(width: 8),
          Text('${alert.lossMld!.round()}',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.red.shade700)),
          const Spacer(),
          Text('${alert.lossPct!.toStringAsFixed(1)}% · GWh',
              style: TextStyle(fontSize: 13, color: Colors.red.shade700)),
        ]),
      ),
    ],
  );
}

Widget _balanceEvidence(AppState app, Alert alert) {
  final isWater = alert.isNrw;
  final unit = isWater ? 'MLD' : 'GWh';
  final producedLabel = isWater ? 'Produced' : 'Supplied';
  final billedLabel = isWater ? 'Billed' : 'Consumed';
  final billedShare =
      (alert.billedMld! / alert.producedMld! * 100).clamp(0, 100).round();
  final lostShare = 100 - billedShare;
  final trend = isWater ? app.nrw.trendFor(alert.state) : <NrwPoint>[];

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('${isWater ? 'Water' : 'Electricity'} balance (${alert.dataYear})',
          style: const TextStyle(fontWeight: FontWeight.w600)),
      const SizedBox(height: 8),
      Row(children: [
        Expanded(child: _metricCard(producedLabel, alert.producedMld!, unit)),
        const SizedBox(width: 10),
        Expanded(child: _metricCard(billedLabel, alert.billedMld!, unit)),
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
          Text('${alert.lossPct!.toStringAsFixed(1)}% · $unit',
              style: TextStyle(fontSize: 13, color: Colors.red.shade700)),
        ]),
      ),
      const SizedBox(height: 8),
      ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Row(children: [
          Expanded(
              flex: billedShare,
              child: Container(height: 14, color: Colors.blue.shade400)),
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
      Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54)),
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
