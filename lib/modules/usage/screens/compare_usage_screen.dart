import 'package:flutter/material.dart';

import '../../../theme/tokens.dart';

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
  ];
  final _elecDaily = const [
    9.8, 11.4, 10.2, 12.8, 10.5, 11.0, 13.2,
    10.1, 11.9, 10.8, 12.4, 13.5, 10.9, 12.1,
  ];

  final _waterMonthly = const [
    _MonthUsage('Jul 2025', 14.8, current: true),
    _MonthUsage('Jun 2025', 15.3),
    _MonthUsage('May 2025', 15.4),
    _MonthUsage('Apr 2025', 15.1),
    _MonthUsage('Mar 2025', 15.8),
    _MonthUsage('Feb 2025', 16.2),
  ];
  final _elecMonthly = const [
    _MonthUsage('Jul 2025', 10.8, current: true),
    _MonthUsage('Jun 2025', 11.4),
    _MonthUsage('May 2025', 11.2),
    _MonthUsage('Apr 2025', 11.5),
    _MonthUsage('Mar 2025', 11.9),
    _MonthUsage('Feb 2025', 12.4),
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
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
            child: _monthlyHistory(currentMonthly, unit, accent, surface),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _header(BuildContext context) {
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
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.bar_chart_outlined,
                  color: Colors.white, size: 22),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('mySumber · USAGE',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      )),
                  SizedBox(height: 2),
                  Text('My Usage',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      )),
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
          ],
        ),
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
          const SizedBox(height: 14),
          SizedBox(
            height: 130,
            child: LayoutBuilder(builder: (context, cs) {
              final barWidth =
                  (cs.maxWidth - (data.length - 1) * 4) / data.length;
              return Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (int i = 0; i < data.length; i++) ...[
                    Container(
                      width: barWidth,
                      height: (data[i] / maxV) * 130,
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.55),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(4),
                          topRight: Radius.circular(4),
                        ),
                      ),
                    ),
                    if (i < data.length - 1) const SizedBox(width: 4),
                  ],
                ],
              );
            }),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              for (int i = 0; i < data.length; i++) ...[
                Expanded(
                  child: Text(
                    (i % 2 == 0) ? '${i + 1}' : '',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ),
              ],
            ],
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

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: SectionLabel('MONTHLY HISTORY'),
          ),
          for (int i = 0; i < months.length; i++) ...[
            if (i > 0) const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Row(
                children: [
                  SizedBox(
                    width: 80,
                    child: Text(months[i].label,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        )),
                  ),
                  if (months[i].current) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.successSurface,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        'Current',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.success,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(width: 12),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: range == 0
                            ? 0.8
                            : (0.3 + (months[i].value - minV) / range * 0.6)
                                .clamp(0.0, 1.0),
                        minHeight: 6,
                        backgroundColor: surface,
                        valueColor: AlwaysStoppedAnimation<Color>(accent),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text('${months[i].value.toStringAsFixed(1)} $unit',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      )),
                ],
              ),
            ),
          ],
          const SizedBox(height: 8),
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
