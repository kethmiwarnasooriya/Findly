import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../core/theme/findly_colors.dart';
import 'findly_logo.dart';

/// Whether the user asked the system to reduce motion.
bool _reduceMotion(BuildContext context) =>
    MediaQuery.maybeDisableAnimationsOf(context) ?? false;

/// The logo breathing inside a spinning coral arc. Used for full-screen and
/// section loading states.
class FindlyLoader extends StatefulWidget {
  const FindlyLoader({super.key, this.size = 72, this.label = 'Loading'});

  final double size;
  final String label;

  @override
  State<FindlyLoader> createState() => _FindlyLoaderState();
}

class _FindlyLoaderState extends State<FindlyLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_reduceMotion(context)) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = context.findly.accent;
    final size = widget.size;
    return Semantics(
      label: widget.label,
      liveRegion: true,
      child: SizedBox.square(
        dimension: size * 1.45,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final t = _controller.value;
            final pulse = 0.94 + 0.06 * math.sin(t * 2 * math.pi);
            return CustomPaint(
              painter: _ArcPainter(progress: t, color: accent),
              child: Center(
                child: Transform.scale(scale: pulse, child: child),
              ),
            );
          },
          child: FindlyLogo(size: size),
        ),
      ),
    );
  }
}

class _ArcPainter extends CustomPainter {
  _ArcPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.shortestSide * 0.045;
    final rect = (Offset.zero & size).deflate(stroke);
    canvas.drawArc(
      rect,
      progress * 2 * math.pi - math.pi / 2,
      math.pi * 0.6,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_ArcPainter old) =>
      old.progress != progress || old.color != color;
}

/// Full-screen brand splash shown while the app starts up.
class BootSplash extends StatelessWidget {
  const BootSplash({super.key});

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Color(0xFF123A2F),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FindlyLoader(size: 84, label: 'Starting Findly'),
            SizedBox(height: 20),
            Text(
              'Findly',
              textDirection: TextDirection.ltr,
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontWeight: FontWeight.w700,
                fontSize: 30,
                color: Colors.white,
                letterSpacing: -0.5,
                decoration: TextDecoration.none,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Lost something? Find your way back.',
              textDirection: TextDirection.ltr,
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 14,
                color: Color(0xFFB4D3C6),
                decoration: TextDecoration.none,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Sweeps a soft highlight across its child to signal loading.
class Shimmer extends StatefulWidget {
  const Shimmer({super.key, required this.child});

  final Widget child;

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_reduceMotion(context)) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final base = scheme.surfaceContainerHigh;
    final highlight = scheme.surfaceContainerLowest;
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        final x = _controller.value * 3 - 1.5;
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) => LinearGradient(
            begin: Alignment(x - 1, -0.3),
            end: Alignment(x + 1, 0.3),
            colors: [base, highlight, base],
            stops: const [0.35, 0.5, 0.65],
          ).createShader(bounds),
          child: child,
        );
      },
    );
  }
}

/// Placeholder block used inside skeletons.
class SkeletonBox extends StatelessWidget {
  const SkeletonBox({
    super.key,
    this.width,
    required this.height,
    this.radius = 8,
  });

  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

/// Skeleton matching the shape of a report card.
class ReportCardSkeleton extends StatelessWidget {
  const ReportCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.findly.card,
        borderRadius: BorderRadius.circular(AppTheme.radius),
      ),
      child: const Row(
        children: [
          SkeletonBox(width: 72, height: 72, radius: 18),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox(width: 64, height: 18, radius: 9),
                SizedBox(height: 10),
                SkeletonBox(height: 14),
                SizedBox(height: 8),
                SkeletonBox(width: 140, height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A shimmering list of [count] report-card skeletons.
class ReportListSkeleton extends StatelessWidget {
  const ReportListSkeleton({super.key, this.count = 4});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Loading reports',
      child: ExcludeSemantics(
        child: Shimmer(
          child: Column(
            children: [
              for (var i = 0; i < count; i++) ...[
                if (i > 0) const SizedBox(height: 12),
                const ReportCardSkeleton(),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
