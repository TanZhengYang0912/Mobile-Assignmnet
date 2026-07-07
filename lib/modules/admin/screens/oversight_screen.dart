import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../leakage/models/alert.dart';
import '../../leakage/models/report.dart';
import '../../leakage/screens/report_view_screen.dart';
import '../../leakage/screens/style.dart';
import '../../leakage/state/app_state.dart';
import 'admin_alert_detail_screen.dart';

/// Admin oversight of the worker's alert queue and report history.
/// Alerts are grouped by status (Pending/Ongoing/Solved/Faults) and can be
/// filtered by utility; tapping one opens the read-only detail + gate.
/// Reports are filterable by utility, outcome, and state.
class OversightScreen extends StatefulWidget {
  const OversightScreen({super.key});

  @override
  State<OversightScreen> createState() => _OversightScreenState();
}

class _OversightScreenState extends State<OversightScreen> {
  Utility? _alertUtility;
  Utility? _reportUtility;
  String? _reportOutcome;
  String? _reportState;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Oversight'),
          backgroundColor: Colors.teal.shade700,
          foregroundColor: Colors.white,
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: 'Alert Queue'),
              Tab(text: 'Reports'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _alertQueueTab(app),
            _reportsTab(app),
          ],
        ),
      ),
    );
  }

  // --- Alert Queue tab ---

  Widget _alertQueueTab(AppState app) {
    final pending = app.pendingAlerts(_alertUtility);
    final ongoing = app.ongoingAlerts(_alertUtility);
    final solved = app.solvedAlerts(_alertUtility);
    final faults = app.faultAlerts(_alertUtility);

    return DefaultTabController(
      length: 4,
      child: Column(
        children: [
          _utilityToggle(_alertUtility, (u) => setState(() => _alertUtility = u)),
          TabBar(
            isScrollable: true,
            labelColor: Colors.teal.shade700,
            unselectedLabelColor: Colors.black54,
            indicatorColor: Colors.teal.shade700,
            tabs: [
              Tab(text: 'Pending (${pending.length})'),
              Tab(text: 'Ongoing (${ongoing.length})'),
              Tab(text: 'Solved (${solved.length})'),
              Tab(text: 'Faults (${faults.length})'),
            ],
          ),
          const Divider(height: 1),
          Expanded(
            child: TabBarView(
              children: [
                _alertList(pending, 'No pending alerts.'),
                _alertList(ongoing, 'No ongoing investigations.'),
                _alertList(solved, 'No solved alerts yet.'),
                _alertList(faults, 'No faults yet.'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _alertList(List<Alert> alerts, String emptyMessage) {
    if (alerts.isEmpty) {
      return Center(child: Text(emptyMessage));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: alerts.length,
      itemBuilder: (context, index) => _compactAlertCard(context, alerts[index]),
    );
  }

  Widget _compactAlertCard(BuildContext context, Alert alert) {
    final date = DateFormat('d MMM').format(alert.detectedAt);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => AdminAlertDetailScreen(alertId: alert.id!))),
        leading: Icon(
          alert.isElectricity ? Icons.bolt_outlined : Icons.water_drop_outlined,
          color: severityColor(alert.severity),
        ),
        title: Text(alert.title,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('Flagged $date'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            pill(Severity.label(alert.severity), severityColor(alert.severity)),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, color: Colors.black38),
          ],
        ),
      ),
    );
  }

  // --- Reports tab ---

  Widget _reportsTab(AppState app) {
    final states = app.alerts.map((a) => a.state).toSet().toList()..sort();
    final reports = app.reportsFiltered(
      utility: _reportUtility,
      outcome: _reportOutcome,
      state: _reportState,
    );

    return Column(
      children: [
        _reportFilters(states),
        Expanded(
          child: reports.isEmpty
              ? const Center(child: Text('No reports match these filters.'))
              : _reportList(app, reports),
        ),
      ],
    );
  }

  Widget _reportFilters(List<String> states) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
      child: Column(
        children: [
          _utilityToggle(_reportUtility, (u) => setState(() => _reportUtility = u)),
          const SizedBox(height: 8),
          Row(
            children: [
              _choiceChip('All', _reportOutcome == null,
                  () => setState(() => _reportOutcome = null)),
              const SizedBox(width: 8),
              _choiceChip('Fixed', _reportOutcome == ReportOutcome.fixed,
                  () => setState(() => _reportOutcome = ReportOutcome.fixed)),
              const SizedBox(width: 8),
              _choiceChip(
                  'Not Fixed',
                  _reportOutcome == ReportOutcome.notFixed,
                  () => setState(() => _reportOutcome = ReportOutcome.notFixed)),
            ],
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String?>(
            initialValue: _reportState,
            isDense: true,
            decoration: const InputDecoration(
              labelText: 'State',
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(),
            ),
            items: [
              const DropdownMenuItem(value: null, child: Text('All States')),
              ...states.map((s) => DropdownMenuItem(value: s, child: Text(s))),
            ],
            onChanged: (v) => setState(() => _reportState = v),
          ),
        ],
      ),
    );
  }

  Widget _reportList(AppState app, List<Report> reports) {
    final dateFormat = DateFormat('d MMM y, HH:mm');
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: reports.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final report = reports[index];
        final matches = app.alerts.where((a) => a.id == report.alertId);
        final alertTitle =
            matches.isEmpty ? 'Alert #${report.alertId}' : matches.first.title;
        return ListTile(
          leading: Icon(
            report.isFixed ? Icons.check_circle_outline : Icons.build_outlined,
            color: report.isFixed ? Colors.green : Colors.orange,
          ),
          title: Text('$alertTitle · ${ReportOutcome.label(report.outcome)}'),
          subtitle: Text(
            '${report.findings.isEmpty ? "No findings" : report.findings}\n'
            'Updated ${dateFormat.format(report.updatedAt)}',
          ),
          isThreeLine: true,
          onTap: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => ReportViewScreen(report: report))),
        );
      },
    );
  }

  // --- Shared controls ---

  Widget _utilityToggle(Utility? current, ValueChanged<Utility?> onChanged) {
    return Row(
      children: [
        _choiceChip('All', current == null, () => onChanged(null)),
        const SizedBox(width: 8),
        _choiceChip('Water', current == Utility.water,
            () => onChanged(Utility.water), icon: Icons.water_drop),
        const SizedBox(width: 8),
        _choiceChip('Electricity', current == Utility.electricity,
            () => onChanged(Utility.electricity), icon: Icons.bolt),
      ],
    );
  }

  Widget _choiceChip(String label, bool selected, VoidCallback onTap,
      {IconData? icon}) {
    return ChoiceChip(
      label: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null) ...[
          Icon(icon, size: 14, color: selected ? Colors.white : Colors.blueGrey),
          const SizedBox(width: 4),
        ],
        Text(label),
      ]),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: Colors.teal.shade600,
      labelStyle: TextStyle(
        color: selected ? Colors.white : Colors.blueGrey,
        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
      ),
      backgroundColor: Colors.white,
      side: BorderSide(color: selected ? Colors.transparent : Colors.grey.shade300),
      showCheckmark: false,
    );
  }
}
