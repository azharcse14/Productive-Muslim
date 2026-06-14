import 'dart:async';

import 'package:flutter/services.dart' show HapticFeedback, rootBundle;
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:signals/signals.dart';

import '../../features/dua_tasbih/data/dua_asset_data_source.dart';
import '../../features/dua_tasbih/data/dua_repository_impl.dart';
import '../../features/dua_tasbih/domain/repositories/dua_repository.dart';
import '../../features/dua_tasbih/presentation/state/dua_favorites_store.dart';
import '../../features/dua_tasbih/presentation/state/dua_store.dart';
import '../../features/dua_tasbih/presentation/state/tasbih_store.dart';
import '../../features/hadith/data/hadith_asset_data_source.dart';
import '../../features/hadith/data/hadith_repository_impl.dart';
import '../../features/hadith/domain/repositories/hadith_repository.dart';
import '../../features/hadith/presentation/state/hadith_store.dart';
import '../../features/home_widget/data/prayer_widget_service.dart';
import '../../features/muhasaba/data/database/muhasaba_database.dart';
import '../../features/muhasaba/data/repositories/muhasaba_repository_impl.dart';
import '../../features/muhasaba/domain/repositories/muhasaba_repository.dart';
import '../../features/muhasaba/presentation/state/muhasaba_store.dart';
import '../../features/my_mosque/data/datasources/mosque_local_data_source.dart';
import '../../features/my_mosque/data/repositories/mosque_repository_impl.dart';
import '../../features/my_mosque/domain/repositories/mosque_repository.dart';
import '../../features/my_mosque/domain/usecases/get_mosque_state.dart';
import '../../features/my_mosque/domain/usecases/save_mosque_state.dart';
import '../../features/my_mosque/presentation/state/mosque_store.dart';
import '../../features/notifications/data/local_notifications_scheduler.dart';
import '../../features/notifications/domain/repositories/notification_scheduler.dart';
import '../../features/notifications/domain/usecases/reschedule_notifications.dart';
import '../../features/notifications/presentation/state/notification_controller.dart';
import '../../features/onboarding/data/app_lock_data_source.dart';
import '../../features/onboarding/data/local_auth_biometric.dart';
import '../../features/onboarding/presentation/state/app_lock_store.dart';
import '../../features/prayer_times/data/repositories/prayer_day_repository_impl.dart';
import '../../features/prayer_times/domain/repositories/prayer_day_repository.dart';
import '../../features/prayer_times/domain/usecases/get_prayer_day.dart';
import '../../features/prayer_times/presentation/state/home_store.dart';
import '../../features/qibla/data/datasources/sensor_data_source.dart';
import '../../features/qibla/presentation/state/qibla_store.dart';
import '../../features/quran/data/datasources/quran_database.dart';
import '../../features/quran/data/repositories/quran_repository_impl.dart';
import '../../features/quran/domain/repositories/quran_repository.dart';
import '../../features/quran/presentation/state/quran_store.dart';
import '../../features/settings/data/datasources/city_asset_data_source.dart';
import '../../features/settings/data/datasources/geolocator_data_source.dart';
import '../../features/settings/data/datasources/settings_local_data_source.dart';
import '../../features/settings/data/datasources/timezone_clock.dart';
import '../../features/settings/data/repositories/city_repository_impl.dart';
import '../../features/settings/data/repositories/location_repository_impl.dart';
import '../../features/settings/data/repositories/settings_repository_impl.dart';
import '../../features/settings/domain/entities/prayer_params.dart';
import '../../features/settings/domain/repositories/city_repository.dart';
import '../../features/settings/domain/repositories/location_repository.dart';
import '../../features/settings/domain/repositories/settings_repository.dart';
import '../../features/settings/domain/repositories/zoned_clock.dart';
import '../../features/settings/domain/usecases/get_current_location.dart';
import '../../features/settings/domain/usecases/get_settings.dart';
import '../../features/settings/domain/usecases/save_settings.dart';
import '../../features/settings/domain/usecases/search_cities.dart';
import '../../features/settings/presentation/state/settings_store.dart';
import '../utils/locale_digits.dart';

/// Global service locator. The ONLY place registrations happen
/// (guide §4 — single composition root). Widgets never call
/// `locator` directly; screen-level state objects resolve dependencies.
final GetIt locator = GetIt.instance;

