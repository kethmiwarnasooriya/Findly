import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/findly_colors.dart';
import '../../models/report_type.dart';
import '../../widgets/app_card.dart';
import '../../widgets/findly_logo.dart';
import '../../widgets/header_panel.dart';
import '../../widgets/report_badges.dart';

/// Curved header: brand, settings, search and the All/Lost/Found tabs.
class HomeHeader extends StatelessWidget {
  const HomeHeader({
    super.key,
    required this.searchController,
    required this.onSearchChanged,
    required this.selectedType,
    required this.onTypeChanged,
    required this.onOpenSettings,
  });

  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final ReportType? selectedType;
  final ValueChanged<ReportType?> onTypeChanged;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final brand = context.findly;
    final textTheme = Theme.of(context).textTheme;

    return HeaderPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Semantics(
                header: true,
                label: 'Findly',
                excludeSemantics: true,
                child: FindlyWordmark(logoSize: 38, color: brand.onHeader),
              ),
              const Spacer(),
              IconButton(
                tooltip: 'Settings',
                onPressed: onOpenSettings,
                style: IconButton.styleFrom(
                  backgroundColor: brand.headerField,
                  foregroundColor: brand.onHeader,
                ),
                icon: const Icon(Icons.tune_rounded),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Lost something? Find your way back.',
            style: textTheme.bodyMedium?.copyWith(color: brand.onHeaderMuted),
          ),
          const SizedBox(height: 14),
          _HeaderSearchField(
            controller: searchController,
            onChanged: onSearchChanged,
          ),
          const SizedBox(height: 14),
          PillTabs<ReportType?>(
            selected: selectedType,
            onChanged: onTypeChanged,
            tabs: const [
              PillTab(value: null, label: 'All'),
              PillTab(value: ReportType.lost, label: 'Lost'),
              PillTab(value: ReportType.found, label: 'Found'),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderSearchField extends StatelessWidget {
  const _HeaderSearchField({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final brand = context.findly;
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppTheme.fieldRadius),
      borderSide: BorderSide.none,
    );
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) => TextField(
        controller: controller,
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        style: TextStyle(color: brand.onHeader),
        cursorColor: brand.onHeader,
        decoration: InputDecoration(
          hintText: 'Search items, places, descriptions…',
          hintStyle: TextStyle(color: brand.onHeaderMuted),
          filled: true,
          fillColor: brand.headerField,
          border: border,
          enabledBorder: border,
          focusedBorder: border.copyWith(
            borderSide: BorderSide(color: brand.onHeaderMuted),
          ),
          prefixIcon: Icon(Icons.search_rounded, color: brand.onHeaderMuted),
          suffixIcon: value.text.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Clear search',
                  color: brand.onHeader,
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () {
                    controller.clear();
                    onChanged('');
                  },
                ),
        ),
      ),
    );
  }
}

/// Tappable count of active reports of one type.
class SummaryCard extends StatelessWidget {
  const SummaryCard({
    super.key,
    required this.label,
    required this.count,
    required this.type,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int count;
  final ReportType type;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tone = context.findly.forType(type);
    return Semantics(
      button: true,
      selected: selected,
      label: '$count $label',
      excludeSemantics: true,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.radius + 2),
          border: Border.all(
            color: selected ? tone.foreground : Colors.transparent,
            width: 2,
          ),
        ),
        child: AppCard(
          onTap: onTap,
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              IconTile(
                icon: reportTypeIcon(type),
                background: tone.background,
                foreground: tone.foreground,
                size: 44,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TweenAnimationBuilder<int>(
                      tween: IntTween(begin: 0, end: count),
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, _) => Text(
                        '$value',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          height: 1.1,
                        ),
                      ),
                    ),
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
