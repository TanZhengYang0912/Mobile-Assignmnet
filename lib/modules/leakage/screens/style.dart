import 'package:flutter/material.dart';

import '../models/alert.dart';

Color severityColor(String severity) {
  switch (severity) {
    case Severity.high:
      return Colors.red.shade600;
    case Severity.medium:
      return Colors.orange.shade700;
    case Severity.low:
      return Colors.blue.shade600;
    default:
      return Colors.blueGrey;
  }
}

Color statusColor(String status) {
  switch (status) {
    case AlertStatus.pending:
      return Colors.blueGrey.shade500;
    case AlertStatus.investigating:
      return Colors.blue.shade600;
    case AlertStatus.resolved:
      return Colors.green.shade600;
    case AlertStatus.notFixed:
      return Colors.red.shade600;
    case AlertStatus.dismissed:
      return Colors.grey;
    default:
      return Colors.blueGrey;
  }
}

Widget pill(String text, Color color) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color),
    ),
    child: Text(
      text,
      style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12),
    ),
  );
}
