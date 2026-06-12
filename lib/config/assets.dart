/// Typed asset constants — the only place asset paths and font family
/// names are spelled out.
abstract final class AppFonts {
  /// Latin/UI font (variable weight). Default numerals; tabular for countdowns.
  static const ui = 'SchibstedGrotesk';

  /// Bengali script with full conjunct rendering. Bengali digits.
  static const bengali = 'NotoSansBengali';

  /// UI Arabic (labels in RTL locales). Eastern Arabic digits.
  static const arabicUi = 'IBMPlexSansArabic';

  /// KFGQPC Uthmanic Script HAFS — Quran text only, never UI.
  static const quran = 'UthmanicHafs';

  /// Fallback chain for UI text so Bengali/Arabic glyphs always render.
  static const uiFallback = [bengali, arabicUi];
}
