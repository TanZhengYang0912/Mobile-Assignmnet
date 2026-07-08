import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../theme/tokens.dart';
import '../../auth/state/auth_state.dart';
import 'notifications_screen.dart';

class CompareUsageScreen extends StatefulWidget {
  const CompareUsageScreen({super.key});

  @override
  State<CompareUsageScreen> createState() => _CompareUsageScreenState();
}

class _CompareUsageScreenState extends State<CompareUsageScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  final _waterDaily = const [
    14.2, 15.1, 13.6, 16.4, 14.8, 15.9, 17.1,
    14.3, 15.5, 14.7, 16.0, 17.4, 15.2, 16.8,
    13.9, 15.0, 14.5, 15.8, 16.2, 14.1, 15.7,
    16.5, 14.4, 15.3, 17.0, 14.9, 15.6, 16.1,
    14.6, 15.9, 16.7,
  ];
  final _elecDaily = const [
    9.8, 11.4, 10.2, 12.8, 10.5, 11.0, 13.2,
    10.1, 11.9, 10.8, 12.4, 13.5, 10.9, 12.1,
    9.5, 11.7, 10.6, 12.3, 13.0, 10.4, 11.6,
    12.6, 10.7, 11.3, 12.9, 10.0, 11.2, 12.5,
    10.3, 11.8, 12.7,
  ];

  final _waterMonthly = const [
    _MonthUsage('Jul 2025', 14.8, current: true),
    _MonthUsage('Jun 2025', 15.3),
    _MonthUsage('May 2025', 15.4),
    _MonthUsage('Apr 2025', 15.1),
    _MonthUsage('Mar 2025', 15.8),
    _MonthUsage('Feb 2025', 16.2),
    _MonthUsage('Jan 2025', 16.5),
    _MonthUsage('Dec 2024', 17.1),
    _MonthUsage('Nov 2024', 16.8),
    _MonthUsage('Oct 2024', 15.9),
    _MonthUsage('Sep 2024', 15.4),
    _MonthUsage('Aug 2024', 14.9),
  ];
  final _elecMonthly = const [
    _MonthUsage('Jul 2025', 10.8, current: true),
    _MonthUsage('Jun 2025', 11.4),
    _MonthUsage('May 2025', 11.2),
    _MonthUsage('Apr 2025', 11.5),
    _MonthUsage('Mar 2025', 11.9),
    _MonthUsage('Feb 2025', 12.4),
    _MonthUsage('Jan 2025', 12.8),
    _MonthUsage('Dec 2024', 13.5),
    _MonthUsage('Nov 2024', 13.2),
    _MonthUsage('Oct 2024', 12.1),
    _MonthUsage('Sep 2024', 11.7),
    _MonthUsage('Aug 2024', 11.0),
  ];

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

  bool get _isWater => _tab.index == 0;

  @override
  Widget build(BuildContext context) {
    final currentDaily = _isWater ? _waterDaily : _elecDaily;
    final currentMonthly = _isWater ? _waterMonthly : _elecMonthly;
    final unit = _isWater ? 'm³' : 'kWh';
    final accent =
        _isWater ? AppColors.waterAccent : AppColors.electricityAccent;
    final surface =
        _isWater ? AppColors.waterSurface : AppColors.electricitySurface;
    final current = currentMonthly.first;
    final prev = currentMonthly[1];
    final delta = ((current.value - prev.value) / prev.value * 100);
    final avg =
        currentMonthly.map((m) => m.value).reduce((a, b) => a + b) /
            currentMonthly.length;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          _header(context),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: _utilityTabs(),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
            child: _summaryCard(current, delta, avg, unit, accent, surface),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
            child: _dailyChart(currentDaily, unit, accent, surface),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
            child: _monthlyHistory(currentMonthly, unit, accent, surface),
          ),
        ],
      ),
    );
  }

  Widget _header(BuildContext context) {
    final email = context.watch<RoleState>().email ?? '';
    final displayName = email.isEmpty
        ? 'there'
        : email.split('@').first.replaceAll('.', ' ').replaceAllMapped(
              RegExp(r'\b\w'),
              (m) => m.group(0)!.toUpperCase(),
            );

    return Container(
      width: double.infinity,
      color: AppColors.adminPrimary,
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.of(context).padding.top + 14,
        20,
        18,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person_outline,
                color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Good morning,',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                    )),
                const SizedBox(height: 2),
                Text(displayName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                    )),
              ],
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const NotificationsScreen(),
                ),
              ),
              child: Stack(
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
                    top: -3,
                    right: -3,
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
            ),
          ),
        ],
      ),
    );
  }

  Widget _utilityTabs() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Expanded(
            child: _tabButton(
              label: 'Water',
              icon: Icons.water_drop_outlined,
              selected: _isWater,
              onTap: () => _tab.animateTo(0),
              color: AppColors.waterAccent,
            ),
          ),
          Expanded(
            child: _tabButton(
              label: 'Electricity',
              icon: Icons.electric_bolt_outlined,
              selected: !_isWater,
              onTap: () => _tab.animateTo(1),
              color: AppColors.electricityAccent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabButton({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
    required Color color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: selected
              ? const [
                  BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 16,
                color: selected ? color : AppColors.textTertiary),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: selected ? color : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryCard(_MonthUsage current, double delta, double avg,
      String unit, Color accent, Color surface) {
    final trendDown = delta < 0;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${current.label} · ${_isWater ? 'Water' : 'Electricity'} Usage',
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                current.value.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  height: 1.1,
                ),
              ),
              const SizedBox(width: 4),
              Text(unit,
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                  )),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(trendDown ? Icons.trending_down : Icons.trending_up,
                  size: 16,
                  color: trendDown ? AppColors.success : AppColors.critical),
              const SizedBox(width: 4),
              Text(
                '${delta.toStringAsFixed(1)}% compared to Jun',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: trendDown ? AppColors.success : AppColors.critical,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Text('Monthly average',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  )),
              const Spacer(),
              Text('${avg.toStringAsFixed(1)} $unit',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  )),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (current.value / avg).clamp(0.0, 1.5) / 1.5,
              minHeight: 8,
              backgroundColor: surface,
              valueColor: AlwaysStoppedAnimation<Color>(accent),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dailyChart(
      List<double> data, String unit, Color accent, Color surface) {
    final maxV = data.reduce((a, b) => a > b ? a : b) * 1.15;
    const barWidth = 18.0;
    const barGap = 6.0;
    const chartHeight = 130.0;
    const labelHeight = 18.0;
    const scrollbarPad = 14.0;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SectionLabel('DAILY (JUL 2025)'),
              Text('per day in $unit',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textTertiary,
                  )),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              const Icon(Icons.swipe, size: 13, color: AppColors.textTertiary),
              const SizedBox(width: 4),
              Text('Swipe · ${data.length} days',
                  style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.textTertiary,
                      fontStyle: FontStyle.italic)),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: chartHeight + labelHeight + scrollbarPad,
            child: Scrollbar(
              thumbVisibility: true,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.only(bottom: scrollbarPad),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: chartHeight,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          for (int i = 0; i < data.length; i++) ...[
                            Container(
                              width: barWidth,
                              height: (data[i] / maxV) * chartHeight,
                              decoration: BoxDecoration(
                                color: accent.withValues(alpha: 0.55),
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(4),
                                  topRight: Radius.circular(4),
                                ),
                              ),
                            ),
                            if (i < data.length - 1)
                              const SizedBox(width: barGap),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    SizedBox(
                      height: labelHeight - 4,
                      child: Row(
                        children: [
                          for (int i = 0; i < data.length; i++) ...[
                            SizedBox(
                              width: barWidth,
                              child: Text(
                                '${i + 1}',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 9,
                                  color: AppColors.textTertiary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            if (i < data.length - 1)
                              const SizedBox(width: barGap),
                          ],
                        ],
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

  Widget _monthlyHistory(
      List<_MonthUsage> months, String unit, Color accent, Color surface) {
    final maxV = months.map((m) => m.value).reduce((a, b) => a > b ? a : b);
    final minV = months.map((m) => m.value).reduce((a, b) => a < b ? a : b);
    final range = maxV - minV;
    const rowHeight = 44.0;
    final visibleRows = months.length > 4 ? 4 : months.length;
    final scrollHeight = rowHeight * visibleRows;

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: SectionLabel('MONTHLY HISTORY'),
          ),
          if (months.length > 4)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Icon(Icons.swap_vert,
                      size: 13, color: AppColors.textTertiary),
                  const SizedBox(width: 4),
                  Text('Scroll · ${months.length} months',
                      style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.textTertiary,
                          fontStyle: FontStyle.italic)),
                ],
              ),
            ),
          SizedBox(
            height: scrollHeight,
            child: Scrollbar(
              thumbVisibility: true,
              child: ListView.builder(
                padding: const EdgeInsets.only(right: 4),
                physics: const ClampingScrollPhysics(),
                itemCount: months.length,
                itemExtent: rowHeight,
                itemBuilder: (ctx, i) => _monthRow(
                  months[i],
                  unit,
                  accent,
                  surface,
                  minV,
                  range,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _monthRow(
    _MonthUsage m,
    String unit,
    Color accent,
    Color surface,
    double minV,
    double range,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            child: Text(m.label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                )),
          ),
          if (m.current) ...[
            const SizedBox(width: 4),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.successSurface,
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Text(
                'Current',
                style: TextStyle(
                  fontSize: 9,
                  color: AppColors.success,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
          const SizedBox(width: 10),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: range == 0
                    ? 0.8
                    : (0.3 + (m.value - minV) / range * 0.6)
                        .clamp(0.0, 1.0),
                minHeight: 6,
                backgroundColor: surface,
                valueColor: AlwaysStoppedAnimation<Color>(accent),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text('${m.value.toStringAsFixed(1)} $unit',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              )),
        ],
      ),
    );
  }

}

class _MonthUsage {
  final String label;
  final double value;
  final bool current;
  const _MonthUsage(this.label, this.value, {this.current = false});
}
