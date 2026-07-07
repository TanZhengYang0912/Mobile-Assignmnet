import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../leakage/screens/network_error.dart';
import '../../leakage/services/simulation_service.dart';
import '../../leakage/state/app_state.dart';

class ReportProblemScreen extends StatefulWidget {
  const ReportProblemScreen({super.key});

  @override
  State<ReportProblemScreen> createState() => _ReportProblemScreenState();
}

class _ReportProblemScreenState extends State<ReportProblemScreen> {
  String _selectedState = 'Selangor';

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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Report A Problem'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Report A Household Water Problem',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 4),
          const Text(
              'Tell us what\'s happening with your water usage. We\'ll check '
              'it against your state\'s average and send it to our team if '
              'it looks abnormal.',
              style: TextStyle(fontSize: 13, color: Colors.black54)),
          const SizedBox(height: 16),
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
          const SizedBox(height: 16),
          const Text('What Best Describes the Problem?',
              style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: LeakScenario.values
                .map((s) => OutlinedButton(
                      onPressed: () => _submit(app, s),
                      child: Text(s.label),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  Future<void> _submit(AppState app, LeakScenario scenario) async {
    try {
      final outcome = await app.simulate(scenario, _selectedState);
      if (!mounted) return;
      final message = outcome.anomalyRaised
          ? 'Thanks — we\'ve flagged this as ${outcome.result.signature} '
              '(${outcome.result.severity}) and sent it to our team.'
          : 'Your usage looks within the normal range '
              '(${outcome.result.ratio.toStringAsFixed(1)}x average). No report needed.';
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
