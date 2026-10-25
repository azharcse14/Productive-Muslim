/// App-level constants that are not visual design tokens.
///
/// Values here are product rules from the design brief / development guide,
/// kept in one place so features never hardcode them.
abstract final class AppConfig {
  /// Countdown turns amber when jamaat is this close (design: "jamaat ≤10 min").
  static const jamaatSoonThreshold = Duration(minutes: 10);

  /// Countdown turns urgent in the last part of the waqt
  /// (design: "makruh window / last 20 min").
  static const waqtEndingThreshold = Duration(minutes: 20);

  /// Default Maghrib jamaat offset (design: "Maghrib defaults to offset +5").
  static const defaultMaghribJamaatOffset = Duration(minutes: 5);

  /// Notifications are scheduled this far ahead on app open/resume. There is
  /// no background refresh, so the window is long; a keep-alive nudge at its
  /// end asks the user to open the app.
  static const notificationSchedulingWindow = Duration(days: 7);

  /// iOS keeps at most 64 pending local notifications per app; stay under it
  /// (the keep-alive nudge counts toward this).
  static const iosMaxPendingNotifications = 60;

  /// Qibla alignment tolerance in degrees (design: ±3°).
  static const qiblaAlignmentToleranceDeg = 3.0;

  /// Quran reader font scale bounds (design: 22–44px in steps of 2).
  static const quranFontSizeMin = 22.0;
  static const quranFontSizeMax = 44.0;
  static const quranFontSizeStep = 2.0;
}
