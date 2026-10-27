import 'location_config.dart';
import 'notification_matrix.dart';
import 'prayer_params.dart';

/// Theme preference (domain stays Flutter-free; presentation maps to
/// Flutter's ThemeMode).
enum AppThemeMode { system, light, dark }

/// Optional Home sections the user can hide. The countdown and prayer
/// table are the point of Home, so they are not listed.
enum HomeCard {
  quickActions,
  specialTimes,
  muhasaba,
  continueReading,
  tasbih,
  reflection,
}

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
    this.showAchievements = false,
    this.hapticsEnabled = true,
    this.hiddenHomeCards = const {},
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

  /// Badge wall + muhasaba achievements card; off by default (design brief:
  /// not gamified-loud).
  final bool showAchievements;

  /// Vibration on taps, counts and milestones.
  final bool hapticsEnabled;

  /// Home sections the user turned off (empty = show everything).
  final Set<HomeCard> hiddenHomeCards;

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
    bool? showAchievements,
    bool? hapticsEnabled,
    Set<HomeCard>? hiddenHomeCards,
    int? hijriOffsetDays,
  }) {
    return AppSettings(
      location: location ?? this.location,
      prayerParams: prayerParams ?? this.prayerParams,
      notifications: notifications ?? this.notifications,
      themeMode: themeMode ?? this.themeMode,
      localeCode: localeCode ?? this.localeCode,
      setupComplete: setupComplete ?? this.setupComplete,
      showAchievements: showAchievements ?? this.showAchievements,
      hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
      hiddenHomeCards: hiddenHomeCards ?? this.hiddenHomeCards,
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
      other.showAchievements == showAchievements &&
      other.hapticsEnabled == hapticsEnabled &&
      other.hiddenHomeCards.length == hiddenHomeCards.length &&
      other.hiddenHomeCards.containsAll(hiddenHomeCards) &&
      other.hijriOffsetDays == hijriOffsetDays;

  @override
  int get hashCode => Object.hash(
    location,
    prayerParams,
    notifications,
    themeMode,
    localeCode,
    setupComplete,
    showAchievements,
    hapticsEnabled,
    Object.hashAllUnordered(hiddenHomeCards),
    hijriOffsetDays,
  );
}
