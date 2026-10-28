import 'package:flutter/material.dart';

/// All Productive Muslim color tokens beyond Material's [ColorScheme], mapped 1:1 from
/// `docs/design_handoff_productive_muslim/productive_muslim/tokens.css`. Feature widgets read these
/// via `Theme.of(context).extension<ProductiveMuslimColors>()` — never inline colors.
@immutable
final class ProductiveMuslimColors
    extends ThemeExtension<ProductiveMuslimColors> {
  const ProductiveMuslimColors({
    required this.bg,
    required this.surface,
    required this.surface2,
    required this.ink,
    required this.ink2,
    required this.ink3,
    required this.line,
    required this.primary,
    required this.onPrimary,
    required this.primarySoft,
    required this.onPrimarySoft,
    required this.accent,
    required this.onAccent,
    required this.accentStrong,
    required this.accentSoft,
    required this.onAccentSoft,
    required this.ok,
    required this.okSoft,
    required this.warn,
    required this.warnSoft,
    required this.urgent,
    required this.urgentSoft,
    required this.scrim,
  });

  /// Screen background — warm paper (light) / teal-black (dark).
  final Color bg;

  /// Cards and sheets.
  final Color surface;

  /// Skeletons, segmented-control track, heatmap level 0.
  final Color surface2;

  /// Primary text.
  final Color ink;

  /// Secondary text.
  final Color ink2;

  /// Hints and disabled text.
  final Color ink3;

  /// Hairlines and card borders.
  final Color line;

  /// Brand teal ("qalb teal").
  final Color primary;
  final Color onPrimary;

  /// Tonal containers, active row highlight.
  final Color primarySoft;
  final Color onPrimarySoft;

  /// Warm honey — celebrations ONLY (streaks, iftar, qibla lock).
  final Color accent;

  /// Text/icons on a solid [accent] fill.
  final Color onAccent;

  /// AA-safe accent text on light backgrounds.
  final Color accentStrong;
  final Color accentSoft;
  final Color onAccentSoft;

  /// Completed / prayed.
  final Color ok;
  final Color okSoft;

  /// Countdown "soon" (jamaat ≤10 min).
  final Color warn;
  final Color warnSoft;

  /// Countdown "urgent" (makruh / last 20 min) — never used for missed deeds.
  final Color urgent;
  final Color urgentSoft;

  /// Sheet/dialog scrim.
  final Color scrim;

  static const light = ProductiveMuslimColors(
    bg: Color(0xFFF6F4EE),
    surface: Color(0xFFFFFFFF),
    surface2: Color(0xFFEFEBE1),
    ink: Color(0xFF1F2A26),
    ink2: Color(0xFF5A6661),
    ink3: Color(0xFF656C68),
    line: Color(0xFFE4DFD3),
    primary: Color(0xFF15564D),
    onPrimary: Color(0xFFF2F7F5),
    primarySoft: Color(0xFFDCE9E4),
    onPrimarySoft: Color(0xFF123F39),
    accent: Color(0xFFC08A2E),
    onAccent: Color(0xFF231603),
    accentStrong: Color(0xFF8E5E12),
    accentSoft: Color(0xFFF4E6C8),
    onAccentSoft: Color(0xFF6E4A0E),
    ok: Color(0xFF246B45),
    okSoft: Color(0xFFDCEBDF),
    warn: Color(0xFF8E5E12),
    warnSoft: Color(0xFFF4E6C8),
    urgent: Color(0xFFA93B29),
    urgentSoft: Color(0xFFF6DDD6),
    scrim: Color.fromRGBO(20, 28, 26, 0.45),
  );

  static const dark = ProductiveMuslimColors(
    bg: Color(0xFF0E1513),
    surface: Color(0xFF16201D),
    surface2: Color(0xFF1D2A26),
    ink: Color(0xFFE4E9E4),
    ink2: Color(0xFF9BABA3),
    ink3: Color(0xFF80928A),
    line: Color(0xFF243029),
    primary: Color(0xFF79C7B6),
    onPrimary: Color(0xFF07231D),
    primarySoft: Color(0xFF1C332D),
    onPrimarySoft: Color(0xFFA7DACD),
    accent: Color(0xFFE2B264),
    onAccent: Color(0xFF231603),
    accentStrong: Color(0xFFE2B264),
    accentSoft: Color(0xFF322817),
    onAccentSoft: Color(0xFFEAC182),
    ok: Color(0xFF84C9A0),
    okSoft: Color(0xFF16271E),
    warn: Color(0xFFE2B264),
    warnSoft: Color(0xFF322817),
    urgent: Color(0xFFE78D77),
    urgentSoft: Color(0xFF36201B),
    scrim: Color.fromRGBO(4, 8, 7, 0.6),
  );

  @override
  ProductiveMuslimColors copyWith({
    Color? bg,
    Color? surface,
    Color? surface2,
    Color? ink,
    Color? ink2,
    Color? ink3,
    Color? line,
    Color? primary,
    Color? onPrimary,
    Color? primarySoft,
    Color? onPrimarySoft,
    Color? accent,
    Color? onAccent,
    Color? accentStrong,
    Color? accentSoft,
    Color? onAccentSoft,
    Color? ok,
    Color? okSoft,
    Color? warn,
    Color? warnSoft,
    Color? urgent,
    Color? urgentSoft,
    Color? scrim,
  }) {
    return ProductiveMuslimColors(
      bg: bg ?? this.bg,
      surface: surface ?? this.surface,
      surface2: surface2 ?? this.surface2,
      ink: ink ?? this.ink,
      ink2: ink2 ?? this.ink2,
      ink3: ink3 ?? this.ink3,
      line: line ?? this.line,
      primary: primary ?? this.primary,
      onPrimary: onPrimary ?? this.onPrimary,
      primarySoft: primarySoft ?? this.primarySoft,
      onPrimarySoft: onPrimarySoft ?? this.onPrimarySoft,
      accent: accent ?? this.accent,
      onAccent: onAccent ?? this.onAccent,
      accentStrong: accentStrong ?? this.accentStrong,
      accentSoft: accentSoft ?? this.accentSoft,
      onAccentSoft: onAccentSoft ?? this.onAccentSoft,
      ok: ok ?? this.ok,
      okSoft: okSoft ?? this.okSoft,
      warn: warn ?? this.warn,
      warnSoft: warnSoft ?? this.warnSoft,
      urgent: urgent ?? this.urgent,
      urgentSoft: urgentSoft ?? this.urgentSoft,
      scrim: scrim ?? this.scrim,
    );
  }

  @override
  ProductiveMuslimColors lerp(ProductiveMuslimColors? other, double t) {
    if (other == null) {
      return this;
    }
    return ProductiveMuslimColors(
      bg: Color.lerp(bg, other.bg, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surface2: Color.lerp(surface2, other.surface2, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      ink2: Color.lerp(ink2, other.ink2, t)!,
      ink3: Color.lerp(ink3, other.ink3, t)!,
      line: Color.lerp(line, other.line, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      onPrimary: Color.lerp(onPrimary, other.onPrimary, t)!,
      primarySoft: Color.lerp(primarySoft, other.primarySoft, t)!,
      onPrimarySoft: Color.lerp(onPrimarySoft, other.onPrimarySoft, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      onAccent: Color.lerp(onAccent, other.onAccent, t)!,
      accentStrong: Color.lerp(accentStrong, other.accentStrong, t)!,
      accentSoft: Color.lerp(accentSoft, other.accentSoft, t)!,
      onAccentSoft: Color.lerp(onAccentSoft, other.onAccentSoft, t)!,
      ok: Color.lerp(ok, other.ok, t)!,
      okSoft: Color.lerp(okSoft, other.okSoft, t)!,
      warn: Color.lerp(warn, other.warn, t)!,
      warnSoft: Color.lerp(warnSoft, other.warnSoft, t)!,
      urgent: Color.lerp(urgent, other.urgent, t)!,
      urgentSoft: Color.lerp(urgentSoft, other.urgentSoft, t)!,
      scrim: Color.lerp(scrim, other.scrim, t)!,
    );
  }
}
