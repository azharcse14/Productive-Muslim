import 'package:flutter/material.dart';

import '../../config/assets.dart';

import 'productive_muslim_colors.dart';
import 'productive_muslim_tokens.dart';
import 'productive_muslim_typography.dart';

/// Builds the two designed themes. Dark is its own palette
/// (comfortable at Fajr/Tahajjud) — never an inversion of light.
///
/// Material 3 is mandatory (guide §2): `useMaterial3` is Flutter's default
/// and must never be disabled; only M3 APIs (ColorScheme, WidgetState)
/// are used here.
abstract final class AppTheme {
  static ThemeData light() =>
      _build(ProductiveMuslimColors.light, Brightness.light);

  static ThemeData dark() =>
      _build(ProductiveMuslimColors.dark, Brightness.dark);

  static ThemeData _build(ProductiveMuslimColors q, Brightness brightness) {
    final scheme = ColorScheme(
      brightness: brightness,
      primary: q.primary,
      onPrimary: q.onPrimary,
      primaryContainer: q.primarySoft,
      onPrimaryContainer: q.onPrimarySoft,
      secondary: q.accent,
      onSecondary: q.onAccent,
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
      // Dialogs, fields and other framework text outside [textTheme].
      fontFamily: AppFonts.ui,
      fontFamilyFallback: AppFonts.uiFallback,
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
          (states) =>
              states.contains(WidgetState.selected) ? q.onPrimary : q.ink3,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? q.primary : q.surface2,
        ),
        trackOutlineColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? q.primary : q.line,
        ),
      ),
    );
  }
}
