import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/report.dart';

class ReportViewScreen extends StatelessWidget {
  final Report report;
  const ReportViewScreen({super.key, required this.report});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('d MMM y, HH:mm');
    final outcomeColor = report.isFixed ? Colors.green : Colors.orange;

    return Scaffold(
      appBar: AppBar(title: const Text('Investigation report')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
              '${report.workerName} · ${dateFormat.format(report.createdAt)}',
              style: const TextStyle(fontSize: 12, color: Colors.black54)),
          const SizedBox(height: 16),
          const Text('Findings',
              style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black26),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(report.findings.isEmpty
                ? 'No findings recorded'
                : report.findings),
          ),
          const SizedBox(height: 16),
          const Text('Action taken',
              style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black26),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(report.actionTaken.isEmpty
                ? 'No action recorded'
                : report.actionTaken),
          ),
          const SizedBox(height: 16),
          const Text('Outcome', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: outcomeColor.withValues(alpha: 0.12),
              border: Border.all(color: outcomeColor),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(children: [
              Icon(report.isFixed ? Icons.check : Icons.warning_amber,
                  color: outcomeColor, size: 18),
              const SizedBox(width: 8),
              Text(ReportOutcome.label(report.outcome),
                  style: TextStyle(
                      color: outcomeColor, fontWeight: FontWeight.w600)),
            ]),
          ),
          const SizedBox(height: 12),
          Text('Last updated ${dateFormat.format(report.updatedAt)}',
              style: const TextStyle(fontSize: 12, color: Colors.black45)),
        ],
      ),
    );
  }
}
