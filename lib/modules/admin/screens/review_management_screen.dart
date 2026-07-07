import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../theme/tokens.dart';
import '../../leakage/models/ai_summary.dart';
import '../../leakage/models/service_review.dart';
import '../../leakage/state/app_state.dart';

class ReviewManagementScreen extends StatefulWidget {
  const ReviewManagementScreen({super.key});

  @override
  State<ReviewManagementScreen> createState() => _ReviewManagementScreenState();
}

class _ReviewManagementScreenState extends State<ReviewManagementScreen> {
  bool _generating = false;

  Future<void> _generate(BuildContext context) async {
    setState(() => _generating = true);
    final app = context.read<AppState>();
    final messenger = ScaffoldMessenger.of(context);
    final ok = await app.generateAiSummary();
    if (mounted) {
      setState(() => _generating = false);
      messenger.showSnackBar(SnackBar(
        content: Text(ok ? 'AI Insights generated!' : 'Generation failed — check Groq key.'),
        backgroundColor: ok ? AppColors.success : AppColors.critical,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final reviews = app.reviews;
    final summary = app.latestSummary;

    final avgStars = reviews.isEmpty
        ? 0.0
        : reviews.map((r) => r.stars).reduce((a, b) => a + b) / reviews.length;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          _header(),
          _statsRow(reviews.length, avgStars, summary),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: FilledButton.icon(
              onPressed: _generating ? null : () => _generate(context),
              icon: _generating
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.auto_awesome, size: 18),
              label: Text(_generating ? 'Generating...' : '✨ Generate AI Insights'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.adminPrimary,
                minimumSize: const Size.fromHeight(52),
                textStyle: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w800),
              ),
            ),
          ),
          if (summary != null) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: _AiSummaryCard(summary: summary),
            ),
          ],
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: SectionLabel('ALL REVIEWS'),
          ),
          for (final r in reviews)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: _ReviewCard(review: r),
            ),
          if (reviews.isEmpty)
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 24, 16, 0),
              child: Center(
                child: Text('No reviews yet.',
                    style: TextStyle(color: AppColors.textSecondary)),
              ),
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _header() {
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
              child: const Icon(Icons.star_outline, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('mySumber · ADMIN',
                      style: TextStyle(color: Colors.white70, fontSize: 13)),
                  SizedBox(height: 2),
                  Text('Service Reviews',
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

  Widget _statsRow(int total, double avg, AiSummary? summary) {
    final lastGen = summary == null
        ? 'Never'
        : DateFormat('d MMM, HH:mm').format(summary.generatedAt.toLocal());

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Row(
        children: [
          Expanded(
            child: _StatCell(
              label: 'Total Reviews',
              value: '$total',
              icon: Icons.rate_review_outlined,
              color: AppColors.adminPrimary,
              bg: AppColors.adminSurface,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _StatCell(
              label: 'Avg. Rating',
              value: avg == 0 ? '—' : avg.toStringAsFixed(1),
              icon: Icons.star_outline,
              color: const Color(0xFFF59E0B),
              bg: const Color(0xFFFEF3C7),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _StatCell(
              label: 'Last AI Run',
              value: lastGen,
              icon: Icons.auto_awesome_outlined,
              color: AppColors.workerPrimary,
              bg: AppColors.workerSurface,
              valueSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Color bg;
  final double valueSize;

  const _StatCell({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.bg,
    this.valueSize = 22,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0A000000), blurRadius: 6, offset: Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration:
                BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(height: 8),
          Text(value,
              style: TextStyle(
                  fontSize: valueSize,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  height: 1.1)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _AiSummaryCard extends StatelessWidget {
  final AiSummary summary;
  const _AiSummaryCard({required this.summary});

  @override
  Widget build(BuildContext context) {
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
              const Icon(Icons.auto_awesome, color: Colors.white, size: 16),
              const SizedBox(width: 8),
              const Text('AI Insights',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w800)),
              const Spacer(),
              Text(
                'Based on ${summary.reviewCount} reviews',
                style:
                    const TextStyle(color: Colors.white70, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            summary.summaryText,
            style: const TextStyle(
                color: Colors.white, fontSize: 13, height: 1.5),
          ),
          if (summary.pros.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text('PROS',
                style: TextStyle(
                    color: Colors.white60,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: summary.pros
                  .map((p) => _Pill(label: p, positive: true))
                  .toList(),
            ),
          ],
          if (summary.cons.isNotEmpty) ...[
            const SizedBox(height: 10),
            const Text('CONS',
                style: TextStyle(
                    color: Colors.white60,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: summary.cons
                  .map((c) => _Pill(label: c, positive: false))
                  .toList(),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            'Generated ${DateFormat("d MMM yyyy, HH:mm").format(summary.generatedAt.toLocal())}',
            style:
                const TextStyle(color: Colors.white38, fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final bool positive;
  const _Pill({required this.label, required this.positive});

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

class _ReviewCard extends StatelessWidget {
  final ServiceReview review;
  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('d MMM yyyy').format(review.createdAt);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2))
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Row(
                children: List.generate(
                  5,
                  (i) => Icon(
                    i < review.stars ? Icons.star : Icons.star_outline,
                    color: const Color(0xFFF59E0B),
                    size: 16,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  review.consumerEmail,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(date,
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textTertiary)),
            ],
          ),
          if (review.tags.isNotEmpty) ...[
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: review.tags
                  .map((t) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.adminSurface,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(t,
                            style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.adminPrimary)),
                      ))
                  .toList(),
            ),
          ],
          if (review.comment.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              '"${review.comment}"',
              style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  fontStyle: FontStyle.italic,
                  height: 1.4),
            ),
          ],
        ],
      ),
    );
  }
}
