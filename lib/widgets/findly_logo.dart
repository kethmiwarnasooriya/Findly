import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

/// Findly's mark: a magnifying lens with a location pin inside, a coral
/// handle and a small sparkle, on a rounded green tile.
///
/// The same painter generates the launcher icon (see
/// `tool/generate_icons_test.dart`), so the app icon and in-app logo match.
class FindlyLogo extends StatelessWidget {
  const FindlyLogo({super.key, this.size = 48, this.showTile = true});

  final double size;
  final bool showTile;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Findly logo',
      image: true,
      child: CustomPaint(
        size: Size.square(size),
        painter: FindlyLogoPainter(showTile: showTile),
      ),
    );
  }
}

/// Logo plus the "Findly" wordmark.
class FindlyWordmark extends StatelessWidget {
  const FindlyWordmark({super.key, this.logoSize = 40, this.color});

  final double logoSize;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ExcludeSemantics(child: FindlyLogo(size: logoSize)),
        SizedBox(width: logoSize * 0.28),
        Text(
          'Findly',
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            fontWeight: FontWeight.w700,
            fontSize: logoSize * 0.62,
            letterSpacing: -0.5,
            height: 1,
            color: color ?? Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}

class FindlyLogoPainter extends CustomPainter {
  const FindlyLogoPainter({this.showTile = true, this.monochrome = false});

  /// Draw the rounded green background tile.
  final bool showTile;

  /// Paint every element in white (Android themed/monochrome icons).
  final bool monochrome;

  static const tileTop = Color(0xFF24654F);
  static const tileBottom = Color(0xFF0F3328);
  static const lensColor = Colors.white;
  static const handleColor = Color(0xFFF08A6E);
  static const pinColor = Color(0xFFF08A6E);
  static const sparkleColor = Color(0xFFA9E5CD);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    Color tone(Color c) => monochrome ? Colors.white : c;

    if (showTile) {
      final tile = RRect.fromRectAndRadius(
        Offset.zero & Size.square(s),
        Radius.circular(s * 0.28),
      );
      canvas.drawRRect(
        tile,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [tileTop, tileBottom],
          ).createShader(tile.outerRect),
      );
    }

    final lensCenter = Offset(s * 0.43, s * 0.43);
    final lensRadius = s * 0.215;
    final ringWidth = s * 0.075;

    // Handle, drawn first so the ring overlaps its end cleanly.
    const diagonal = math.sqrt1_2;
    final handleStart =
        lensCenter +
        Offset(diagonal, diagonal) * (lensRadius + ringWidth * 0.2);
    canvas.drawLine(
      handleStart,
      Offset(s * 0.79, s * 0.79),
      Paint()
        ..color = tone(handleColor)
        ..strokeWidth = s * 0.105
        ..strokeCap = StrokeCap.round,
    );

    // Lens ring.
    canvas.drawCircle(
      lensCenter,
      lensRadius,
      Paint()
        ..color = tone(lensColor)
        ..style = PaintingStyle.stroke
        ..strokeWidth = ringWidth,
    );

    // Location pin inside the lens.
    final pinRadius = s * 0.075;
    final pinCenter = lensCenter - Offset(0, s * 0.04);
    canvas.drawPath(
      _pinPath(pinCenter, pinRadius),
      Paint()..color = tone(pinColor),
    );

    // Sparkle: "found it!".
    canvas.drawPath(
      _sparklePath(Offset(s * 0.77, s * 0.22), s * 0.075),
      Paint()..color = tone(sparkleColor),
    );
  }

  /// Teardrop pin with a round hole, tip pointing down.
  static Path _pinPath(Offset c, double r) {
    final tip = Offset(c.dx, c.dy + r * 2.0);
    final outline = Path()
      ..moveTo(tip.dx, tip.dy)
      ..cubicTo(
        c.dx - r * 0.35,
        c.dy + r * 1.3,
        c.dx - r,
        c.dy + r * 0.65,
        c.dx - r,
        c.dy,
      )
      ..arcToPoint(Offset(c.dx + r, c.dy), radius: Radius.circular(r))
      ..cubicTo(
        c.dx + r,
        c.dy + r * 0.65,
        c.dx + r * 0.35,
        c.dy + r * 1.3,
        tip.dx,
        tip.dy,
      )
      ..close();
    final hole = Path()..addOval(Rect.fromCircle(center: c, radius: r * 0.42));
    return Path.combine(PathOperation.difference, outline, hole);
  }

  /// Four-pointed star with concave sides.
  static Path _sparklePath(Offset c, double r) {
    final inner = r * 0.28;
    return Path()
      ..moveTo(c.dx, c.dy - r)
      ..quadraticBezierTo(
        c.dx + inner * 0.4,
        c.dy - inner * 0.4,
        c.dx + r,
        c.dy,
      )
      ..quadraticBezierTo(
        c.dx + inner * 0.4,
        c.dy + inner * 0.4,
        c.dx,
        c.dy + r,
      )
      ..quadraticBezierTo(
        c.dx - inner * 0.4,
        c.dy + inner * 0.4,
        c.dx - r,
        c.dy,
      )
      ..quadraticBezierTo(
        c.dx - inner * 0.4,
        c.dy - inner * 0.4,
        c.dx,
        c.dy - r,
      )
      ..close();
  }

  @override
  bool shouldRepaint(FindlyLogoPainter oldDelegate) =>
      oldDelegate.showTile != showTile || oldDelegate.monochrome != monochrome;
}
