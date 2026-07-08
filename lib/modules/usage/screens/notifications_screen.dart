import 'package:flutter/material.dart';

import '../../../theme/tokens.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  static const _items = <_NotificationItem>[
    _NotificationItem(
      icon: Icons.warning_amber_rounded,
      color: AppColors.warning,
      bg: AppColors.warningSurface,
      title: 'Bill Due Soon',
      message: 'Your July bill of RM 78.40 is due on 31 Jul 2025.',
      timeAgo: '2h ago',
      showStrip: true,
    ),
    _NotificationItem(
      icon: Icons.check_circle_outline,
      color: AppColors.success,
      bg: AppColors.successSurface,
      title: 'Usage Down This Month',
      message: 'Great news! Your water usage dropped 3.1% vs last month.',
      timeAgo: '1d ago',
      showStrip: true,
    ),
    _NotificationItem(
      icon: Icons.info_outline,
      color: AppColors.waterAccent,
      bg: AppColors.waterSurface,
      title: 'Scheduled Maintenance',
      message: 'Water supply interruption on 10 Aug, 9am–12pm.',
      timeAgo: '2d ago',
      showStrip: false,
    ),
    _NotificationItem(
      icon: Icons.check_circle_outline,
      color: AppColors.success,
      bg: AppColors.successSurface,
      title: 'Meter Reading Confirmed',
      message: 'Your July meter reading has been recorded successfully.',
      timeAgo: '3d ago',
      showStrip: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: Column(
        children: [
          _header(context),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              itemCount: _items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) => _card(_items[i]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.adminPrimary,
      padding: EdgeInsets.fromLTRB(
        4,
        MediaQuery.of(context).padding.top + 8,
        16,
        16,
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          const Text(
            'Notifications',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _card(_NotificationItem item) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0F000000),
              blurRadius: 10,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: item.showStrip ? 4 : 0,
                color: item.color,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: item.bg,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Icon(item.icon, color: item.color, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    item.title,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  item.timeAgo,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textTertiary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item.message,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationItem {
  final IconData icon;
  final Color color;
  final Color bg;
  final String title;
  final String message;
  final String timeAgo;
  final bool showStrip;

  const _NotificationItem({
    required this.icon,
    required this.color,
    required this.bg,
    required this.title,
    required this.message,
    required this.timeAgo,
    required this.showStrip,
  });
}
