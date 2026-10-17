import 'package:flutter/material.dart';

import 'findly_colors.dart';

abstract final class AppTheme {
  static const fontFamily = 'Poppins';
  static const radius = 22.0;
  static const fieldRadius = 16.0;
  static const headerRadius = 40.0;

  static ThemeData light() => _build(
    brightness: Brightness.light,
    brand: FindlyColors.light,
    scheme:
        ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E5A47),
          brightness: Brightness.light,
        ).copyWith(
          primary: const Color(0xFF1E5A47),
          onPrimary: Colors.white,
          primaryContainer: const Color(0xFFD3EADF),
          onPrimaryContainer: const Color(0xFF0A2A20),
          secondary: const Color(0xFFC9533A),
          onSecondary: Colors.white,
          secondaryContainer: const Color(0xFFFCE3DA),
          onSecondaryContainer: const Color(0xFF3D1308),
          surface: const Color(0xFFF6F4EF),
          onSurface: const Color(0xFF1B1D1B),
          onSurfaceVariant: const Color(0xFF5A5E5A),
          surfaceContainerLowest: Colors.white,
          surfaceContainerLow: const Color(0xFFF1EEE8),
          surfaceContainer: const Color(0xFFECE9E2),
          surfaceContainerHigh: const Color(0xFFE6E2DA),
          surfaceContainerHighest: const Color(0xFFE0DBD2),
          outline: const Color(0xFF8A8A84),
          outlineVariant: const Color(0xFFE3DFD7),
        ),
  );

  static ThemeData dark() => _build(
    brightness: Brightness.dark,
    brand: FindlyColors.dark,
    scheme:
        ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E5A47),
          brightness: Brightness.dark,
        ).copyWith(
          primary: const Color(0xFF86D4B5),
          onPrimary: const Color(0xFF00382A),
          primaryContainer: const Color(0xFF1D4A3C),
          onPrimaryContainer: const Color(0xFFBFEBD9),
          secondary: const Color(0xFFFF9A80),
          onSecondary: const Color(0xFF4A1206),
          secondaryContainer: const Color(0xFF5C2414),
          onSecondaryContainer: const Color(0xFFFFDAD0),
          surface: const Color(0xFF0E1512),
          onSurface: const Color(0xFFE4E8E5),
          onSurfaceVariant: const Color(0xFFA9B2AD),
          surfaceContainerLowest: const Color(0xFF18221E),
          surfaceContainerLow: const Color(0xFF151E1A),
          surfaceContainer: const Color(0xFF1B2521),
          surfaceContainerHigh: const Color(0xFF222D28),
          surfaceContainerHighest: const Color(0xFF2A3530),
          outline: const Color(0xFF7D8782),
          outlineVariant: const Color(0xFF2C3732),
        ),
  );

  static ThemeData _build({
    required Brightness brightness,
    required ColorScheme scheme,
    required FindlyColors brand,
  }) {
    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      fontFamily: fontFamily,
    );
    final text = base.textTheme.apply(
      bodyColor: scheme.onSurface,
      displayColor: scheme.onSurface,
    );

    final fieldBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(fieldRadius),
      borderSide: BorderSide(color: scheme.outlineVariant),
    );

    return base.copyWith(
      scaffoldBackgroundColor: scheme.surface,
      extensions: [brand],
      textTheme: text.copyWith(
        headlineMedium: text.headlineMedium?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
        headlineSmall: text.headlineSmall?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
        titleLarge: text.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        titleMedium: text.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        titleSmall: text.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        labelLarge: text.labelLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        titleTextStyle: text.titleLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
      cardTheme: CardThemeData(
        color: brand.card,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: brand.card,
        border: fieldBorder,
        enabledBorder: fieldBorder,
        focusedBorder: fieldBorder.copyWith(
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        errorBorder: fieldBorder.copyWith(
          borderSide: BorderSide(color: scheme.error),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(fieldRadius),
          ),
          textStyle: text.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 54),
          side: BorderSide(color: scheme.outlineVariant, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(fieldRadius),
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: brand.accent,
        foregroundColor: brand.onAccent,
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: brand.card,
        selectedColor: scheme.primaryContainer,
        side: BorderSide(color: scheme.outlineVariant),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        labelStyle: text.labelLarge?.copyWith(fontWeight: FontWeight.w500),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          selectedBackgroundColor: scheme.primaryContainer,
          selectedForegroundColor: scheme.onPrimaryContainer,
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: brand.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: brand.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      dividerTheme: DividerThemeData(color: scheme.outlineVariant, space: 1),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
        },
      ),
    );
  }
}
