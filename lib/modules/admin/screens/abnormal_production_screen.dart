import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../electricity/models/electricity_models.dart';
import '../../leakage/models/alert.dart';
import '../../leakage/screens/network_error.dart';
import '../../leakage/screens/style.dart';
import '../../leakage/services/nrw_service.dart';
import '../../leakage/state/app_state.dart';

/// Admin screen: generates alerts from real data.gov.my analysis.
///   - Water: per-state production vs consumption (NRW)
///   - Electricity: per-state supply vs consumption
///   - Electricity: national tampering spikes (z-score months)
/// The false-positive gate (pending ↔ faults) lives on the Oversight screen.
class AbnormalProductionScreen extends StatefulWidget {
  const AbnormalProductionScreen({super.key});

  @override
  State<AbnormalProductionScreen> createState() =>
      _AbnormalProductionScreenState();
}

class _AbnormalProductionScreenState extends State<AbnormalProductionScreen> {
  String? _busyKey;

  Future<void> _run(
      String busyKey, String label, Future<bool> Function() action) async {
    setState(() => _busyKey = busyKey);
    try {
      final reported = await action();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(reported
            ? 'Reported $label to the worker queue.'
            : '$label was already reported.'),
        backgroundColor: reported ? Colors.red.shade600 : Colors.blueGrey,
      ));
    } catch (_) {
      if (mounted) showNetworkErrorSnackBar(context);
    } finally {
      if (mounted) setState(() => _busyKey = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    if (app.loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final water = app.nrw.analyse();
    final electricity = app.electricityLoss.analyse();
    final tampering = app.tamperingCandidates
      ..sort((a, b) => b.date.compareTo(a.date));

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Abnormal Production'),
          backgroundColor: Colors.teal.shade700,
          foregroundColor: Colors.white,
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: 'Water'),
              Tab(text: 'Electricity'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _waterTab(app, water),
            _electricityTab(app, electricity, tampering),
          ],
        ),
      ),
    );
  }

  Widget _waterTab(AppState app, List<NrwResult> water) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _sectionHeader('Production vs. Consumption',
            'States where treated water production doesn\'t match billed '
                'consumption (real data.gov.my figures).'),
        if (water.isEmpty)
          _emptyCard('No abnormal water states detected.')
        else
          ...water.map((r) => _lossCard(
                result: r,
                reported: app.reportedWaterStates.contains(r.state),
                unit: 'MLD',
                busyKey: 'W-${r.state}',
                onReport: () =>
                    _run('W-${r.state}', r.state, () => app.reportAbnormalState(r)),
              )),
      ],
    );
  }

  Widget _electricityTab(AppState app, List<NrwResult> electricity,
      List<ElectricityRecord> tampering) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _sectionHeader('Supply vs. Consumption',
            'States where electricity supply exceeds metered consumption by '
                'more than the national average.'),
        if (electricity.isEmpty)
          _emptyCard('No abnormal electricity states detected.')
        else
          ...electricity.map((r) => _lossCard(
                result: r,
                reported: app.reportedElectricityStates.contains(r.state),
                unit: 'GWh',
                busyKey: 'E-${r.state}',
                onReport: () => _run(
                    'E-${r.state}', r.state, () => app.reportElectricityState(r)),
              )),
        const Divider(height: 40),
        _sectionHeader('Tampering Spikes',
            'Months where national electricity losses spiked abnormally '
                '(z-score) versus the surrounding period.'),
        if (tampering.isEmpty)
          _emptyCard('No tampering spikes detected.')
        else
          ...tampering.map((rec) {
            final key = AppState.monthKey(rec.date);
            return _tamperingCard(
              record: rec,
              reported: app.reportedTamperingKeys.contains(key),
              onReport: () => _run('T-$key', DateFormat('MMM y').format(rec.date),
                  () => app.reportElectricityTampering(rec)),
            );
          }),
      ],
    );
  }

  Widget _sectionHeader(String title, String subtitle) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 4),
            Text(subtitle,
                style: const TextStyle(fontSize: 13, color: Colors.black54)),
          ],
        ),
      );

  Widget _emptyCard(String text) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(text, style: const TextStyle(color: Colors.black54)),
        ),
      );

  Widget _lossCard({
    required NrwResult result,
    required bool reported,
    required String unit,
    required String busyKey,
    required VoidCallback onReport,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(result.state,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600)),
                ),
                pill(Severity.label(result.severity),
                    severityColor(result.severity)),
              ],
            ),
            const SizedBox(height: 8),
            Text(
                'Produced ${result.producedMld.round()} $unit · '
                'Consumed ${result.billedMld.round()} $unit · '
                'Loss ${result.lossPct.toStringAsFixed(1)}% (${result.year})',
                style: const TextStyle(fontSize: 13, color: Colors.black54)),
            const SizedBox(height: 12),
            _reportButton(reported, busyKey, onReport),
          ],
        ),
      ),
    );
  }

  Widget _tamperingCard({
    required ElectricityRecord record,
    required bool reported,
    required VoidCallback onReport,
  }) {
    final lossPct =
        record.supply == 0 ? 0.0 : record.losses / record.supply * 100;
    final severity = lossPct > 10
        ? Severity.high
        : lossPct > 6
            ? Severity.medium
            : Severity.low;
    final month = DateFormat('MMMM y').format(record.date);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(month,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600)),
                ),
                pill(Severity.label(severity), severityColor(severity)),
              ],
            ),
            const SizedBox(height: 8),
            Text(
                'National · Losses ${record.losses.round()} GWh · '
                '${lossPct.toStringAsFixed(1)}% of supply',
                style: const TextStyle(fontSize: 13, color: Colors.black54)),
            const SizedBox(height: 12),
            _reportButton(reported, 'T-${AppState.monthKey(record.date)}',
                onReport),
          ],
        ),
      ),
    );
  }

  Widget _reportButton(bool reported, String busyKey, VoidCallback onReport) {
    final busy = _busyKey == busyKey;
    return SizedBox(
      width: double.infinity,
      child: reported
          ? OutlinedButton.icon(
              onPressed: null,
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Already Reported'),
            )
          : FilledButton.icon(
              onPressed: busy ? null : onReport,
              icon: busy
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.flag_outlined),
              label: const Text('Report to Worker Queue'),
            ),
    );
  }
}
