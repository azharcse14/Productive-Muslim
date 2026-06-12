import 'package:flutter/services.dart' show rootBundle;
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/prayer_times/data/repositories/prayer_day_repository_impl.dart';
import '../../features/prayer_times/domain/repositories/prayer_day_repository.dart';
import '../../features/prayer_times/domain/usecases/get_prayer_day.dart';
import '../../features/prayer_times/presentation/state/home_store.dart';
import '../../features/settings/data/datasources/city_asset_data_source.dart';
import '../../features/settings/data/datasources/geolocator_data_source.dart';
import '../../features/settings/data/datasources/settings_local_data_source.dart';
import '../../features/settings/data/datasources/timezone_clock.dart';
import '../../features/settings/data/repositories/city_repository_impl.dart';
import '../../features/settings/data/repositories/location_repository_impl.dart';
import '../../features/settings/data/repositories/settings_repository_impl.dart';
import '../../features/settings/domain/repositories/city_repository.dart';
import '../../features/settings/domain/repositories/location_repository.dart';
import '../../features/settings/domain/repositories/settings_repository.dart';
import '../../features/settings/domain/repositories/zoned_clock.dart';
import '../../features/settings/domain/usecases/get_current_location.dart';
import '../../features/settings/domain/usecases/get_settings.dart';
import '../../features/settings/domain/usecases/save_settings.dart';
import '../../features/settings/domain/usecases/search_cities.dart';
import '../../features/settings/presentation/state/settings_store.dart';

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
      ),
    );

  await locator<SettingsStore>().load();
}
