import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/alert.dart';
import '../state/app_state.dart';
import 'alert_detail_screen.dart';
import 'style.dart';

class AlertQueueScreen extends StatefulWidget {
  const AlertQueueScreen({super.key});

  @override
  State<AlertQueueScreen> createState() => _AlertQueueScreenState();
}

class _AlertQueueScreenState extends State<AlertQueueScreen> {
  final _search = TextEditingController();
  String _severity = 'all';
  String _status = 'all';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final query = _search.text.trim().toLowerCase();

    List<Alert> filter(List<Alert> source) {
      return source.where((a) {
        if (query.isNotEmpty && !a.state.toLowerCase().contains(query)) {
          return false;
        }
        if (_severity != 'all' && a.severity != _severity) return false;
        if (_status != 'all' && a.status != _status) return false;
        return true;
      }).toList();
    }

    final unresolved = filter(app.unresolvedAlerts);
    final resolved = filter(app.resolvedAlerts);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Leakage alerts'),
          backgroundColor: Colors.blue.shade700,
          foregroundColor: Colors.white,
          bottom: TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: 'Unresolved · ${app.unresolvedAlerts.length}'),
              Tab(text: 'Resolved · ${app.resolvedAlerts.length}'),
            ],
          ),
        ),
        body: Column(
          children: [
            _filters(app),
            Expanded(
              child: TabBarView(
                children: [
                  _list(unresolved, 'No unresolved alerts.'),
                  _list(resolved, 'No resolved alerts yet.'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filters(AppState app) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      child: Column(
        children: [
          TextField(
            controller: _search,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Search by state',
              prefixIcon: const Icon(Icons.search),
              isDense: true,
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _dropdown('Severity', _severity, {
                  'all': 'All severity',
                  Severity.high: 'High',
                  Severity.medium: 'Medium',
                  Severity.low: 'Low',
                }, (v) => setState(() => _severity = v)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _dropdown('Status', _status, {
                  'all': 'All status',
                  AlertStatus.pending: 'Pending',
                  AlertStatus.investigating: 'Investigating',
                  AlertStatus.notFixed: 'Not fixed',
                  AlertStatus.resolved: 'Resolved',
                }, (v) => setState(() => _status = v)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _dropdown(String hint, String value, Map<String, String> options,
      ValueChanged<String> onChanged) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      isDense: true,
      decoration: InputDecoration(
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
      ),
      items: options.entries
          .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
          .toList(),
      onChanged: (v) => onChanged(v ?? 'all'),
    );
  }

  Widget _list(List<Alert> alerts, String empty) {
    if (alerts.isEmpty) {
      return Center(child: Text(empty));
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
      itemCount: alerts.length,
      itemBuilder: (context, index) => _AlertCard(alert: alerts[index]),
    );
  }
}

class _AlertCard extends StatelessWidget {
  final Alert alert;
  const _AlertCard({required this.alert});

  @override
  Widget build(BuildContext context) {
    final color = severityColor(alert.severity);
    final metric = alert.isNrw
        ? '${alert.lossPct!.toStringAsFixed(1)}%'
        : '${alert.ratio.toStringAsFixed(1)}×';
    final unit =
        alert.isNrw ? 'of treated water lost' : 'of the state average';
    final typeLabel = alert.isNrw ? 'NRW hotspot' : 'Household';
    final date = DateFormat('d MMM').format(alert.detectedAt);
    final time = alert.isNrw
        ? 'Flagged $date · ${alert.dataYear} data'
        : 'Flagged $date';

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => AlertDetailScreen(alertId: alert.id!))),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                        alert.severity == Severity.high
                            ? Icons.warning_amber
                            : Icons.error_outline,
                        color: color),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(alert.title,
                            style: const TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Row(children: [
                          Icon(alert.isNrw ? Icons.place_outlined : Icons.home_outlined,
                              size: 13, color: Colors.black45),
                          const SizedBox(width: 4),
                          Text('$typeLabel · ${Severity.label(alert.severity)}',
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.black54)),
                        ]),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.black38),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(metric,
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.w600)),
                  const SizedBox(width: 7),
                  Text(unit,
                      style: const TextStyle(
                          fontSize: 12, color: Colors.black54)),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  pill(AlertStatus.label(alert.status),
                      statusColor(alert.status)),
                  const Spacer(),
                  Text(time,
                      style:
                          const TextStyle(fontSize: 12, color: Colors.black45)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
