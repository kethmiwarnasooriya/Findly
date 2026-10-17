import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/findly_colors.dart';
import '../../widgets/findly_logo.dart';
import '../../widgets/header_panel.dart';

/// Illustrated header for the sign-in screen: the logo surrounded by
/// everyday items that drift gently.
class AuthHero extends StatefulWidget {
  const AuthHero({super.key});

  @override
  State<AuthHero> createState() => _AuthHeroState();
}

class _AuthHeroState extends State<AuthHero>
    with SingleTickerProviderStateMixin {
  late final AnimationController _float = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 4),
  );

  static const _items = [
    (Icons.backpack_rounded, Alignment(-0.82, -0.55)),
    (Icons.key_rounded, Alignment(0.80, -0.70)),
    (Icons.account_balance_wallet_rounded, Alignment(-0.70, 0.62)),
    (Icons.headphones_rounded, Alignment(0.86, 0.45)),
    (Icons.badge_rounded, Alignment(0.05, -1.0)),
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      _float.stop();
    } else if (!_float.isAnimating) {
      _float.repeat();
    }
  }

  @override
  void dispose() {
    _float.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brand = context.findly;
    final textTheme = Theme.of(context).textTheme;

    return HeaderPanel(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        children: [
          SizedBox(
            height: 190,
            child: ExcludeSemantics(
              child: AnimatedBuilder(
                animation: _float,
                builder: (context, _) {
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: brand.headerField,
                        ),
                      ),
                      for (final (index, (icon, alignment)) in _items.indexed)
                        Align(
                          alignment: alignment,
                          child: Transform.translate(
                            offset: Offset(
                              0,
                              6 *
                                  math.sin(
                                    (_float.value + index * 0.2) * 2 * math.pi,
                                  ),
                            ),
                            child: _FloatingItem(icon: icon),
                          ),
                        ),
                      const FindlyLogo(size: 92),
                    ],
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Findly',
            style: textTheme.headlineMedium?.copyWith(color: brand.onHeader),
          ),
          const SizedBox(height: 4),
          Text(
            'Lost something? Find your way back.',
            textAlign: TextAlign.center,
            style: textTheme.bodyLarge?.copyWith(color: brand.onHeaderMuted),
          ),
        ],
      ),
    );
  }
}

class _FloatingItem extends StatelessWidget {
  const _FloatingItem({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final brand = context.findly;
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: brand.card,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Icon(icon, color: brand.accent, size: 22),
    );
  }
}
