import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/simulation_service.dart';
import '../state/app_state.dart';
import 'alert_queue_screen.dart';
import 'network_error.dart';
import 'report_history_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedState = 'Selangor';
  bool _analysing = false;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    if (app.loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final states = app.baseline.states;
    if (!states.contains(_selectedState) && states.isNotEmpty) {
      _selectedState = states.first;
    }
    final perCapita = app.baseline.perCapitaLPerDay(_selectedState);
    final unresolved = app.unresolvedAlerts.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Water leakage detection'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: Colors.blue.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Real-data leakage scan',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(
                      'Compares state water production and consumption from data.gov.my to flag Non-Revenue Water hotspots.',
                      style: TextStyle(
                          fontSize: 13, color: Colors.blue.shade900)),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(46)),
                    icon: _analysing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.travel_explore),
                    label: const Text('Run leakage analysis'),
                    onPressed: _analysing ? null : () => _runAnalysis(app),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            tileColor: Colors.blueGrey.shade50,
            leading: const Icon(Icons.warning_amber),
            title: const Text('Alert queue'),
            subtitle: Text('$unresolved unresolved alert(s)'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const AlertQueueScreen())),
          ),
          const SizedBox(height: 8),
          ListTile(
            tileColor: Colors.blueGrey.shade50,
            leading: const Icon(Icons.description_outlined),
            title: const Text('Report history'),
            subtitle: Text('${app.reports.length} report(s)'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const ReportHistoryScreen())),
          ),
          const Divider(height: 32),
          const Text('Simulate a household reading (demo)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text('State: '),
              DropdownButton<String>(
                value: _selectedState,
                onChanged: (s) =>
                    setState(() => _selectedState = s ?? _selectedState),
                items: states
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
              ),
            ],
          ),
          Text(
              'Average domestic use: ${perCapita.toStringAsFixed(0)} L/person/day '
              '(${app.baseline.latestYear})',
              style: const TextStyle(fontSize: 13, color: Colors.black54)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: LeakScenario.values
                .map((s) => OutlinedButton(
                      onPressed: () => _simulate(app, s),
                      child: Text(s.label),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  Future<void> _runAnalysis(AppState app) async {
    setState(() => _analysing = true);
    try {
      final added = await app.runAnalysis();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(added == 0
            ? 'No new hotspots — all flagged states already in the queue.'
            : 'Flagged $added leaking state(s) from real data.'),
        backgroundColor: added == 0 ? Colors.blueGrey : Colors.red.shade600,
      ));
    } catch (_) {
      if (mounted) showNetworkErrorSnackBar(context);
    } finally {
      if (mounted) setState(() => _analysing = false);
    }
  }

  Future<void> _simulate(AppState app, LeakScenario scenario) async {
    try {
      final outcome = await app.simulate(scenario, _selectedState);
      if (!mounted) return;
      final message = outcome.anomalyRaised
          ? 'Alert raised: ${outcome.result.signature} '
              '(${outcome.result.severity}, ${outcome.result.ratio.toStringAsFixed(1)}× average)'
          : 'No anomaly: usage within normal range '
              '(${outcome.result.ratio.toStringAsFixed(1)}× average)';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(message),
        backgroundColor: outcome.anomalyRaised
            ? Colors.red.shade600
            : Colors.green.shade600,
      ));
    } catch (_) {
      if (mounted) showNetworkErrorSnackBar(context);
    }
  }
}
