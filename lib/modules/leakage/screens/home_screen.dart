import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../theme/tokens.dart';
import '../../auth/state/auth_state.dart';
import '../models/alert.dart';
import '../state/app_state.dart';
import 'alert_detail_screen.dart';
import 'alert_queue_screen.dart';
import 'report_history_screen.dart';

class HomeScreen extends StatelessWidget {
  final Utility utility;
  const HomeScreen({super.key, this.utility = Utility.water});

  bool get _isWater => utility == Utility.water;

  Color get _primary => AppColors.workerPrimary;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    if (app.loading) {
      return const Scaffold(
        backgroundColor: AppColors.canvas,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final unresolved = app.unresolvedFor(utility);
    final reports = app.reportsFor(utility);
    final highCount =
        unresolved.where((a) => a.severity == Severity.high).length;
    final mediumCount =
        unresolved.where((a) => a.severity == Severity.medium).length;
    final lowCount = unresolved.where((a) => a.severity == Severity.low).length;

    final latestAlert = unresolved.isNotEmpty ? unresolved.first : null;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          _header(context),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: _alertQueueCard(
              context,
              unresolved.length,
              highCount,
              mediumCount,
              lowCount,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: _reportHistoryCard(context, reports.length),
          ),
          if (latestAlert != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: _latestAlertCard(context, latestAlert),
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _primary,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'mySumber · WORKER',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                InkWell(
                  onTap: () => context.read<RoleState>().logout(),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.logout, color: Colors.white, size: 16),
                      SizedBox(width: 4),
                      Text('Logout',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              _isWater ? 'Water Monitoring' : 'Electricity Monitoring',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w700,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _alertQueueCard(
    BuildContext context,
    int total,
    int high,
    int medium,
    int low,
  ) {
    final resolved = total == 0;
    final accent = resolved ? AppColors.success : AppColors.critical;
    final background =
        resolved ? AppColors.successSurface : AppColors.criticalSurface;

    return AppCard(
      background: background,
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => AlertQueueScreen(utility: utility)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: accent,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.notifications_active_outlined,
                    color: Colors.white, size: 20),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: SectionLabel('ALERT QUEUE', color: AppColors.textPrimary),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('View',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 13)),
                    SizedBox(width: 2),
                    Icon(Icons.chevron_right,
                        color: Colors.white, size: 18),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '$total',
            style: TextStyle(
              fontSize: 44,
              fontWeight: FontWeight.w800,
              color: accent,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            resolved ? 'All alerts resolved' : 'Unresolved alerts need attention',
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (total > 0) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (high > 0)
                  Pill('$high high', color: AppColors.critical),
                if (medium > 0)
                  Pill('$medium medium', color: const Color(0xFFB45309),
                      background: AppColors.warningSurface),
                if (low > 0)
                  Pill('$low low',
                      color: AppColors.workerPrimary,
                      background: AppColors.workerSurface),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _reportHistoryCard(BuildContext context, int count) {
    return AppCard(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ReportHistoryScreen(utility: utility),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.workerSurface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.description_outlined,
                color: AppColors.workerPrimary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionLabel('REPORT HISTORY'),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('$count',
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          height: 1,
                          color: AppColors.textPrimary,
                        )),
                    const SizedBox(width: 8),
                    const Padding(
                      padding: EdgeInsets.only(bottom: 4),
                      child: Text(
                        'Total reports submitted',
                        style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.textTertiary),
        ],
      ),
    );
  }

  Widget _latestAlertCard(BuildContext context, Alert alert) {
    final sev = alert.severity;
    Color sevColor;
    Color sevBg;
    String sevLabel;
    if (sev == Severity.high) {
      sevColor = AppColors.critical;
      sevBg = AppColors.criticalSurface;
      sevLabel = 'High Severity';
    } else if (sev == Severity.medium) {
      sevColor = const Color(0xFFB45309);
      sevBg = AppColors.warningSurface;
      sevLabel = 'Medium Severity';
    } else {
      sevColor = AppColors.workerPrimary;
      sevBg = AppColors.workerSurface;
      sevLabel = 'Low Severity';
    }

    final typeLabel = alert.alertType == AlertType.household
        ? 'Household'
        : alert.alertType == AlertType.nrwHotspot
            ? 'NRW Hotspot'
            : alert.alertType == AlertType.electricityHotspot
                ? 'Electricity Loss'
                : 'Tampering';

    return AppCard(
      onTap: alert.id == null
          ? null
          : () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => AlertDetailScreen(alertId: alert.id!),
                ),
              ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.schedule, color: AppColors.warning, size: 16),
              SizedBox(width: 6),
              SectionLabel('LATEST ALERT'),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      alert.title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Flagged ${DateFormat('d MMM').format(alert.detectedAt)} · $typeLabel',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Pill(sevLabel, color: sevColor, background: sevBg),
            ],
          ),
        ],
      ),
    );
  }
}
