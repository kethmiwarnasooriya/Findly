import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../core/theme/findly_colors.dart';

/// Deep-green panel with a large rounded bottom-right corner, used at the
/// top of the main screens.
class HeaderPanel extends StatelessWidget {
  const HeaderPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(20, 12, 20, 28),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final brand = context.findly;
    return Container(
      decoration: BoxDecoration(
        color: brand.header,
        borderRadius: const BorderRadius.only(
          bottomRight: Radius.circular(AppTheme.headerRadius),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

/// One option in [PillTabs].
class PillTab<T> {
  const PillTab({required this.value, required this.label, this.icon});

  final T value;
  final String label;
  final IconData? icon;
}

/// Segmented pill selector designed to sit on a [HeaderPanel].
class PillTabs<T> extends StatelessWidget {
  const PillTabs({
    super.key,
    required this.tabs,
    required this.selected,
    required this.onChanged,
  });

  final List<PillTab<T>> tabs;
  final T selected;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final brand = context.findly;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: brand.headerField,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          for (final tab in tabs)
            Expanded(
              child: Semantics(
                button: true,
                selected: tab.value == selected,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onChanged(tab.value),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    constraints: const BoxConstraints(minHeight: 44),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: tab.value == selected
                          ? brand.header
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: tab.value == selected
                          ? const [
                              BoxShadow(
                                color: Color(0x33000000),
                                blurRadius: 8,
                                offset: Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (tab.icon != null) ...[
                          Icon(
                            tab.icon,
                            size: 16,
                            color: tab.value == selected
                                ? brand.onHeader
                                : brand.onHeaderMuted,
                          ),
                          const SizedBox(width: 6),
                        ],
                        Flexible(
                          child: Text(
                            tab.label,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.labelLarge?.copyWith(
                              color: tab.value == selected
                                  ? brand.onHeader
                                  : brand.onHeaderMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
