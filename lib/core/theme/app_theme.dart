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
      // Honey is for celebrations only — Material's secondary/tertiary roles
      // (selected chips, nav indicators, …) stay in the calm families.
      secondary: q.onPrimarySoft,
      onSecondary: q.primarySoft,
      secondaryContainer: q.primarySoft,
      onSecondaryContainer: q.onPrimarySoft,
      tertiary: q.ok,
      onTertiary: q.okSoft,
      tertiaryContainer: q.okSoft,
      onTertiaryContainer: q.ok,
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
      // Filled, rounded fields on the token palette (matches the Quran
      // search field); errors use the urgent tone.
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: q.surface,
        labelStyle: QType.body.copyWith(color: q.ink2),
        floatingLabelStyle: WidgetStateTextStyle.resolveWith(
          (states) => QType.label.copyWith(
            color: states.contains(WidgetState.error)
                ? q.urgent
                : states.contains(WidgetState.focused)
                ? q.primary
                : q.ink2,
          ),
        ),
        hintStyle: QType.body.copyWith(color: q.ink3),
        helperStyle: QType.caption.copyWith(color: q.ink2),
        errorStyle: QType.caption.copyWith(color: q.urgent),
        prefixIconColor: q.ink2,
        suffixIconColor: q.ink2,
        border: _field(q.lineStrong, 1.5),
        enabledBorder: _field(q.lineStrong, 1.5),
        focusedBorder: _field(q.primary, 2),
        errorBorder: _field(q.urgent, 1.5),
        focusedErrorBorder: _field(q.urgent, 2),
        disabledBorder: _field(q.line, 1),
      ),
      // Stock FilledButton matches QButton primary: 52dp teal pill.
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: q.primary,
          foregroundColor: q.onPrimary,
          minimumSize: const Size(64, 52),
          padding: const EdgeInsets.symmetric(horizontal: QSpace.s6),
          shape: const StadiumBorder(),
          textStyle: QType.button,
        ),
      ),
      // Stock ListTile / SwitchListTile match QListRow.
      listTileTheme: ListTileThemeData(
        minTileHeight: 56,
        minVerticalPadding: 10,
        iconColor: q.ink2,
        textColor: q.ink,
        titleTextStyle: QType.titleSm.copyWith(color: q.ink),
        subtitleTextStyle: QType.caption.copyWith(color: q.ink2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(QRadius.md),
        ),
      ),
      // Stock chips match QChip: pill, strong outline when unselected.
      chipTheme: ChipThemeData(
        shape: const StadiumBorder(),
        side: WidgetStateBorderSide.resolveWith(
          (states) => BorderSide(
            color: states.contains(WidgetState.selected)
                ? q.primary
                : q.lineStrong,
            width: 1.5,
          ),
        ),
      ),
      // Inverse bar: ink fill with page-colored text in both themes.
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: q.ink,
        contentTextStyle: QType.body.copyWith(color: q.bg),
        actionTextColor: q.primarySoft,
        closeIconColor: q.bg,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(QRadius.md),
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

  static OutlineInputBorder _field(Color color, double width) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(QRadius.md),
        borderSide: BorderSide(color: color, width: width),
      );
}
