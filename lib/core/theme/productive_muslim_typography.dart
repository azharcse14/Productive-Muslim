import 'package:flutter/material.dart';

import '../../config/assets.dart';

/// Type scale from the design handoff (size/line-height · weight):
/// display 34/1.12·700 · headline 26/1.18·700 · title 19/1.25·600 ·
/// title-sm 16.5/1.3·600 · body 15/1.5·400 · label 13/1.35·600 ·
/// caption 11.5/1.4·500 · overline 11·700 (+1.4 tracking, uppercase).
abstract final class QType {
  /// Variable-font weight axis must be set explicitly; [FontWeight] alone
  /// does not drive the `wght` axis for variable TTFs.
  static List<FontVariation> _wght(double w) => [FontVariation('wght', w)];

  static TextStyle _base(
    double size,
    double height,
    double weight, {
    double spacing = 0,
  }) {
    return TextStyle(
      fontFamily: AppFonts.ui,
      fontFamilyFallback: AppFonts.uiFallback,
      fontSize: size,
      height: height,
      fontWeight: weight >= 700
          ? FontWeight.w700
          : weight >= 600
          ? FontWeight.w600
          : weight >= 500
          ? FontWeight.w500
          : FontWeight.w400,
      fontVariations: _wght(weight),
      letterSpacing: spacing,
    );
  }

  static final display = _base(34, 1.12, 700, spacing: -0.6);
  static final headline = _base(26, 1.18, 700, spacing: -0.4);
  static final title = _base(19, 1.25, 600, spacing: -0.2);
  static final titleSm = _base(16.5, 1.3, 600);
  static final body = _base(15, 1.5, 400);
  static final label = _base(13, 1.35, 600);
  static final caption = _base(11.5, 1.4, 500);
  static final overline = _base(11, 1.2, 700, spacing: 1.4);

  /// Countdown hero numeral: 56px·700, −1.5 tracking, tabular numerals.
  static final countdown = _base(
    56,
    1.05,
    700,
    spacing: -1.5,
  ).copyWith(fontFeatures: const [FontFeature.tabularFigures()]);

  /// Tabular-numeral variant of any style (times, counters).
  static TextStyle num_(TextStyle style) =>
      style.copyWith(fontFeatures: const [FontFeature.tabularFigures()]);

  /// Quran Arabic — KFGQPC Uthmanic HAFS only, independent user scale
  /// (22–44 in steps of 2, persisted separately from system font scale).
  static TextStyle quran(double size) =>
      TextStyle(fontFamily: AppFonts.quran, fontSize: size, height: 1.9);

  /// Material [TextTheme] wiring so framework widgets pick up the scale.
  /// Roles without a design size map to the nearest step of the scale.
  static TextTheme textTheme(Color ink, Color ink2) => TextTheme(
    displayLarge: display.copyWith(color: ink),
    displayMedium: display.copyWith(color: ink),
    displaySmall: display.copyWith(color: ink),
    headlineLarge: headline.copyWith(color: ink),
    headlineMedium: headline.copyWith(color: ink),
    headlineSmall: headline.copyWith(color: ink),
    titleLarge: title.copyWith(color: ink),
    titleMedium: titleSm.copyWith(color: ink),
    titleSmall: label.copyWith(color: ink),
    bodyLarge: body.copyWith(color: ink),
    bodyMedium: body.copyWith(color: ink),
    bodySmall: caption.copyWith(color: ink2),
    labelLarge: label.copyWith(color: ink),
    labelMedium: label.copyWith(color: ink),
    labelSmall: overline.copyWith(color: ink2),
  );
}
