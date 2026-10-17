import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/findly_colors.dart';
import '../../core/utils/date_utils.dart';
import '../../models/item_report.dart';
import '../../models/report_status.dart';
import '../../models/report_type.dart';
import '../../state/reports_controller.dart';
import '../../widgets/app_card.dart';
import '../../widgets/category_icon.dart';
import '../../widgets/feedback.dart';
import '../../widgets/report_badges.dart';
import '../../widgets/report_photo.dart';
import '../../widgets/state_views.dart';
import '../matches/matches_screen.dart';
import '../report/report_form_screen.dart';

enum _MenuAction { edit, delete }

/// Full details of one report. Looks the report up by id so it always shows
/// the latest saved version.
class ItemDetailsScreen extends StatefulWidget {
  const ItemDetailsScreen({super.key, required this.reportId});

  final String reportId;

  @override
  State<ItemDetailsScreen> createState() => _ItemDetailsScreenState();
}

class _ItemDetailsScreenState extends State<ItemDetailsScreen> {
  bool _busy = false;

  Future<void> _setStatus(ItemReport report, ReportStatus status) async {
    final resolving = status == ReportStatus.resolved;
    final confirmed = await confirmAction(
      context,
      title: resolving ? 'Mark as resolved?' : 'Reopen report?',
      message: resolving
          ? 'Resolved reports are hidden from matching. You can reopen it later.'
          : 'The report will be active again and included in matching.',
      confirmLabel: resolving ? 'Mark resolved' : 'Reopen',
    );
    if (!confirmed || !mounted) return;
    await _run(() async {
      await context.read<ReportsController>().setStatus(report, status);
      if (mounted) {
        showMessage(
          context,
          resolving ? 'Marked as resolved' : 'Report reopened',
        );
      }
    });
  }

  Future<void> _delete(ItemReport report) async {
    final confirmed = await confirmAction(
      context,
      title: 'Delete this report?',
      message:
          'This permanently removes the report and its photo. '
          'This cannot be undone.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!confirmed || !mounted) return;
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    await _run(() async {
      await context.read<ReportsController>().deleteReport(report);
      navigator.pop();
      messenger.showSnackBar(const SnackBar(content: Text('Report deleted')));
    });
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } catch (error) {
      if (mounted) showError(context, error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _edit(ItemReport report) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ReportFormScreen(existing: report),
      ),
    );
  }

  void _openMatches(ItemReport report) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MatchesScreen(reportId: report.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ReportsController>();
    final report = controller.reportById(widget.reportId);

    if (report == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(
          child: EmptyState(
            icon: Icons.inventory_2_outlined,
            title: 'Report not available',
            message: 'It may have been deleted.',
          ),
        ),
      );
    }

    final isOwner = controller.isOwner(report);
    final matchCount = report.isActive
        ? controller.matchesFor(report).length
        : 0;
    final theme = Theme.of(context);
    final brand = context.findly;
    final isLost = report.type == ReportType.lost;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            stretch: true,
            expandedHeight: 300,
            backgroundColor: brand.header,
            foregroundColor: brand.onHeader,
            title: Text('${report.type.label} item'),
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.only(
                bottomRight: Radius.circular(AppTheme.headerRadius),
              ),
            ),
            clipBehavior: Clip.antiAlias,
            actions: [
              if (isOwner)
                PopupMenuButton<_MenuAction>(
                  tooltip: 'More actions',
                  enabled: !_busy,
                  onSelected: (action) => switch (action) {
                    _MenuAction.edit => _edit(report),
                    _MenuAction.delete => _delete(report),
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: _MenuAction.edit,
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.edit_outlined),
                        title: Text('Edit'),
                      ),
                    ),
                    PopupMenuItem(
                      value: _MenuAction.delete,
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.delete_outline_rounded),
                        title: Text('Delete'),
                      ),
                    ),
                  ],
                ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.parallax,
              background: Stack(
                fit: StackFit.expand,
                children: [
                  ReportPhoto(report: report, borderRadius: 0, iconSize: 88),
                  // Keeps the app bar icons readable over bright photos.
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.center,
                        colors: [Color(0x99000000), Color(0x00000000)],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            sliver: SliverList.list(
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    TypeBadge(report.type),
                    StatusBadge(report.status),
                    if (isOwner)
                      PillBadge(
                        label: 'Your report',
                        icon: Icons.person_outline_rounded,
                        colors: ToneColors(
                          theme.colorScheme.surfaceContainerHigh,
                          theme.colorScheme.onSurface,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(report.title, style: theme.textTheme.headlineSmall),
                const SizedBox(height: 18),
                AppCard(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Column(
                    children: [
                      _InfoRow(
                        icon: report.category.icon,
                        label: 'Category',
                        value: report.category.label,
                      ),
                      _InfoRow(
                        icon: Icons.place_outlined,
                        label: isLost ? 'Lost at' : 'Found at',
                        value: report.location,
                      ),
                      _InfoRow(
                        icon: Icons.event_outlined,
                        label: isLost ? 'Date lost' : 'Date found',
                        value: formatDisplayDate(report.eventDate),
                      ),
                      _InfoRow(
                        icon: Icons.schedule_rounded,
                        label: 'Reported',
                        value: formatRelativeDate(report.createdAt),
                      ),
                      if (report.resolvedAt case final resolvedAt?)
                        _InfoRow(
                          icon: Icons.check_circle_outline_rounded,
                          label: 'Resolved',
                          value: formatDisplayDate(resolvedAt),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                Text('Description', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(
                  report.description,
                  style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
                ),
                const SizedBox(height: 28),
                if (report.isActive)
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: brand.accent,
                      foregroundColor: brand.onAccent,
                    ),
                    onPressed: () => _openMatches(report),
                    icon: const Icon(Icons.join_inner_rounded),
                    label: Text(
                      matchCount == 0
                          ? 'Check for possible matches'
                          : 'View $matchCount possible ${matchCount == 1 ? 'match' : 'matches'}',
                    ),
                  )
                else
                  NoticeCard(
                    icon: Icons.task_alt_rounded,
                    message: 'Resolved reports are not included in matching.',
                    tone: brand.resolved,
                  ),
                if (isOwner) ...[
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _busy
                        ? null
                        : () => _setStatus(
                            report,
                            report.isActive
                                ? ReportStatus.resolved
                                : ReportStatus.active,
                          ),
                    icon: Icon(
                      report.isActive
                          ? Icons.task_alt_rounded
                          : Icons.replay_rounded,
                    ),
                    label: Text(
                      report.isActive ? 'Mark as resolved' : 'Reopen report',
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return MergeSemantics(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Row(
          children: [
            IconTile(
              icon: icon,
              background: scheme.primaryContainer,
              foreground: scheme.onPrimaryContainer,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  Text(value, style: theme.textTheme.bodyLarge),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
