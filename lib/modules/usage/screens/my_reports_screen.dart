import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../theme/tokens.dart';
import '../../auth/state/auth_state.dart';
import '../../leakage/models/alert.dart';
import '../../leakage/models/service_review.dart';
import '../../leakage/state/app_state.dart';

class MyReportsScreen extends StatelessWidget {
  const MyReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final email = context.watch<RoleState>().email ?? '';

    final resolved = app.solvedAlerts();
    final reviewedIds = app.reviewedAlertIds(email);

    final pending = resolved.where((a) => !reviewedIds.contains(a.id)).toList();
    final done = resolved.where((a) => reviewedIds.contains(a.id)).toList();

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          _header(context),
          if (pending.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: SectionLabel('PENDING REVIEW'),
            ),
            for (final a in pending)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: _AlertReviewCard(
                  alert: a,
                  reviewed: false,
                  review: null,
                  email: email,
                ),
              ),
          ],
          if (done.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: SectionLabel('PAST REVIEWS'),
            ),
            for (final a in done) ...[
              Builder(builder: (ctx) {
                final review = app.reviews.firstWhere(
                  (r) => r.alertId == a.id && r.consumerEmail == email,
                  orElse: () => ServiceReview(
                    consumerEmail: email,
                    stars: 0,
                    createdAt: DateTime.now(),
                  ),
                );
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: _AlertReviewCard(
                    alert: a,
                    reviewed: true,
                    review: review,
                    email: email,
                  ),
                );
              }),
            ],
          ],
          if (pending.isEmpty && done.isEmpty)
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 40, 16, 0),
              child: Center(
                child: Text(
                  'No resolved repairs yet.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
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
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('mySumber · CUSTOMER',
                      style: TextStyle(color: Colors.white70, fontSize: 13)),
                  SizedBox(height: 2),
                  Text('My Repair Reports',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AlertReviewCard extends StatelessWidget {
  final Alert alert;
  final bool reviewed;
  final ServiceReview? review;
  final String email;

  const _AlertReviewCard({
    required this.alert,
    required this.reviewed,
    required this.review,
    required this.email,
  });

  @override
  Widget build(BuildContext context) {
    final isWater = alert.utility == Utility.water;
    final accent = isWater ? AppColors.waterAccent : AppColors.electricityAccent;
    final typeLabel = isWater ? 'Water Repair' : 'Electricity Repair';
    final date = DateFormat('d MMM yyyy').format(alert.detectedAt);

    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0F000000),
                blurRadius: 10,
                offset: Offset(0, 3),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(18, 14, 14, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      alert.state,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.successSurface,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text('Resolved',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.success,
                        )),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '$typeLabel · $date',
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary),
              ),
              if (alert.lossPct != null) ...[
                const SizedBox(height: 4),
                Text(
                  '${alert.lossPct!.toStringAsFixed(1)}% loss resolved',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: accent),
                ),
              ],
              const SizedBox(height: 12),
              if (!reviewed)
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => _openRatingSheet(context),
                    icon: const Icon(Icons.star_outline, size: 16),
                    label: const Text('Rate this Repair'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.adminPrimary,
                      minimumSize: const Size.fromHeight(42),
                      textStyle: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                  ),
                )
              else if (review != null && review!.stars > 0) ...[
                Row(
                  children: [
                    for (int i = 1; i <= 5; i++)
                      Icon(
                        i <= review!.stars ? Icons.star : Icons.star_outline,
                        color: const Color(0xFFF59E0B),
                        size: 18,
                      ),
                    const SizedBox(width: 8),
                    Text(
                      DateFormat('d MMM').format(review!.createdAt),
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textTertiary),
                    ),
                  ],
                ),
                if (review!.tags.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    children: review!.tags
                        .map((t) => _TagChip(label: t))
                        .toList(),
                  ),
                ],
              ],
            ],
          ),
        ),
        Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          child: Container(
            width: 4,
            decoration: BoxDecoration(
              color: reviewed ? AppColors.success : accent,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                bottomLeft: Radius.circular(14),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _openRatingSheet(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _RateRepairSheet(alert: alert, email: email),
    );
  }
}

class _TagChip extends StatelessWidget {
  final String label;
  const _TagChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.adminSurface,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label,
          style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.adminPrimary)),
    );
  }
}

// ── Rating bottom sheet ─────────────────────────────────────────────────────

const _positiveTags = [
  'Fast Response',
  'Perfectly Fixed',
  'Great Attitude',
  'Professional',
  'Thorough Check',
];
const _negativeTags = [
  'Still Leaking',
  'Slow Response',
  'Overcharged',
  'Unprofessional',
  'Poor Fix',
];

class _RateRepairSheet extends StatefulWidget {
  final Alert alert;
  final String email;
  const _RateRepairSheet({required this.alert, required this.email});

  @override
  State<_RateRepairSheet> createState() => _RateRepairSheetState();
}

class _RateRepairSheetState extends State<_RateRepairSheet> {
  int _stars = 0;
  final Set<String> _tags = {};
  final _commentCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: ListView(
                controller: ctrl,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                children: [
                  const Text('Rate this Repair',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 4),
                  Text(
                    '${widget.alert.state} · ${widget.alert.utility == Utility.water ? "Water Repair" : "Electricity Repair"}',
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 24),
                  const Text('How was the repair?',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (i) {
                      final idx = i + 1;
                      return GestureDetector(
                        onTap: () => setState(() => _stars = idx),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Icon(
                            idx <= _stars ? Icons.star : Icons.star_outline,
                            color: const Color(0xFFF59E0B),
                            size: 40,
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 24),
                  const Text('What went well?',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _positiveTags
                        .map((t) => _SelectableChip(
                              label: t,
                              selected: _tags.contains(t),
                              color: AppColors.success,
                              bg: AppColors.successSurface,
                              onTap: () => setState(
                                  () => _tags.contains(t)
                                      ? _tags.remove(t)
                                      : _tags.add(t)),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 16),
                  const Text('Any issues?',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _negativeTags
                        .map((t) => _SelectableChip(
                              label: t,
                              selected: _tags.contains(t),
                              color: AppColors.critical,
                              bg: AppColors.criticalSurface,
                              onTap: () => setState(
                                  () => _tags.contains(t)
                                      ? _tags.remove(t)
                                      : _tags.add(t)),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 16),
                  const Text('Additional comments (optional)',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _commentCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'Tell us more about your experience...',
                      hintStyle:
                          TextStyle(color: AppColors.textTertiary, fontSize: 13),
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _stars == 0 || _submitting ? null : _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.adminPrimary,
                      minimumSize: const Size.fromHeight(52),
                      disabledBackgroundColor: AppColors.divider,
                    ),
                    child: _submitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text('Submit Review',
                            style: TextStyle(
                                fontWeight: FontWeight.w800, fontSize: 15)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    final review = ServiceReview(
      alertId: widget.alert.id,
      consumerEmail: widget.email,
      stars: _stars,
      tags: _tags.toList(),
      comment: _commentCtrl.text.trim(),
      createdAt: DateTime.now(),
    );
    await context.read<AppState>().submitReview(review);
    if (mounted) Navigator.of(context).pop();
  }
}

class _SelectableChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final Color bg;
  final VoidCallback onTap;

  const _SelectableChip({
    required this.label,
    required this.selected,
    required this.color,
    required this.bg,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color : bg,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? color : color.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : color,
          ),
        ),
      ),
    );
  }
}
