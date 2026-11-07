import 'package:flutter/material.dart' show Locale, ThemeMode;
import 'package:signals_flutter/signals_flutter.dart';

import '../../features/settings/domain/entities/app_settings.dart';
import '../../features/settings/domain/entities/location_config.dart';
import '../../features/settings/domain/entities/notification_matrix.dart';
import '../../features/settings/domain/entities/prayer_params.dart';
import '../../features/settings/domain/usecases/get_settings.dart';
import '../../features/settings/domain/usecases/regional_defaults.dart';
import '../../features/settings/domain/usecases/save_settings.dart';
import '../utils/haptics.dart';
import '../utils/result.dart';

/// App-scoped settings state. One [AppSettings] signal; everything else
/// is derived (guide §4: derive, don't duplicate). Updates persist
/// fire-and-await through [SaveSettings].
final class SettingsStore {
  SettingsStore(this._getSettings, this._saveSettings);

  final GetSettings _getSettings;
  final SaveSettings _saveSettings;

  late final settings = signal(const AppSettings());
  late final loaded = signal(false);

  /// Bumped whenever a change fails to persist, so open settings screens
  /// can say so (setters are mostly fire-and-forget).
  late final saveFailures = signal(0);

  /// Storage couldn't be read: [settings] holds defaults, not the user's
  /// data, so saving them would clobber whatever is stored.
  bool _readFailed = false;

  /// Flutter-facing derivations.
  late final themeMode = computed(
    () => switch (settings.value.themeMode) {
      AppThemeMode.system => ThemeMode.system,
      AppThemeMode.light => ThemeMode.light,
      AppThemeMode.dark => ThemeMode.dark,
    },
  );
  late final locale = computed(() => Locale(settings.value.localeCode));
  late final location = computed(() => settings.value.location);
  late final prayerParams = computed(() => settings.value.prayerParams);
  late final hijriOffsetDays = computed(() => settings.value.hijriOffsetDays);

  Future<void> load() async {
    final result = await _getSettings();
    result.fold(
      (value) {
        _readFailed = false;
        settings.value = value;
        Haptics.enabled = value.hapticsEnabled;
      },
      // Keep defaults; storage failure must not block boot.
      (_) => _readFailed = true,
    );
    loaded.value = true;
  }

  Future<void> setThemeMode(AppThemeMode mode) =>
      _update((s) => s.copyWith(themeMode: mode));

  Future<void> setLocale(String code) =>
      _update((s) => s.copyWith(localeCode: code));

  Future<void> setLocation(LocationConfig location) =>
      _update((s) => s.copyWith(location: location));

  Future<void> setMadhab(Madhab madhab) => _update(
    (s) => s.copyWith(prayerParams: s.prayerParams.copyWith(madhab: madhab)),
  );

  Future<void> setMethod(CalculationMethodId method) => _update(
    (s) => s.copyWith(prayerParams: s.prayerParams.copyWith(method: method)),
  );

  Future<void> setHighLatitudeRule(HighLatitudeRule rule) => _update(
    (s) => s.copyWith(
      prayerParams: s.prayerParams.copyWith(highLatitudeRule: rule),
    ),
  );

  Future<void> setPolarRule(PolarRule rule) => _update(
    (s) => s.copyWith(prayerParams: s.prayerParams.copyWith(polarRule: rule)),
  );

  Future<void> setNotifications(NotificationMatrix matrix) =>
      _update((s) => s.copyWith(notifications: matrix));

  /// The user's own margin: it no longer follows the region default.
  Future<void> setSahriSafety(int minutes) => _update(
    (s) => s.copyWith(
      sahriSafetyTuned: true,
      prayerParams: s.prayerParams.copyWith(sahriSafetyMinutes: minutes),
    ),
  );

  /// The user's own offset (clamped to −2..+2 by [AppSettings]): it no
  /// longer follows the region default.
  Future<void> setHijriOffset(int days) =>
      _update((s) => s.copyWith(hijriOffsetDays: days, hijriOffsetTuned: true));

  /// Sets the Hijri offset and sahri margin the user never tuned to
  /// [countryCode]'s defaults (first setup and country moves).
  Future<void> applyRegionalTimingDefaults(String countryCode) => _update(
    (s) => s.copyWith(
      hijriOffsetDays: s.hijriOffsetTuned
          ? null
          : defaultHijriOffsetFor(countryCode),
      prayerParams: s.sahriSafetyTuned
          ? null
          : s.prayerParams.copyWith(
              sahriSafetyMinutes: defaultSahriSafetyFor(countryCode),
            ),
    ),
  );

  Future<void> setShowAchievements({required bool show}) =>
      _update((s) => s.copyWith(showAchievements: show));

  Future<void> setHapticsEnabled({required bool enabled}) {
    Haptics.enabled = enabled;
    return _update((s) => s.copyWith(hapticsEnabled: enabled));
  }

  /// Home's exact-alarm banner: "don't remind me".
  Future<void> dismissExactAlarmBanner() =>
      _update((s) => s.copyWith(exactAlarmBannerDismissed: true));

  Future<void> setHomeCardVisible(HomeCard card, {required bool visible}) {
    return _update((s) {
      final hidden = {...s.hiddenHomeCards};
      visible ? hidden.remove(card) : hidden.add(card);
      return s.copyWith(hiddenHomeCards: hidden);
    });
  }

  /// Onboarding gate (router redirect reads this). A failure means the
  /// flag holds in memory only (onboarding reruns next launch).
  Future<Result<void>> setSetupComplete({required bool complete}) =>
      _update((s) => s.copyWith(setupComplete: complete));

  /// Clamped to ±[PrayerParams.maxAdjustment].
  Future<void> setAdjustment(Prayer prayer, int minutes) {
    final clamped = minutes.clamp(
      -PrayerParams.maxAdjustment,
      PrayerParams.maxAdjustment,
    );
    return _update(
      (s) => s.copyWith(
        prayerParams: s.prayerParams.copyWith(
          adjustments: {...s.prayerParams.adjustments, prayer: clamped},
        ),
      ),
    );
  }

  /// Applies [change] to the current settings and saves. [change] is a
  /// function, not a value, so a change made while storage was unreadable
  /// can be replayed onto the real settings once they load. Fails (and
  /// bumps [saveFailures]) when the change couldn't be persisted.
  Future<Result<void>> _update(AppSettings Function(AppSettings) change) async {
    final result = await _apply(change);
    if (!result.isSuccess) {
      saveFailures.value++;
    }
    return result;
  }

  /// The retry-read in flight, shared by every update that arrives while
  /// it runs: a second read finishing later would overwrite [settings]
  /// with a snapshot that lacks the first update's change.
  Future<void>? _reload;

  Future<Result<void>> _apply(AppSettings Function(AppSettings) change) async {
    if (_readFailed) {
      // Retry the read first so [change] lands on the user's settings,
      // not on the defaults kept after the failed load.
      await (_reload ??= load().whenComplete(() => _reload = null));
      if (_readFailed) {
        // ponytail: still unreadable — saving would overwrite the stored
        // settings with defaults, so the change lives in memory only and
        // is lost on restart.
        settings.value = change(settings.value);
        return const Result.failure(
          UnexpectedFailure('Settings unreadable; change not saved'),
        );
      }
    }
    final next = change(settings.value);
    settings.value = next;
    return _saveSettings(next);
  }
}
