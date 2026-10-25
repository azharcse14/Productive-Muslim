import 'package:flutter/material.dart' show Locale, ThemeMode;
import 'package:signals_flutter/signals_flutter.dart';

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
  late final hijriOffsetDays =
      computed(() => settings.value.hijriOffsetDays);

  Future<void> load() async {
    final result = await _getSettings();
    result.fold(
      (value) => settings.value = value,
      (_) {}, // keep defaults; storage failure must not block boot
    );
    loaded.value = true;
  }

  Future<void> setThemeMode(AppThemeMode mode) =>
      _update(settings.value.copyWith(themeMode: mode));

  Future<void> setLocale(String code) =>
      _update(settings.value.copyWith(localeCode: code));

  Future<void> setLocation(LocationConfig location) =>
      _update(settings.value.copyWith(location: location));

  Future<void> setMadhab(Madhab madhab) => _update(
        settings.value.copyWith(
          prayerParams: settings.value.prayerParams.copyWith(madhab: madhab),
        ),
      );

  Future<void> setMethod(CalculationMethodId method) => _update(
        settings.value.copyWith(
          prayerParams: settings.value.prayerParams.copyWith(method: method),
        ),
      );

  Future<void> setHighLatitudeRule(HighLatitudeRule rule) => _update(
        settings.value.copyWith(
          prayerParams:
              settings.value.prayerParams.copyWith(highLatitudeRule: rule),
        ),
      );

  Future<void> setNotifications(NotificationMatrix matrix) =>
      _update(settings.value.copyWith(notifications: matrix));

  /// Onboarding gate (router redirect reads this).
  /// Clamped to −2..+2 by [AppSettings].
  Future<void> setSahriSafety(int minutes) => _update(
        settings.value.copyWith(
          prayerParams: settings.value.prayerParams
              .copyWith(sahriSafetyMinutes: minutes),
        ),
      );

  Future<void> setHijriOffset(int days) =>
      _update(settings.value.copyWith(hijriOffsetDays: days));

  Future<void> setShowAchievements({required bool show}) =>
      _update(settings.value.copyWith(showAchievements: show));

  Future<void> setSetupComplete({required bool complete}) =>
      _update(settings.value.copyWith(setupComplete: complete));

  Future<void> setAdjustment(Prayer prayer, int minutes) {
    final params = settings.value.prayerParams;
    return _update(
      settings.value.copyWith(
        prayerParams: params.copyWith(
          adjustments: {...params.adjustments, prayer: minutes},
        ),
      ),
    );
  }

  Future<void> _update(AppSettings next) async {
    settings.value = next;
    await _saveSettings(next);
  }
}
