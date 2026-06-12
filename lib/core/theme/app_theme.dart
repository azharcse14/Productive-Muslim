import 'package:flutter/material.dart';

import 'qalbee_colors.dart';
import 'qalbee_tokens.dart';
import 'qalbee_typography.dart';

/// Builds the two designed themes. Dark is its own palette
/// (comfortable at Fajr/Tahajjud) — never an inversion of light.
///
/// Material 3 is mandatory (guide §2): `useMaterial3` is Flutter's default
/// and must never be disabled; only M3 APIs (ColorScheme, WidgetState,
/// NavigationBar theming) are used here.
abstract final class AppTheme {
  static ThemeData light() => _build(QalbeeColors.light, Brightness.light);

  static ThemeData dark() => _build(QalbeeColors.dark, Brightness.dark);

  static ThemeData _build(QalbeeColors q, Brightness brightness) {
    final scheme = ColorScheme(
      brightness: brightness,
      primary: q.primary,
      onPrimary: q.onPrimary,
      primaryContainer: q.primarySoft,
      onPrimaryContainer: q.onPrimarySoft,
      secondary: q.accent,
      onSecondary: brightness == Brightness.light
          ? const Color(0xFF231603)
          : const Color(0xFF231603),
      secondaryContainer: q.accentSoft,
      onSecondaryContainer: q.onAccentSoft,
      error: q.urgent,
      onError: q.urgentSoft,
      errorContainer: q.urgentSoft,
      onErrorContainer: q.urgent,
      surface: q.surface,
      onSurface: q.ink,
      onSurfaceVariant: q.ink2,
      surfaceContainerLowest: q.bg,
      surfaceContainerLow: q.surface,
      surfaceContainer: q.surface2,
      outline: q.line,
      outlineVariant: q.line,
      scrim: q.scrim,
    );

    final textTheme = QType.textTheme(q.ink, q.ink2);

    return ThemeData(
      colorScheme: scheme,
      brightness: brightness,
      scaffoldBackgroundColor: q.bg,
      textTheme: textTheme,
      splashFactory: InkSparkle.splashFactory,
      visualDensity: VisualDensity.standard,
      extensions: [q],
      appBarTheme: AppBarTheme(
        backgroundColor: q.bg,
        foregroundColor: q.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: QType.title.copyWith(color: q.ink),
      ),
      cardTheme: CardThemeData(
        color: q.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(QRadius.lg),
          side: BorderSide(color: q.line),
        ),
        margin: EdgeInsets.zero,
      ),
      dividerTheme: DividerThemeData(color: q.line, thickness: 1, space: 1),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: q.surface,
        modalBarrierColor: q.scrim,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(QRadius.sheetTop),
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: q.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(QRadius.lg),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? q.onPrimary
              : q.ink3,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? q.primary
              : q.surface2,
        ),
        trackOutlineColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? q.primary
              : q.line,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: q.surface,
        indicatorColor: q.primarySoft,
        height: 64,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => QType.caption.copyWith(
            fontSize: 10.5,
            color: states.contains(WidgetState.selected) ? q.ink : q.ink3,
            fontVariations: [
              FontVariation(
                'wght',
                states.contains(WidgetState.selected) ? 700 : 500,
              ),
            ],
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 20,
            color: states.contains(WidgetState.selected)
                ? q.onPrimarySoft
                : q.ink3,
          ),
        ),
      ),
    );
  }
}
