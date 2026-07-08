import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../theme/tokens.dart';
import '../../auth/state/auth_state.dart';
import '../../electricity/models/electricity_models.dart';
import '../../leakage/models/alert.dart';
import '../../leakage/screens/network_error.dart';
import '../../leakage/services/nrw_service.dart';
import '../../leakage/state/app_state.dart';

class AbnormalProductionScreen extends StatefulWidget {
  const AbnormalProductionScreen({super.key});

  @override
  State<AbnormalProductionScreen> createState() =>
      _AbnormalProductionScreenState();
}

class _AbnormalProductionScreenState extends State<AbnormalProductionScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;
  String? _busyKey;
  int _waterPage = 0;
  int _elecPage = 0;

  static const _perPage = 5;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _tab.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

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
        backgroundColor:
            reported ? AppColors.adminPrimary : Colors.blueGrey,
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
      return const Scaffold(
          body: Center(child: CircularProgressIndicator()));
    }

    final water = app.nrw.analyse();
    final electricity = app.electricityLoss.analyse();
    final tampering = app.tamperingCandidates
      ..sort((a, b) => b.date.compareTo(a.date));

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: Column(
        children: [
          _buildHeader(context),
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: [
                _waterTab(app, water),
                _electricityTab(app, electricity, tampering),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.adminPrimary,
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.of(context).padding.top + 16,
        20,
        20,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'mySumber · ADMIN',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Abnormal Production',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
          Material(
            color: Colors.white.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(999),
            child: InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: () => context.read<RoleState>().logout(),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.logout, size: 15, color: Colors.white),
                    SizedBox(width: 6),
                    Text(
                      'Logout',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tab,
        labelColor: AppColors.adminPrimary,
        unselectedLabelColor: AppColors.textSecondary,
        labelStyle:
            const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        unselectedLabelStyle:
            const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
        indicatorColor: AppColors.adminPrimary,
        indicatorWeight: 2.5,
        dividerColor: AppColors.divider,
        tabs: const [
          Tab(text: 'Water'),
          Tab(text: 'Electricity'),
        ],
      ),
    );
  }

  Widget _waterTab(AppState app, List<NrwResult> water) {
    final totalPages = (water.length / _perPage).ceil().clamp(1, 9999);
    final page = _waterPage.clamp(0, totalPages - 1);
    final pageItems =
        water.skip(page * _perPage).take(_perPage).toList();

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            children: [
              _sectionDescription(
                'Production vs. Consumption',
                "States where treated water production doesn't match "
                    'billed consumption (real data.gov.my figures).',
              ),
              const SizedBox(height: 16),
              if (water.isEmpty)
                _emptyCard('No abnormal water states detected.')
              else
                ...pageItems.map((r) => _lossCard(
                      result: r,
                      reported:
                          app.reportedWaterStates.contains(r.state),
                      unit: 'MLD',
                      busyKey: 'W-${r.state}',
                      onReport: () => _run('W-${r.state}', r.state,
                          () => app.reportAbnormalState(r)),
                    )),
            ],
          ),
        ),
        if (water.length > _perPage)
          _paginationBar(
            page: page,
            totalPages: totalPages,
            onPrev: page > 0
                ? () => setState(() => _waterPage = page - 1)
                : null,
            onNext: page < totalPages - 1
                ? () => setState(() => _waterPage = page + 1)
                : null,
          ),
      ],
    );
  }

  Widget _electricityTab(AppState app, List<NrwResult> electricity,
      List<ElectricityRecord> tampering) {
    final totalPages =
        (electricity.length / _perPage).ceil().clamp(1, 9999);
    final page = _elecPage.clamp(0, totalPages - 1);
    final pageItems =
        electricity.skip(page * _perPage).take(_perPage).toList();

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            children: [
              _sectionDescription(
                'Supply vs. Consumption',
                'States where electricity supply exceeds metered '
                    'consumption by more than the national average.',
              ),
              const SizedBox(height: 16),
              if (electricity.isEmpty)
                _emptyCard('No abnormal electricity states detected.')
              else
                ...pageItems.map((r) => _lossCard(
                      result: r,
                      reported: app.reportedElectricityStates
                          .contains(r.state),
                      unit: 'GWh',
                      busyKey: 'E-${r.state}',
                      onReport: () => _run('E-${r.state}', r.state,
                          () => app.reportElectricityState(r)),
                    )),
              if (tampering.isNotEmpty) ...[
                const SizedBox(height: 4),
                const Divider(),
                const SizedBox(height: 12),
                _sectionDescription(
                  'Tampering Spikes',
                  'Months where national electricity losses spiked '
                      'abnormally (z-score) versus the surrounding period.',
                ),
                const SizedBox(height: 16),
                ...tampering.map((rec) {
                  final key = AppState.monthKey(rec.date);
                  return _tamperingCard(
                    record: rec,
                    reported:
                        app.reportedTamperingKeys.contains(key),
                    onReport: () => _run(
                        'T-$key',
                        DateFormat('MMM y').format(rec.date),
                        () => app.reportElectricityTampering(rec)),
                  );
                }),
              ],
            ],
          ),
        ),
        if (electricity.length > _perPage)
          _paginationBar(
            page: page,
            totalPages: totalPages,
            onPrev: page > 0
                ? () => setState(() => _elecPage = page - 1)
                : null,
            onNext: page < totalPages - 1
                ? () => setState(() => _elecPage = page + 1)
                : null,
          ),
      ],
    );
  }

  Widget _sectionDescription(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary)),
        const SizedBox(height: 4),
        Text(subtitle,
            style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.5)),
      ],
    );
  }

  Widget _emptyCard(String text) => AppCard(
        child: Text(text,
            style: const TextStyle(color: AppColors.textSecondary)),
      );

  Widget _lossCard({
    required NrwResult result,
    required bool reported,
    required String unit,
    required String busyKey,
    required VoidCallback onReport,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(result.state,
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary)),
                ),
                const SizedBox(width: 8),
                _severityBadge(result.severity),
              ],
            ),
            const SizedBox(height: 6),
            Text.rich(
              TextSpan(
                style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.5),
                children: [
                  TextSpan(
                    text: 'Produced ${result.producedMld.round()} $unit · '
                        'Consumed ${result.billedMld.round()} $unit · Loss ',
                  ),
                  TextSpan(
                    text: '${result.lossPct.toStringAsFixed(1)}%',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary),
                  ),
                  TextSpan(text: ' (${result.year})'),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _actionButton(reported, busyKey, onReport),
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
    final key = AppState.monthKey(record.date);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(DateFormat('MMMM y').format(record.date),
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary)),
                ),
                const SizedBox(width: 8),
                _severityBadge(severity),
              ],
            ),
            const SizedBox(height: 6),
            Text.rich(
              TextSpan(
                style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.5),
                children: [
                  TextSpan(
                      text:
                          'National · Losses ${record.losses.round()} GWh · '),
                  TextSpan(
                    text: '${lossPct.toStringAsFixed(1)}%',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary),
                  ),
                  const TextSpan(text: ' of supply'),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _actionButton(reported, 'T-$key', onReport),
          ],
        ),
      ),
    );
  }

  Widget _severityBadge(String severity) {
    final Color color;
    final Color bg;
    final String label;
    if (severity == Severity.high) {
      color = AppColors.critical;
      bg = AppColors.criticalSurface;
      label = 'High Severity';
    } else if (severity == Severity.medium) {
      color = AppColors.warning;
      bg = AppColors.warningSurface;
      label = 'Medium Severity';
    } else {
      color = AppColors.success;
      bg = AppColors.successSurface;
      label = 'Low Severity';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label,
          style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600)),
    );
  }

  Widget _actionButton(
      bool reported, String busyKey, VoidCallback onReport) {
    final busy = _busyKey == busyKey;
    if (reported) {
      return SizedBox(
        width: double.infinity,
        height: 44,
        child: OutlinedButton.icon(
          onPressed: null,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.textSecondary,
            disabledForegroundColor: AppColors.textSecondary,
            side: const BorderSide(color: AppColors.divider),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
          icon: const Icon(Icons.check_circle_outline, size: 18),
          label: const Text('Already Reported'),
        ),
      );
    }
    return SizedBox(
      width: double.infinity,
      height: 44,
      child: FilledButton.icon(
        onPressed: busy ? null : onReport,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.adminPrimary,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
        ),
        icon: busy
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white))
            : const Icon(Icons.notifications_outlined, size: 18),
        label: const Text('Report to Worker Queue'),
      ),
    );
  }

  Widget _paginationBar({
    required int page,
    required int totalPages,
    required VoidCallback? onPrev,
    required VoidCallback? onNext,
  }) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: onPrev,
            icon: const Icon(Icons.chevron_left, size: 22),
            style: IconButton.styleFrom(
              foregroundColor: onPrev != null
                  ? AppColors.adminPrimary
                  : AppColors.textTertiary,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Page ${page + 1} of $totalPages',
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: onNext,
            icon: const Icon(Icons.chevron_right, size: 22),
            style: IconButton.styleFrom(
              foregroundColor: onNext != null
                  ? AppColors.adminPrimary
                  : AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}
