import 'package:flutter/material.dart';

import '../../models/item_category.dart';
import '../../models/report_filter.dart';
import '../../models/report_status.dart';
import '../../widgets/category_icon.dart';

/// Status and category filter chips. Emits a new [ReportFilter] on change.
/// (The Lost/Found type filter lives in the header's pill tabs.)
class ReportFilterBar extends StatelessWidget {
  const ReportFilterBar({
    super.key,
    required this.filter,
    required this.onChanged,
  });

  final ReportFilter filter;
  final ValueChanged<ReportFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          for (final status in ReportStatus.values)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(status.label),
                selected: filter.status == status,
                onSelected: (selected) => onChanged(
                  filter.copyWith(status: () => selected ? status : null),
                ),
              ),
            ),
          const SizedBox(height: 24, child: VerticalDivider(width: 16)),
          for (final category in ItemCategory.values)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                avatar: Icon(category.icon, size: 18),
                label: Text(category.label),
                selected: filter.category == category,
                showCheckmark: false,
                onSelected: (selected) => onChanged(
                  filter.copyWith(category: () => selected ? category : null),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
