import 'package:flutter/material.dart' show Locale, ThemeMode;
import 'package:signals_flutter/signals_flutter.dart';

import '../../../../core/utils/haptics.dart';
import '../../domain/entities/app_settings.dart';
import '../../domain/entities/location_config.dart';
import '../../domain/entities/notification_matrix.dart';
import '../../domain/entities/prayer_params.dart';
import '../../domain/usecases/get_settings.dart';
import '../../domain/usecases/save_settings.dart';

/// App-scoped settings state. One [AppSettings] signal; everything else
/// is derived (guide §4: derive, don't duplicate). Updates persist
/// fire-and-await through [SaveSettings].
final class SettingsStore {
  SettingsStore(this._getSettings, this._saveSettings);

  final GetSettings _getSettings;
  final SaveSettings _saveSettings;

  late final settings = signal(const AppSettings());
  late final loaded = signal(false);

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
    (s) => s.copyWith(
      prayerParams: s.prayerParams.copyWith(madhab: madhab),
    ),
  );

  Future<void> setMethod(CalculationMethodId method) => _update(
    (s) => s.copyWith(
      prayerParams: s.prayerParams.copyWith(method: method),
    ),
  );

  Future<void> setHighLatitudeRule(HighLatitudeRule rule) => _update(
    (s) => s.copyWith(
      prayerParams: s.prayerParams.copyWith(
        highLatitudeRule: rule,
      ),
    ),
  );

  Future<void> setNotifications(NotificationMatrix matrix) =>
      _update((s) => s.copyWith(notifications: matrix));

  /// Onboarding gate (router redirect reads this).
  /// Clamped to −2..+2 by [AppSettings].
  Future<void> setSahriSafety(int minutes) => _update(
    (s) => s.copyWith(
      prayerParams: s.prayerParams.copyWith(
        sahriSafetyMinutes: minutes,
      ),
    ),
  );

  Future<void> setHijriOffset(int days) =>
      _update((s) => s.copyWith(hijriOffsetDays: days));

  Future<void> setShowAchievements({required bool show}) =>
      _update((s) => s.copyWith(showAchievements: show));

  Future<void> setHapticsEnabled({required bool enabled}) {
    Haptics.enabled = enabled;
    return _update((s) => s.copyWith(hapticsEnabled: enabled));
  }

  Future<void> setHomeCardVisible(HomeCard card, {required bool visible}) {
    return _update((s) {
      final hidden = {...s.hiddenHomeCards};
      visible ? hidden.remove(card) : hidden.add(card);
      return s.copyWith(hiddenHomeCards: hidden);
    });
  }

  Future<void> setSetupComplete({required bool complete}) =>
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
  /// can be replayed onto the real settings once they load.
  Future<void> _update(AppSettings Function(AppSettings) change) async {
    if (_readFailed) {
      // Retry the read first so [change] lands on the user's settings,
      // not on the defaults kept after the failed load.
      await load();
      if (_readFailed) {
        // ponytail: still unreadable — saving would overwrite the stored
        // settings with defaults, so the change lives in memory only and
        // is lost on restart.
        settings.value = change(settings.value);
        return;
      }
    }
    final next = change(settings.value);
    settings.value = next;
    await _saveSettings(next);
  }
}
