import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../leakage/state/app_state.dart';
import '../services/electricity_baseline_service.dart';

class CompareUsageScreen extends StatefulWidget {
  const CompareUsageScreen({super.key});

  @override
  State<CompareUsageScreen> createState() => _CompareUsageScreenState();
}

class _CompareUsageScreenState extends State<CompareUsageScreen> {
  final _electricityBaseline = ElectricityBaselineService();
  final _waterController = TextEditingController();
  final _electricityController = TextEditingController();

  bool _loadingBaseline = true;
  String? _selectedState;
  int _householdSize = 4;

  _Comparison? _waterResult;
  _Comparison? _electricityResult;

  @override
  void initState() {
    super.initState();
    _electricityBaseline.load().then((_) {
      if (mounted) setState(() => _loadingBaseline = false);
    });
  }

  @override
  void dispose() {
    _waterController.dispose();
    _electricityController.dispose();
    super.dispose();
  }

  void _compare() {
    final state = _selectedState;
    if (state == null) return;

    final app = context.read<AppState>();
    final waterInput = double.tryParse(_waterController.text);
    final electricityInput = double.tryParse(_electricityController.text);

    setState(() {
      _waterResult = waterInput == null
          ? null
          : _Comparison(
              actual: waterInput,
              expected: app.baseline
                  .expectedHouseholdLPerDay(state, _householdSize),
              unit: 'L/day',
            );
      _electricityResult = electricityInput == null
          ? null
          : _Comparison(
              actual: electricityInput,
              expected: _electricityBaseline.expectedHouseholdKwhPerDay(
                  state, _householdSize),
              unit: 'kWh/day',
            );
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingBaseline) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final app = context.watch<AppState>();
    final states = app.baseline.states;
    _selectedState ??= states.isNotEmpty ? states.first : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Compare My Usage'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('See how your household compares to your state\'s '
              'average water and electricity usage.',
              style: TextStyle(fontSize: 13, color: Colors.black54)),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _selectedState,
            decoration: const InputDecoration(
              labelText: 'State',
              border: OutlineInputBorder(),
            ),
            items: states
                .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                .toList(),
            onChanged: (v) => setState(() => _selectedState = v),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text('Household Size: '),
              IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                onPressed: _householdSize > 1
                    ? () => setState(() => _householdSize--)
                    : null,
              ),
              Text('$_householdSize',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: () => setState(() => _householdSize++),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _waterController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Water usage (L/day)',
              prefixIcon: Icon(Icons.water_drop_outlined),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _electricityController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Electricity usage (kWh/day)',
              prefixIcon: Icon(Icons.bolt_outlined),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            style:
                FilledButton.styleFrom(minimumSize: const Size.fromHeight(46)),
            onPressed: _selectedState == null ? null : _compare,
            icon: const Icon(Icons.compare_arrows),
            label: const Text('Compare'),
          ),
          if (_waterResult != null) ...[
            const SizedBox(height: 20),
            _resultCard('Water', Icons.water_drop, Colors.blue, _waterResult!),
          ],
          if (_electricityResult != null) ...[
            const SizedBox(height: 12),
            _resultCard(
                'Electricity', Icons.bolt, Colors.amber, _electricityResult!),
          ],
        ],
      ),
    );
  }

  Widget _resultCard(
      String label, IconData icon, MaterialColor color, _Comparison result) {
    final statusColor = result.isAboveNormal
        ? Colors.red.shade600
        : result.isBelowNormal
            ? Colors.blue.shade600
            : Colors.green.shade600;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color.shade700),
                const SizedBox(width: 8),
                Text(label,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            Text(
                'You: ${result.actual.toStringAsFixed(1)} ${result.unit} · '
                'State average: ${result.expected.toStringAsFixed(1)} ${result.unit}',
                style: const TextStyle(fontSize: 13, color: Colors.black54)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: statusColor),
              ),
              child: Text(
                '${result.statusLabel} (${result.ratio.toStringAsFixed(1)}x average)',
                style: TextStyle(
                    color: statusColor, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Comparison {
  final double actual;
  final double expected;
  final String unit;

  const _Comparison(
      {required this.actual, required this.expected, required this.unit});

  double get ratio => expected == 0 ? 0 : actual / expected;
  bool get isAboveNormal => ratio > 1.3;
  bool get isBelowNormal => ratio < 0.8;
  String get statusLabel => isAboveNormal
      ? 'Above normal'
      : isBelowNormal
          ? 'Below normal'
          : 'Normal';
}
