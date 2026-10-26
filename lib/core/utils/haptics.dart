import 'dart:async';

import 'package:flutter/services.dart' show HapticFeedback;

/// The one gate for tactile feedback: every haptic in the app goes through
/// here so the Settings toggle silences all of them at once.
abstract final class Haptics {
  /// Mirrors `AppSettings.hapticsEnabled`; kept in sync by SettingsStore.
  static bool enabled = true;

  /// Taps on buttons, chips, tabs, toggles.
  static void selection() => _fire(HapticFeedback.selectionClick);

  /// Small confirmations (a counted bead, a correct answer).
  static void light() => _fire(HapticFeedback.lightImpact);

  /// Milestones and alignment.
  static void medium() => _fire(HapticFeedback.mediumImpact);

  /// Errors and lockouts.
  static void heavy() => _fire(HapticFeedback.heavyImpact);

  static void _fire(Future<void> Function() feedback) {
    if (enabled) {
      unawaited(feedback());
    }
  }
}
