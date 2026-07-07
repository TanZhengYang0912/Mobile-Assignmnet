import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/alert.dart';
import '../state/app_state.dart';
import 'alert_queue_screen.dart';
import 'report_history_screen.dart';

class HomeScreen extends StatelessWidget {
  final Utility utility;
  const HomeScreen({super.key, this.utility = Utility.water});

  bool get _isWater => utility == Utility.water;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    if (app.loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final unresolved = app.unresolvedFor(utility).length;
    final reports = app.reportsFor(utility).length;
    final color = _isWater ? Colors.blue.shade700 : Colors.amber.shade700;
    final title =
        _isWater ? 'Water Leakage Detection' : 'Electricity Anomaly Detection';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: color,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            tileColor: Colors.blueGrey.shade50,
            leading: const Icon(Icons.warning_amber),
            title: const Text('Alert Queue'),
            subtitle: Text('$unresolved Unresolved Alert(s)'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => AlertQueueScreen(utility: utility))),
          ),
          const SizedBox(height: 8),
          ListTile(
            tileColor: Colors.blueGrey.shade50,
            leading: const Icon(Icons.description_outlined),
            title: const Text('Report History'),
            subtitle: Text('$reports Report(s)'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => ReportHistoryScreen(utility: utility))),
          ),
        ],
      ),
    );
  }
}
