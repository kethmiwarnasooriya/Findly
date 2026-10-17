import 'package:flutter/material.dart';

import '../../models/report_status.dart';
import '../../models/report_type.dart';

/// A background/foreground pair for badges and tinted surfaces.
@immutable
class ToneColors {
  const ToneColors(this.background, this.foreground);
  final Color background;
  final Color foreground;

  static ToneColors lerp(ToneColors a, ToneColors b, double t) => ToneColors(
    Color.lerp(a.background, b.background, t)!,
    Color.lerp(a.foreground, b.foreground, t)!,
  );
}

/// Brand colours that Material's [ColorScheme] has no slot for, with light
/// and dark variants. Read them with `context.findly`.
@immutable
class FindlyColors extends ThemeExtension<FindlyColors> {
  const FindlyColors({
    required this.header,
    required this.onHeader,
    required this.onHeaderMuted,
    required this.headerField,
    required this.accent,
    required this.onAccent,
    required this.card,
    required this.cardShadow,
    required this.lost,
    required this.found,
    required this.active,
    required this.resolved,
    required this.notice,
  });

  /// Deep green used for the curved header panels.
  final Color header;
  final Color onHeader;
  final Color onHeaderMuted;

  /// Fill of inputs and pill tabs placed on the header.
  final Color headerField;

  /// Coral call-to-action colour (report button, highlights).
  final Color accent;
  final Color onAccent;

  final Color card;
  final Color cardShadow;

  final ToneColors lost;
  final ToneColors found;
  final ToneColors active;
  final ToneColors resolved;

  /// Amber tone for cautionary notes, e.g. the matching disclaimer.
  final ToneColors notice;

  ToneColors forType(ReportType type) => type == ReportType.lost ? lost : found;

  ToneColors forStatus(ReportStatus status) =>
      status == ReportStatus.active ? active : resolved;

  static const light = FindlyColors(
    header: Color(0xFF123A2F),
    onHeader: Colors.white,
    onHeaderMuted: Color(0xFFB4D3C6),
    headerField: Color(0xFF1E4C3F),
    accent: Color(0xFFC9533A),
    onAccent: Colors.white,
    card: Colors.white,
    cardShadow: Color(0x14123A2F),
    lost: ToneColors(Color(0xFFFCE3DA), Color(0xFF7A2511)),
    found: ToneColors(Color(0xFFD5EDE3), Color(0xFF0E4A38)),
    active: ToneColors(Color(0xFFFFF0C7), Color(0xFF5A4100)),
    resolved: ToneColors(Color(0xFFE8E6E1), Color(0xFF45423C)),
    notice: ToneColors(Color(0xFFFFF1CC), Color(0xFF4A3500)),
  );

  static const dark = FindlyColors(
    header: Color(0xFF163A30),
    onHeader: Colors.white,
    onHeaderMuted: Color(0xFF9CC2B3),
    headerField: Color(0xFF214A3E),
    accent: Color(0xFFD9603F),
    onAccent: Colors.white,
    card: Color(0xFF18221E),
    cardShadow: Color(0x33000000),
    lost: ToneColors(Color(0xFF4A2318), Color(0xFFFFC9B9)),
    found: ToneColors(Color(0xFF143F32), Color(0xFFA9E5CD)),
    active: ToneColors(Color(0xFF3E3310), Color(0xFFF3DB8C)),
    resolved: ToneColors(Color(0xFF2B2F2D), Color(0xFFC9CCC9)),
    notice: ToneColors(Color(0xFF3B3110), Color(0xFFF3DB8C)),
  );

  @override
  FindlyColors copyWith({Color? header, Color? accent}) => FindlyColors(
    header: header ?? this.header,
    onHeader: onHeader,
    onHeaderMuted: onHeaderMuted,
    headerField: headerField,
    accent: accent ?? this.accent,
    onAccent: onAccent,
    card: card,
    cardShadow: cardShadow,
    lost: lost,
    found: found,
    active: active,
    resolved: resolved,
    notice: notice,
  );

  @override
  FindlyColors lerp(FindlyColors? other, double t) {
    if (other == null) return this;
    Color c(Color a, Color b) => Color.lerp(a, b, t)!;
    return FindlyColors(
      header: c(header, other.header),
      onHeader: c(onHeader, other.onHeader),
      onHeaderMuted: c(onHeaderMuted, other.onHeaderMuted),
      headerField: c(headerField, other.headerField),
      accent: c(accent, other.accent),
      onAccent: c(onAccent, other.onAccent),
      card: c(card, other.card),
      cardShadow: c(cardShadow, other.cardShadow),
      lost: ToneColors.lerp(lost, other.lost, t),
      found: ToneColors.lerp(found, other.found, t),
      active: ToneColors.lerp(active, other.active, t),
      resolved: ToneColors.lerp(resolved, other.resolved, t),
      notice: ToneColors.lerp(notice, other.notice, t),
    );
  }
}

extension FindlyThemeContext on BuildContext {
  FindlyColors get findly =>
      Theme.of(this).extension<FindlyColors>() ?? FindlyColors.light;
}
