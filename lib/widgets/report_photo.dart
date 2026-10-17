import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/findly_colors.dart';
import '../models/item_report.dart';
import '../state/reports_controller.dart';
import 'category_icon.dart';

/// A report's photo, or its category icon when there is no photo or the
/// photo cannot be loaded. Photos fade in once downloaded.
class ReportPhoto extends StatelessWidget {
  const ReportPhoto({
    super.key,
    required this.report,
    this.borderRadius = 16,
    this.iconSize = 32,
  });

  final ItemReport report;
  final double borderRadius;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final url = context.select<ReportsController, String?>(
      (c) => c.photoUrlFor(report),
    );
    final placeholder = _CategoryPlaceholder(
      report: report,
      iconSize: iconSize,
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: url == null
          ? placeholder
          : Image.network(
              url,
              fit: BoxFit.cover,
              semanticLabel: 'Photo of ${report.title}',
              frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                if (wasSynchronouslyLoaded) return child;
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    placeholder,
                    AnimatedOpacity(
                      opacity: frame == null ? 0 : 1,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                      child: child,
                    ),
                  ],
                );
              },
              errorBuilder: (context, error, stackTrace) => placeholder,
            ),
    );
  }
}

class _CategoryPlaceholder extends StatelessWidget {
  const _CategoryPlaceholder({required this.report, required this.iconSize});

  final ItemReport report;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final tone = context.findly.forType(report.type);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            tone.background,
            Color.lerp(tone.background, tone.foreground, 0.12)!,
          ],
        ),
      ),
      child: Center(
        child: Icon(
          report.category.icon,
          size: iconSize,
          color: tone.foreground.withValues(alpha: 0.8),
          semanticLabel: report.category.label,
        ),
      ),
    );
  }
}
