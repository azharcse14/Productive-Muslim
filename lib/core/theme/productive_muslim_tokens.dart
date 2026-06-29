import 'package:flutter/animation.dart';

/// Spacing tokens — 4pt grid (`--sp-*` in tokens.css).
abstract final class QSpace {
  static const double s1 = 4;
  static const double s2 = 8;
  static const double s3 = 12;
  static const double s4 = 16;
  static const double s5 = 20;
  static const double s6 = 24;
  static const double s8 = 32;
  static const double s10 = 40;
}

/// Corner radius tokens (`--r-*`). Cards use [lg], hero countdown [xl],
/// sheets 24 on top corners, pills [full].
abstract final class QRadius {
  static const double sm = 10;
  static const double md = 14;
  static const double lg = 20;
  static const double xl = 28;
  static const double sheetTop = 24;
  static const double full = 999;
}

/// Motion tokens (`--dur-*`, `--ease`). All signature motion must be
/// disabled (cut, not animated) under reduced-motion settings.
abstract final class QMotion {
  /// State changes, ripple, countdown tick.
  static const fast = Duration(milliseconds: 120);

  /// Sheets, navigation transitions.
  static const med = Duration(milliseconds: 240);

  /// Splash, streak celebration, qibla lock.
  static const slow = Duration(milliseconds: 420);

  static const ease = Cubic(0.4, 0, 0.2, 1);
}

/// Minimum touch target per the design brief.
abstract final class QTouch {
  static const double minTarget = 48;
}
