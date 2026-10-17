import 'package:flutter/material.dart';

import '../core/utils/date_utils.dart';
import '../models/item_report.dart';
import '../models/report_status.dart';
import 'app_card.dart';
import 'report_badges.dart';
import 'report_photo.dart';

/// List item summarising a report. The whole card is one tap target.
class ReportCard extends StatelessWidget {
  const ReportCard({super.key, required this.report, required this.onTap});

  final ItemReport report;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final isResolved = report.status == ReportStatus.resolved;

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox.square(
            dimension: 76,
            child: Opacity(
              opacity: isResolved ? 0.55 : 1,
              child: ReportPhoto(report: report, borderRadius: 18),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          TypeBadge(report.type),
                          if (isResolved) StatusBadge(report.status),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      formatRelativeDate(report.createdAt),
                      style: theme.textTheme.labelSmall?.copyWith(color: muted),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  report.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(height: 1.25),
                ),
                const SizedBox(height: 4),
                _MetaLine(icon: Icons.place_outlined, text: report.location),
                const SizedBox(height: 2),
                _MetaLine(
                  icon: Icons.event_outlined,
                  text:
                      '${report.type.label} ${formatDisplayDate(report.eventDate)} · ${report.category.label}',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaLine extends StatelessWidget {
  const _MetaLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.onSurfaceVariant;
    return Row(
      children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(color: color),
          ),
        ),
      ],
    );
  }
}
