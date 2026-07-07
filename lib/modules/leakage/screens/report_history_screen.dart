import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/alert.dart';
import '../models/report.dart';
import '../state/app_state.dart';
import 'report_view_screen.dart';

class ReportHistoryScreen extends StatelessWidget {
  final Utility utility;
  const ReportHistoryScreen({super.key, this.utility = Utility.water});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final reports = app.reportsFor(utility);
    final dateFormat = DateFormat('d MMM y, HH:mm');
    final color = utility == Utility.water
        ? Colors.blue.shade700
        : Colors.amber.shade700;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Report History'),
        backgroundColor: color,
        foregroundColor: Colors.white,
      ),
      body: reports.isEmpty
          ? const Center(child: Text('No reports yet.'))
          : ListView.separated(
              itemCount: reports.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final report = reports[index];
                final matches =
                    app.alerts.where((a) => a.id == report.alertId);
                final alert = matches.isEmpty ? null : matches.first;
                return ListTile(
                  leading: Icon(
                    report.isFixed
                        ? Icons.check_circle_outline
                        : Icons.build_outlined,
                    color: report.isFixed ? Colors.green : Colors.orange,
                  ),
                  title: Text(
                      '${alert?.state ?? "Alert #${report.alertId}"} · ${ReportOutcome.label(report.outcome)}'),
                  subtitle: Text(
                    '${report.findings.isEmpty ? "No findings" : report.findings}'
                    '\nUpdated ${dateFormat.format(report.updatedAt)}',
                  ),
                  isThreeLine: true,
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => ReportViewScreen(report: report),
                      )),
                );
              },
            ),
    );
  }
}
