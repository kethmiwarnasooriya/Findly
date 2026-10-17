import 'package:flutter/material.dart';

import '../core/theme/findly_colors.dart';
import '../models/report_status.dart';
import '../models/report_type.dart';

/// Small rounded label used for report type and status.
class PillBadge extends StatelessWidget {
  const PillBadge({
    super.key,
    required this.label,
    required this.colors,
    this.icon,
  });

  final String label;
  final ToneColors colors;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: colors.foreground),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: colors.foreground,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

IconData reportTypeIcon(ReportType type) => type == ReportType.lost
    ? Icons.search_rounded
    : Icons.volunteer_activism_rounded;

class TypeBadge extends StatelessWidget {
  const TypeBadge(this.type, {super.key});
  final ReportType type;

  @override
  Widget build(BuildContext context) => PillBadge(
    label: type.label,
    colors: context.findly.forType(type),
    icon: reportTypeIcon(type),
  );
}

class StatusBadge extends StatelessWidget {
  const StatusBadge(this.status, {super.key});
  final ReportStatus status;

  @override
  Widget build(BuildContext context) => PillBadge(
    label: status.label,
    colors: context.findly.forStatus(status),
    icon: status == ReportStatus.resolved
        ? Icons.check_circle_rounded
        : Icons.schedule_rounded,
  );
}
