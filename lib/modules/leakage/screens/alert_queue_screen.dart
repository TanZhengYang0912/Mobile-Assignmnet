import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/alert.dart';
import '../state/app_state.dart';
import 'alert_detail_screen.dart';
import 'style.dart';

class AlertQueueScreen extends StatefulWidget {
  final Utility utility;
  const AlertQueueScreen({super.key, this.utility = Utility.water});

  @override
  State<AlertQueueScreen> createState() => _AlertQueueScreenState();
}

class _AlertQueueScreenState extends State<AlertQueueScreen>
    with SingleTickerProviderStateMixin {
  final _search = TextEditingController();
  String _severity = 'all';
  String _status = 'all';
  late final TabController _tabController;
  int _lastIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this)
      ..addListener(_onTabChanged);
  }

  void _onTabChanged() {
    if (_tabController.index == _lastIndex) return;
    _lastIndex = _tabController.index;
    setState(() {
      _search.clear();
      _severity = 'all';
      _status = 'all';
    });
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final query = _search.text.trim().toLowerCase();
    final isWater = widget.utility == Utility.water;
    final color = isWater ? Colors.blue.shade700 : Colors.amber.shade700;
    final title = isWater ? 'Water Alerts' : 'Electricity Alerts';

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

    final unresolvedAll = app.unresolvedFor(widget.utility);
    final resolvedAll = app.resolvedFor(widget.utility);
    final unresolved = filter(unresolvedAll);
    final resolved = filter(resolvedAll);

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: color,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: [
            Tab(text: 'Unresolved · ${unresolvedAll.length}'),
            Tab(text: 'Resolved · ${resolvedAll.length}'),
          ],
        ),
      ),
      body: Column(
        children: [
          _filters(app),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _list(unresolved, 'No unresolved alerts.'),
                _list(resolved, 'No resolved alerts yet.'),
              ],
            ),
          ),
        ],
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
                  'all': 'All Severity',
                  Severity.high: 'High',
                  Severity.medium: 'Medium',
                  Severity.low: 'Low',
                }, (v) => setState(() => _severity = v)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _dropdown('Status', _status, {
                  'all': 'All Status',
                  AlertStatus.pending: 'Pending',
                  AlertStatus.investigating: 'Investigating',
                  AlertStatus.notFixed: 'Not Fixed',
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

  String _metricUnit() {
    switch (alert.alertType) {
      case AlertType.nrwHotspot:
        return 'of treated water lost';
      case AlertType.electricityHotspot:
        return 'of supply unaccounted for';
      case AlertType.electricityTampering:
        return 'national loss';
      default:
        return 'of the state average';
    }
  }

  String _typeLabel() {
    switch (alert.alertType) {
      case AlertType.nrwHotspot:
        return 'NRW Hotspot';
      case AlertType.electricityHotspot:
        return 'Electricity Loss';
      case AlertType.electricityTampering:
        return 'Tampering Spike';
      default:
        return 'Household';
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = severityColor(alert.severity);
    final usesLossPct = alert.lossPct != null;
    final metric = usesLossPct
        ? '${alert.lossPct!.toStringAsFixed(1)}%'
        : '${alert.ratio.toStringAsFixed(1)}×';
    final unit = _metricUnit();
    final typeLabel = _typeLabel();
    final date = DateFormat('d MMM').format(alert.detectedAt);
    final time = alert.dataYear != null
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
                          Icon(
                              alert.alertType == AlertType.household
                                  ? Icons.home_outlined
                                  : alert.isElectricity
                                      ? Icons.bolt_outlined
                                      : Icons.place_outlined,
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
