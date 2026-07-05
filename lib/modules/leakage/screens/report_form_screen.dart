import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/alert.dart';
import '../models/report.dart';
import '../state/app_state.dart';

class ReportFormScreen extends StatefulWidget {
  final Alert alert;
  final Report? existing;
  const ReportFormScreen({super.key, required this.alert, this.existing});

  @override
  State<ReportFormScreen> createState() => _ReportFormScreenState();
}

class _ReportFormScreenState extends State<ReportFormScreen> {
  late final TextEditingController _findings;
  late final TextEditingController _action;
  String? _outcome;

  @override
  void initState() {
    super.initState();
    _findings = TextEditingController(text: widget.existing?.findings ?? '');
    _action = TextEditingController(text: widget.existing?.actionTaken ?? '');
    _outcome = widget.existing?.outcome;
  }

  @override
  void dispose() {
    _findings.dispose();
    _action.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppState>();
    final started = DateFormat('d MMM y, HH:mm').format(
        widget.existing?.createdAt ?? DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Investigation report'),
        actions: [
          if (widget.existing?.id != null)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Delete report',
              onPressed: () => _delete(app),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('${app.workerName} · ${widget.existing == null ? "started" : "opened"} $started',
              style: const TextStyle(fontSize: 12, color: Colors.black54)),
          const SizedBox(height: 16),
          const Text('Findings', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          TextField(
            controller: _findings,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'What did you find on site?',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Action taken',
              style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          TextField(
            controller: _action,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'What did you do about it?',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Outcome', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
                child: _outcomeButton(ReportOutcome.fixed, 'Fixed',
                    Icons.check, Colors.green)),
            const SizedBox(width: 10),
            Expanded(
                child: _outcomeButton(ReportOutcome.notFixed, 'Not fixed',
                    Icons.warning_amber, Colors.orange)),
          ]),
          const SizedBox(height: 8),
          const Text(
            'Outcome sets the status — Fixed moves it to Resolved, Not fixed keeps it in the queue for a follow-up visit.',
            style: TextStyle(fontSize: 12, color: Colors.black54),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(46)),
            icon: const Icon(Icons.save_outlined),
            label: const Text('Save report'),
            onPressed: () => _save(app),
          ),
        ],
      ),
    );
  }

  Widget _outcomeButton(
      String value, String label, IconData icon, Color color) {
    final selected = _outcome == value;
    return OutlinedButton.icon(
      onPressed: () => setState(() => _outcome = value),
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(46),
        foregroundColor: selected ? color : Colors.black54,
        backgroundColor: selected ? color.withValues(alpha: 0.12) : null,
        side: BorderSide(color: selected ? color : Colors.black26),
      ),
    );
  }

  Future<void> _save(AppState app) async {
    if (_outcome == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Select an outcome before saving.')));
      return;
    }
    final now = DateTime.now();
    final report = (widget.existing ??
            Report(
              alertId: widget.alert.id!,
              workerName: app.workerName,
              findings: '',
              actionTaken: '',
              outcome: _outcome!,
              createdAt: now,
              updatedAt: now,
            ))
        .copyWith(
      findings: _findings.text.trim(),
      actionTaken: _action.text.trim(),
      outcome: _outcome,
      updatedAt: now,
    );
    await app.saveReport(report);
    await app.updateAlertStatus(
        widget.alert.id!,
        _outcome == ReportOutcome.fixed
            ? AlertStatus.resolved
            : AlertStatus.notFixed);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete(AppState app) async {
    await app.deleteReport(widget.existing!.id!);
    if (mounted) Navigator.of(context).pop();
  }
}
