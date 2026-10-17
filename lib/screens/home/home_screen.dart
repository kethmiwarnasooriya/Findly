import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../models/item_report.dart';
import '../../models/report_filter.dart';
import '../../models/report_status.dart';
import '../../models/report_type.dart';
import '../../state/reports_controller.dart';
import '../../widgets/entrance.dart';
import '../../widgets/loading.dart';
import '../../widgets/report_card.dart';
import '../../widgets/state_views.dart';
import '../item_details/item_details_screen.dart';
import '../report/report_form_screen.dart';
import '../settings/settings_screen.dart';
import 'home_header.dart';
import 'report_filter_bar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _push(Widget screen) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));
  }

  void _resetFilters(ReportsController controller) {
    _searchController.clear();
    controller.resetFilters();
  }

  /// Summary cards act as shortcuts for "active lost" / "active found".
  void _toggleSummary(ReportsController controller, ReportType type) {
    final filter = controller.filter;
    final alreadySelected =
        filter.type == type && filter.status == ReportStatus.active;
    controller.updateFilter(
      filter.copyWith(
        type: () => alreadySelected ? null : type,
        status: () => alreadySelected ? null : ReportStatus.active,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ReportsController>();
    final filter = controller.filter;
    final reports = controller.visibleReports;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _push(const ReportFormScreen()),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Report item'),
      ),
      body: RefreshIndicator(
        onRefresh: controller.load,
        edgeOffset: 120,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: HomeHeader(
                searchController: _searchController,
                onSearchChanged: (query) =>
                    controller.updateFilter(filter.copyWith(query: query)),
                selectedType: filter.type,
                onTypeChanged: (type) =>
                    controller.updateFilter(filter.copyWith(type: () => type)),
                onOpenSettings: () => _push(const SettingsScreen()),
              ),
            ),
            if (controller.loadError case final error?
                when controller.allReports.isNotEmpty)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: _RefreshErrorBanner(
                    message: error.message,
                    onRetry: controller.load,
                    onDismiss: controller.dismissLoadError,
                  ),
                ),
              ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    for (final type in ReportType.values) ...[
                      if (type != ReportType.values.first)
                        const SizedBox(width: 12),
                      Expanded(
                        child: SummaryCard(
                          label: 'Active ${type.label.toLowerCase()}',
                          count: type == ReportType.lost
                              ? controller.activeLostCount
                              : controller.activeFoundCount,
                          type: type,
                          selected:
                              filter.type == type &&
                              filter.status == ReportStatus.active,
                          onTap: () => _toggleSummary(controller, type),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.only(top: 18),
              sliver: SliverToBoxAdapter(
                child: ReportFilterBar(
                  filter: filter,
                  onChanged: controller.updateFilter,
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 20, 12, 10),
              sliver: SliverToBoxAdapter(
                child: _ListHeader(
                  filter: filter,
                  count: reports.length,
                  onReset: () => _resetFilters(controller),
                ),
              ),
            ),
            ..._buildResults(controller, reports),
            const SliverToBoxAdapter(child: SizedBox(height: 104)),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildResults(
    ReportsController controller,
    List<ItemReport> reports,
  ) {
    if (controller.allReports.isEmpty) {
      final Widget child = switch (controller.state) {
        LoadState.idle || LoadState.loading => const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: ReportListSkeleton(),
        ),
        LoadState.failure => ErrorState(
          error: controller.loadError!,
          onRetry: controller.load,
        ),
        LoadState.ready => EmptyState(
          icon: Icons.inventory_2_outlined,
          title: 'No reports yet',
          message: 'Be the first to report a lost or found item.',
          action: FilledButton.icon(
            onPressed: () => _push(const ReportFormScreen()),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Report item'),
          ),
        ),
      };
      return [
        SliverToBoxAdapter(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: KeyedSubtree(key: ValueKey(controller.state), child: child),
          ),
        ),
      ];
    }

    if (reports.isEmpty) {
      return [
        SliverToBoxAdapter(
          child: EmptyState(
            icon: Icons.search_off_rounded,
            title: 'No matching reports',
            message: 'Try a different search or clear the filters.',
            action: OutlinedButton(
              onPressed: () => _resetFilters(controller),
              child: const Text('Reset filters'),
            ),
          ),
        ),
      ];
    }

    return [
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        sliver: SliverList.separated(
          itemCount: reports.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final report = reports[index];
            return Entrance(
              key: ValueKey(report.id),
              index: index,
              child: ReportCard(
                report: report,
                onTap: () => _push(ItemDetailsScreen(reportId: report.id)),
              ),
            );
          },
        ),
      ),
    ];
  }
}

class _ListHeader extends StatelessWidget {
  const _ListHeader({
    required this.filter,
    required this.count,
    required this.onReset,
  });

  final ReportFilter filter;
  final int count;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: Semantics(
            header: true,
            child: Text(
              filter.isEmpty
                  ? 'Recently reported'
                  : '$count ${count == 1 ? 'result' : 'results'}',
              style: theme.textTheme.titleLarge,
            ),
          ),
        ),
        if (!filter.isEmpty)
          TextButton.icon(
            onPressed: onReset,
            icon: const Icon(Icons.filter_alt_off_rounded),
            label: const Text('Reset'),
          ),
      ],
    );
  }
}

class _RefreshErrorBanner extends StatelessWidget {
  const _RefreshErrorBanner({
    required this.message,
    required this.onRetry,
    required this.onDismiss,
  });

  final String message;
  final VoidCallback onRetry;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.errorContainer,
      borderRadius: BorderRadius.circular(AppTheme.fieldRadius),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 4, 8),
        child: Row(
          children: [
            Icon(Icons.cloud_off_rounded, color: colors.onErrorContainer),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: colors.onErrorContainer),
              ),
            ),
            TextButton(onPressed: onRetry, child: const Text('Retry')),
            IconButton(
              tooltip: 'Dismiss',
              onPressed: onDismiss,
              icon: const Icon(Icons.close_rounded),
            ),
          ],
        ),
      ),
    );
  }
}