/// Called in `main()` before `runApp`. Data sources & repositories are
/// lazySingletons, use cases lazySingletons (stateless), screen stores
/// factories; [SettingsStore] is app-scoped (theme/locale drive the root).
Future<void> setupLocator() async {
  TimezoneClock.initialize();

  // ---- settings / location ----
  locator
    ..registerLazySingleton(
      () => SettingsLocalDataSource(SharedPreferencesAsync()),
    )
    ..registerLazySingleton(() => CityAssetDataSource(rootBundle))
    ..registerLazySingleton<DeviceLocationSource>(GeolocatorDataSource.new)
    ..registerLazySingleton<ZonedClock>(TimezoneClock.new)
    ..registerLazySingleton<SettingsRepository>(
      () => SettingsRepositoryImpl(locator()),
    )
    ..registerLazySingleton<CityRepository>(
      () => CityRepositoryImpl(locator()),
    )
    ..registerLazySingleton<LocationRepository>(
      () => LocationRepositoryImpl(locator()),
    )
    ..registerLazySingleton(() => GetSettings(locator()))
    ..registerLazySingleton(() => SaveSettings(locator()))
    ..registerLazySingleton(() => SearchCities(locator()))
    ..registerLazySingleton(() => GetCurrentLocation(locator()))
    ..registerLazySingleton(() => SettingsStore(locator(), locator()));

  // ---- onboarding / app lock ----
  locator
    ..registerLazySingleton(
      () => AppLockDataSource(SharedPreferencesAsync()),
    )
    ..registerLazySingleton<BiometricAuth>(LocalAuthBiometric.new)
    ..registerLazySingleton(() => AppLockStore(locator(), locator()));

  // ---- muhasaba ----
  locator
    ..registerLazySingleton<MuhasabaDatabase>(MuhasabaDatabase.open)
    ..registerLazySingleton<MuhasabaRepository>(
      () => MuhasabaRepositoryImpl(locator()),
    )
    ..registerLazySingleton(
      () => MuhasabaStore(locator(), lockedSalahOn: _lockedSalahOn),
    );

  // ---- qibla ----
  locator
    ..registerLazySingleton<CompassSensorSource>(SensorsPlusSource.new)
    ..registerFactory(
      () => QiblaStore(
        sensors: locator(),
        settings: locator(),
        onAligned: HapticFeedback.mediumImpact,
      ),
    );

  // ---- my mosque ----
  locator
    ..registerLazySingleton(
      () => MosqueLocalDataSource(SharedPreferencesAsync()),
    )
    ..registerLazySingleton<MosqueRepository>(
      () => MosqueRepositoryImpl(locator()),
    )
    ..registerLazySingleton(() => GetMosqueState(locator()))
    ..registerLazySingleton(() => SaveMosqueState(locator()))
    ..registerLazySingleton(() => MosqueStore(locator(), locator()));

  // ---- notifications ----
  locator
    ..registerLazySingleton<NotificationScheduler>(
      () => LocalNotificationsScheduler(
        clock: locator(),
        currentLocation: () => locator<SettingsStore>().location.value,
        formatTime: (dt) {
          final code = locator<SettingsStore>().settings.value.localeCode;
          return LocaleDigits.localize(
            DateFormat.jm(code).format(dt),
            code,
          );
        },
      ),
    )
    ..registerLazySingleton(
      () => RescheduleNotifications(
        getPrayerDay: locator(),
        scheduler: locator(),
        clock: locator(),
      ),
    )
    ..registerLazySingleton(
      () => NotificationController(
        reschedule: locator(),
        scheduler: locator(),
        settings: locator(),
        mosque: locator(),
      ),
    );

  // ---- prayer times / home ----
  locator
    ..registerLazySingleton<PrayerDayRepository>(
      () => PrayerDayRepositoryImpl(locator()),
    )
    ..registerLazySingleton(() => GetPrayerDay(locator()))
    ..registerFactory(
      () => HomeStore(
        getPrayerDay: locator(),
        clock: locator(),
        settings: locator(),
        mosque: locator(),
      ),
    );

  // ---- quran ----
  locator
    ..registerSingletonAsync<QuranDatabase>(QuranDatabase.open)
    ..registerLazySingleton<QuranRepository>(
      () => QuranRepositoryImpl(locator()),
    )
    ..registerLazySingleton(
      () => QuranStore(locator(), SharedPreferencesAsync()),
    );

  // ---- dua & tasbih ----
  locator
    ..registerLazySingleton(() => DuaAssetDataSource(rootBundle))
    ..registerLazySingleton<DuaRepository>(
      () => DuaRepositoryImpl(locator()),
    )
    ..registerLazySingleton(() => DuaStore(locator()))
    ..registerLazySingleton(
      () => DuaFavoritesStore(SharedPreferencesAsync()),
    )
    ..registerLazySingleton(() => TasbihStore(SharedPreferencesAsync()));

  // ---- hadith ----
  locator
    ..registerLazySingleton(() => HadithAssetDataSource(rootBundle))
    ..registerLazySingleton<HadithRepository>(
      () => HadithRepositoryImpl(locator()),
    )
    ..registerLazySingleton(() => HadithStore(locator()));

  // ---- home-screen widget ----
  locator.registerLazySingleton(
    () => PrayerWidgetService(
      getPrayerDay: locator(),
      clock: locator(),
      settings: locator(),
    ),
  );

  await locator<SettingsStore>().load();
  await locator<MosqueStore>().load();
  await locator<MuhasabaStore>().load();
  await locator<AppLockStore>().load();
  await locator<DuaFavoritesStore>().load();
  await locator.isReady<QuranDatabase>();

  _startWidgetUpdates();
}

/// Keeps the home-screen widget in sync. Runs once now (app open) and again
/// whenever the location, prayer parameters, or locale change. Best-effort:
/// [PrayerWidgetService.update] swallows its own errors.
void _startWidgetUpdates() {
  final settings = locator<SettingsStore>();
  final widget = locator<PrayerWidgetService>();
  effect(() {
    // Touch the signals the snapshot depends on so the effect re-runs.
    settings.location.value;
    settings.prayerParams.value;
    settings.settings.value.localeCode;
    unawaited(widget.update());
  });
}

/// Salah ids whose waqt hasn't begun on [date] at the location's clock —
/// so muhasaba/home won't let them be checked off ahead of time. Past
/// dates and no-location cases lock nothing (back-fill stays open).
Set<String> _lockedSalahOn(DateTime date) {
  final settings = locator<SettingsStore>();
  final location = settings.location.value;
  if (location == null) {
    return const <String>{};
  }
  final now = locator<ZonedClock>().nowAt(location);
  final today = DateTime(now.year, now.month, now.day);
  final d = DateTime(date.year, date.month, date.day);
  if (d != today) {
    // Past: already happened, fully open. Future can't be selected anyway.
    return const <String>{};
  }
  final day = locator<GetPrayerDay>()(
    location: location,
    params: settings.prayerParams.value,
    date: today,
  ).valueOrNull;
  if (day == null) {
    return const <String>{};
  }
  return {
    for (final prayer in Prayer.values)
      if (now.isBefore(day.startOf(prayer))) 'salah_${prayer.name}',
  };
}
