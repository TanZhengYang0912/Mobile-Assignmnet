import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../theme/tokens.dart';
import '../../auth/state/auth_state.dart';
import '../../leakage/state/app_state.dart';
import 'my_reports_screen.dart';

class CustomerHomeScreen extends StatelessWidget {
  final VoidCallback? onUsageTap;
  const CustomerHomeScreen({super.key, this.onUsageTap});

  @override
  Widget build(BuildContext context) {
    final role = context.watch<RoleState>();
    final app = context.watch<AppState>();
    final email = role.email ?? '';
    final displayName = email.isEmpty
        ? 'there'
        : email.split('@').first.replaceAll('.', ' ').replaceAllMapped(
              RegExp(r'\b\w'),
              (m) => m.group(0)!.toUpperCase(),
            );

    final resolved = app.solvedAlerts();
    final reviewedIds = app.reviewedAlertIds(email);
    final pendingCount =
        resolved.where((a) => !reviewedIds.contains(a.id)).length;
    final summary = app.latestSummary;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          _greetingHeader(context, displayName),
          if (pendingCount > 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: _pendingReviewBanner(context, pendingCount),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
            child: _statusBanner(),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
            child: GestureDetector(
              onTap: onUsageTap,
              child: _myUsageCard(),
            ),
          ),
          if (summary != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
              child: _aiSummaryCard(context, summary.summaryText,
                  summary.pros, summary.cons, summary.reviewCount),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
            child: _trendCard(),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
            child: _billCard(),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
            child: _savingTipCard(),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: SectionLabel('HOME EQUIPMENT'),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: _equipmentCard(
              icon: Icons.water_drop_outlined,
              color: AppColors.waterAccent,
              bg: AppColors.waterSurface,
              name: 'Water Meter',
              serial: 'WM-20482',
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: _equipmentCard(
              icon: Icons.electric_bolt_outlined,
              color: AppColors.electricityAccent,
              bg: AppColors.electricitySurface,
              name: 'Smart Meter',
              serial: 'SM-10921',
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _equipmentCard({
    required IconData icon,
    required Color color,
    required Color bg,
    required String name,
    required String serial,
  }) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  serial,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const Text(
            'Active',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.success,
            ),
          ),
        ],
      ),
    );
  }

  Widget _pendingReviewBanner(BuildContext context, int count) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const MyReportsScreen())),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF7ED),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: AppColors.warning.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Icon(Icons.star_outline,
                  color: Color(0xFFC2410C), size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$count repair${count > 1 ? "s" : ""} awaiting your review',
                    style: const TextStyle(
                      color: Color(0xFFC2410C),
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                  const Text(
                    'Tap to rate the service quality',
                    style: TextStyle(
                        color: Color(0xFF9A3412), fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right,
                color: Color(0xFFC2410C), size: 20),
          ],
        ),
      ),
    );
  }

  Widget _aiSummaryCard(BuildContext context, String summaryText,
      List<String> pros, List<String> cons, int reviewCount) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F766E), Color(0xFF1E40AF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome,
                  color: Colors.white, size: 16),
              const SizedBox(width: 8),
              const Text('AI Service Insights',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w800)),
              const Spacer(),
              Text('$reviewCount reviews',
                  style: const TextStyle(
                      color: Colors.white60, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 10),
          Text(summaryText,
              style: const TextStyle(
                  color: Colors.white, fontSize: 13, height: 1.5)),
          if (pros.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                ...pros.map((p) => _SummaryPill(label: '+ $p', positive: true)),
                ...cons.map((c) => _SummaryPill(label: '- $c', positive: false)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _greetingHeader(BuildContext context, String name) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.adminPrimary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person_outline,
                  color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Good morning,',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.notifications_outlined,
                      color: Colors.white, size: 20),
                ),
                Positioned(
                  top: -2,
                  right: -2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: AppColors.critical,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                          color: AppColors.adminPrimary, width: 1.5),
                    ),
                    child: const Text(
                      '2',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.white70, size: 20),
              onPressed: () => context.read<RoleState>().logout(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.successSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Icon(Icons.check_circle_outline,
                color: AppColors.success, size: 20),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'All systems normal',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                Text(
                  'No anomalies detected this month',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _myUsageCard() {
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                SectionLabel('MY USAGE · JUL 2025'),
                Icon(Icons.chevron_right,
                    color: AppColors.textTertiary, size: 20),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
            child: Row(
              children: [
                Expanded(
                  child: _usageCell(
                    icon: Icons.water_drop_outlined,
                    color: AppColors.waterAccent,
                    bg: AppColors.waterSurface,
                    label: 'WATER',
                    value: '14.8',
                    unit: 'm³ this month',
                    trend: '-3.3% vs Jun',
                    trendPositive: true,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _usageCell(
                    icon: Icons.electric_bolt_outlined,
                    color: AppColors.electricityAccent,
                    bg: AppColors.electricitySurface,
                    label: 'ELECTRICITY',
                    value: '10.8',
                    unit: 'kWh this month',
                    trend: '-5.3% vs Jun',
                    trendPositive: true,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _usageCell({
    required IconData icon,
    required Color color,
    required Color bg,
    required String label,
    required String value,
    required String unit,
    required String trend,
    required bool trendPositive,
  }) {
    final trendColor = trendPositive ? AppColors.success : AppColors.critical;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              height: 1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            unit,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                trendPositive ? Icons.trending_down : Icons.trending_up,
                size: 14,
                color: trendColor,
              ),
              const SizedBox(width: 4),
              Text(
                trend,
                style: TextStyle(
                  color: trendColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _trendCard() {
    final months = ['Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul'];
    final water = [16.2, 15.8, 15.4, 15.4, 15.3, 14.8];
    final elec = [12.5, 12.0, 11.6, 11.4, 11.4, 10.8];

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SectionLabel('6-MONTH TREND'),
              Row(
                children: [
                  _legendDot(AppColors.waterAccent, 'Water'),
                  const SizedBox(width: 12),
                  _legendDot(AppColors.electricityAccent, 'Elec.'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 160,
            child: LineChart(
              LineChartData(
                minY: 8,
                maxY: 18,
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      interval: 1,
                      getTitlesWidget: (v, meta) {
                        final i = v.round();
                        if (i < 0 || i >= months.length || i != v) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            months[i],
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textTertiary,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                gridData: const FlGridData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    isCurved: true,
                    color: AppColors.waterAccent,
                    barWidth: 3,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, _, __, ___) =>
                          FlDotCirclePainter(
                        radius: 4,
                        color: AppColors.waterAccent,
                        strokeWidth: 0,
                      ),
                      checkToShowDot: (spot, bar) =>
                          spot.x == bar.spots.last.x,
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.waterAccent.withValues(alpha: 0.15),
                    ),
                    spots: [
                      for (int i = 0; i < water.length; i++)
                        FlSpot(i.toDouble(), water[i]),
                    ],
                  ),
                  LineChartBarData(
                    isCurved: true,
                    color: AppColors.electricityAccent,
                    barWidth: 3,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, _, __, ___) =>
                          FlDotCirclePainter(
                        radius: 4,
                        color: AppColors.electricityAccent,
                        strokeWidth: 0,
                      ),
                      checkToShowDot: (spot, bar) =>
                          spot.x == bar.spots.last.x,
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color:
                          AppColors.electricityAccent.withValues(alpha: 0.12),
                    ),
                    spots: [
                      for (int i = 0; i < elec.length; i++)
                        FlSpot(i.toDouble(), elec[i]),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            )),
      ],
    );
  }

  Widget _billCard() {
    return AppCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Estimated Bill · Jul 2025',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    )),
                const SizedBox(height: 4),
                const Text('RM 78.40',
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      height: 1.1,
                    )),
                const SizedBox(height: 4),
                Text('Due 31 Jul 2025',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.warning,
                      fontWeight: FontWeight.w700,
                    )),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.successSurface,
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Text(
              'Due 31 Jul 2025',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.success,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _savingTipCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lightbulb_outline,
              color: const Color(0xFFC2410C), size: 20),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Saving Tip',
                    style: TextStyle(
                      color: Color(0xFFC2410C),
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    )),
                SizedBox(height: 2),
                Text(
                  'Turn off the tap while brushing — save up to 12 L per day.',
                  style: TextStyle(
                    color: Color(0xFF9A3412),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryPill extends StatelessWidget {
  final String label;
  final bool positive;
  const _SummaryPill({required this.label, required this.positive});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: positive
            ? Colors.white.withValues(alpha: 0.2)
            : Colors.red.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label,
          style: const TextStyle(
              color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}
