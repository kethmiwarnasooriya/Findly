import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/findly_colors.dart';
import '../../models/match_result.dart';
import '../../models/report_status.dart';
import '../../state/reports_controller.dart';
import '../../widgets/app_card.dart';
import '../../widgets/entrance.dart';
import '../../widgets/feedback.dart';
import '../../widgets/report_card.dart';
import '../../widgets/state_views.dart';
import '../item_details/item_details_screen.dart';

/// Ranked suggestions for one report, each with its score explanation.
class MatchesScreen extends StatelessWidget {
  const MatchesScreen({super.key, required this.reportId});

  final String reportId;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ReportsController>();
    final report = controller.reportById(reportId);
    final matches = report == null
        ? const <MatchResult>[]
        : controller.matchesFor(report);
    final isOwner = report != null && controller.isOwner(report);

    return Scaffold(
      appBar: AppBar(title: const Text('Possible matches')),
      bottomNavigationBar: isOwner && report.isActive
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: FilledButton.icon(
                  onPressed: () => _resolve(context),
                  icon: const Icon(Icons.task_alt_rounded),
                  label: const Text('This is sorted — mark resolved'),
                ),
              ),
            )
          : null,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          children: [
            const NoticeCard(
              icon: Icons.info_outline_rounded,
              message:
                  'Suggestions compare category, description words, location '
                  'wording and dates. A high score is not proof it is the same '
                  'item. Always check details before anything is handed over.',
            ),
            const SizedBox(height: 16),
            if (report == null || !report.isActive)
              const EmptyState(
                icon: Icons.task_alt_rounded,
                title: 'This report is resolved',
                message: 'Resolved reports are not matched.',
              )
            else if (matches.isEmpty)
              const EmptyState(
                icon: Icons.manage_search_rounded,
                title: 'No likely matches yet',
                message:
                    'New reports are compared automatically. Check back later.',
              )
            else
              for (final (index, match) in matches.indexed) ...[
                Entrance(
                  index: index,
                  child: _MatchCard(match: match),
                ),
                const SizedBox(height: 16),
              ],
          ],
        ),
      ),
    );
  }

  Future<void> _resolve(BuildContext context) async {
    final controller = context.read<ReportsController>();
    final report = controller.reportById(reportId);
    if (report == null) return;
    final confirmed = await confirmAction(
      context,
      title: 'Mark as resolved?',
      message:
          'Only do this once the item is back with its owner '
          'or the report is no longer needed.',
      confirmLabel: 'Mark resolved',
    );
    if (!confirmed || !context.mounted) return;
    try {
      await controller.setStatus(report, ReportStatus.resolved);
      if (context.mounted) showMessage(context, 'Marked as resolved');
    } catch (error) {
      if (context.mounted) showError(context, error);
    }
  }
}

class _MatchCard extends StatelessWidget {
  const _MatchCard({required this.match});

  final MatchResult match;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final breakdown = match.breakdown;

    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _ScoreRing(score: match.score, strength: match.strength),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      match.strength.label,
                      style: theme.textTheme.titleMedium,
                    ),
                    Text(
                      'Based on ${match.reasons.length} '
                      '${match.reasons.length == 1 ? 'signal' : 'signals'}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ReportCard(
            report: match.candidate,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => ItemDetailsScreen(reportId: match.candidate.id),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text('Why this was suggested', style: theme.textTheme.labelLarge),
          const SizedBox(height: 6),
          for (final reason in match.reasons)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    size: 18,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(reason, style: theme.textTheme.bodySmall),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _PointsChip(label: 'Category', points: breakdown.category),
              _PointsChip(label: 'Description', points: breakdown.description),
              _PointsChip(label: 'Location', points: breakdown.location),
              _PointsChip(label: 'Date', points: breakdown.date),
            ],
          ),
        ],
      ),
    );
  }
}

/// Circular gauge that animates up to the score.
class _ScoreRing extends StatelessWidget {
  const _ScoreRing({required this.score, required this.strength});

  final int score;
  final MatchStrength strength;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final brand = context.findly;
    final color = switch (strength) {
      MatchStrength.strong => scheme.primary,
      MatchStrength.possible => brand.accent,
      MatchStrength.weak => scheme.outline,
    };

    return Semantics(
      label: 'Score $score out of 100',
      excludeSemantics: true,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: score / 100),
        duration: const Duration(milliseconds: 900),
        curve: Curves.easeOutCubic,
        builder: (context, value, _) => SizedBox.square(
          dimension: 56,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CircularProgressIndicator(
                value: value,
                strokeWidth: 5,
                strokeCap: StrokeCap.round,
                color: color,
                backgroundColor: scheme.surfaceContainerHigh,
              ),
              Center(
                child: Text(
                  '${(value * 100).round()}',
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PointsChip extends StatelessWidget {
  const _PointsChip({required this.label, required this.points});

  final String label;
  final int points;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final earned = points > 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: earned ? scheme.primaryContainer : scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$label +$points',
        style: theme.textTheme.labelSmall?.copyWith(
          color: earned ? scheme.onPrimaryContainer : scheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
