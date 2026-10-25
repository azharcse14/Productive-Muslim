import 'location_config.dart';
import 'notification_matrix.dart';
import 'prayer_params.dart';

/// Theme preference (domain stays Flutter-free; presentation maps to
/// Flutter's ThemeMode).
enum AppThemeMode { system, light, dark }

/// The whole persisted app configuration. Immutable; every change creates
/// a new instance via [copyWith].
final class AppSettings {
  const AppSettings({
    this.location,
    this.prayerParams = const PrayerParams(),
    this.notifications = const NotificationMatrix(),
    this.themeMode = AppThemeMode.system,
    this.localeCode = 'en',
    this.setupComplete = false,
    int hijriOffsetDays = 0,
  }) : hijriOffsetDays = hijriOffsetDays < minHijriOffset
            ? minHijriOffset
            : (hijriOffsetDays > maxHijriOffset
                ? maxHijriOffset
                : hijriOffsetDays);

  /// Bounds for [hijriOffsetDays].
  static const minHijriOffset = -2;
  static const maxHijriOffset = 2;

  /// Null until onboarding/location setup picks one.
  final LocationConfig? location;
  final PrayerParams prayerParams;
  final NotificationMatrix notifications;
  final AppThemeMode themeMode;

  /// 'en' | 'bn' (more later).
  final String localeCode;

  /// Onboarding gate flag read by the router redirect (Phase 11).
  final bool setupComplete;

  /// Moon-sighting adjustment applied to every Hijri date (−2..+2 days,
  /// clamped): the tabular calendar can differ from local sighting.
  final int hijriOffsetDays;

  AppSettings copyWith({
    LocationConfig? location,
    PrayerParams? prayerParams,
    NotificationMatrix? notifications,
    AppThemeMode? themeMode,
    String? localeCode,
    bool? setupComplete,
    int? hijriOffsetDays,
  }) {
    return AppSettings(
      location: location ?? this.location,
      prayerParams: prayerParams ?? this.prayerParams,
      notifications: notifications ?? this.notifications,
      themeMode: themeMode ?? this.themeMode,
      localeCode: localeCode ?? this.localeCode,
      setupComplete: setupComplete ?? this.setupComplete,
      hijriOffsetDays: hijriOffsetDays ?? this.hijriOffsetDays,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is AppSettings &&
      other.location == location &&
      other.prayerParams == prayerParams &&
      other.notifications == notifications &&
      other.themeMode == themeMode &&
      other.localeCode == localeCode &&
      other.setupComplete == setupComplete &&
      other.hijriOffsetDays == hijriOffsetDays;

  @override
  int get hashCode => Object.hash(
        location,
        prayerParams,
        notifications,
        themeMode,
        localeCode,
        setupComplete,
        hijriOffsetDays,
      );
}
