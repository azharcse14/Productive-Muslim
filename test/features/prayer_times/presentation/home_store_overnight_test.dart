import 'package:flutter_test/flutter_test.dart';
import 'package:productive_muslim/core/utils/result.dart';
import 'package:productive_muslim/features/prayer_times/domain/entities/prayer_day.dart';
import 'package:productive_muslim/features/prayer_times/domain/repositories/prayer_day_repository.dart';
import 'package:productive_muslim/features/prayer_times/domain/usecases/get_prayer_day.dart';
import 'package:productive_muslim/features/prayer_times/presentation/state/home_store.dart';
import 'package:productive_muslim/features/settings/data/datasources/timezone_clock.dart';
import 'package:productive_muslim/features/settings/domain/entities/app_settings.dart';
import 'package:productive_muslim/features/settings/domain/entities/city.dart';
import 'package:productive_muslim/features/settings/domain/entities/location_config.dart';
import 'package:productive_muslim/features/settings/domain/entities/prayer_params.dart';
import 'package:productive_muslim/features/settings/domain/repositories/settings_repository.dart';
import 'package:productive_muslim/features/settings/domain/repositories/zoned_clock.dart';
import 'package:productive_muslim/features/settings/domain/usecases/get_settings.dart';
import 'package:productive_muslim/features/settings/domain/usecases/save_settings.dart';
import 'package:productive_muslim/features/settings/presentation/state/settings_store.dart';

import '../../../helpers/mosque_fakes.dart';

final class _Repo implements SettingsRepository {
  _Repo(this.stored);

  AppSettings stored;

  @override
  Future<Result<AppSettings>> load() async => Result.success(stored);

  @override
  Future<Result<void>> save(AppSettings settings) async {
    stored = settings;
    return const Result.success(null);
  }
}

final class _FixedClock implements ZonedClock {
  _FixedClock(this.now);

  final DateTime now;
  final _real = TimezoneClock();

  @override
  DateTime nowAt(LocationConfig location) => now;

  @override
  DateTime instantAt(LocationConfig location, DateTime instant) =>
      _real.instantAt(location, instant);

  @override
  DateTime utcInstantOf(LocationConfig location, DateTime wall) =>
      _real.utcInstantOf(location, wall);
}

/// A London-June-like day: yesterday's isha only starts after midnight.
final class _LateIshaDays implements PrayerDayRepository {
  @override
  Result<PrayerDay> prayerDay({
    required LocationConfig location,
    required PrayerParams params,
    required DateTime date,
  }) => Result.success(
    PrayerDay(
      maghribYesterday: DateTime(2026, 6, 20, 21, 20),
      ishaYesterday: DateTime(2026, 6, 21, 0, 30),
      fajr: DateTime(2026, 6, 21, 2, 50),
      sunrise: DateTime(2026, 6, 21, 4, 43),
      dhuhr: DateTime(2026, 6, 21, 13, 2),
      asr: DateTime(2026, 6, 21, 17, 25),
      maghrib: DateTime(2026, 6, 21, 21, 21),
      isha: DateTime(2026, 6, 22, 0, 31),
      fajrTomorrow: DateTime(2026, 6, 22, 2, 51),
    ),
  );
}

const _london = ManualCityLocation(
  City(
    name: 'London',
    countryCode: 'GB',
    latitude: 51.5072,
    longitude: -0.1276,
    timezone: 'Europe/London',
  ),
);

void main() {
  setUpAll(TimezoneClock.initialize);

  Future<HomeStore> at(DateTime now) async {
    final repo = _Repo(const AppSettings(location: _london));
    final settings = SettingsStore(GetSettings(repo), SaveSettings(repo));
    await settings.load();
    final (mosque, _) = await makeMosqueStore();
    return HomeStore(
      getPrayerDay: GetPrayerDay(_LateIshaDays()),
      clock: _FixedClock(now),
      settings: settings,
      mosque: mosque,
    );
  }

  test(
    "before a past-midnight isha, yesterday's maghrib is checkable",
    () async {
      final store = await at(DateTime(2026, 6, 21, 0, 10));
      expect(store.activeWaqt.value?.prayer, Prayer.maghrib);
      expect(store.overnightWaqt.value, Prayer.maghrib);
      expect(store.lockedPrayers.value, isNot(contains(Prayer.maghrib)));
      expect(store.lockedPrayers.value, contains(Prayer.isha));
      expect(store.salahDate(Prayer.maghrib), DateTime(2026, 6, 20));
      store.dispose();
    },
  );

  test("once it starts, yesterday's isha is the overnight waqt", () async {
    final store = await at(DateTime(2026, 6, 21, 1));
    expect(store.overnightWaqt.value, Prayer.isha);
    expect(store.lockedPrayers.value, isNot(contains(Prayer.isha)));
    expect(store.salahDate(Prayer.isha), DateTime(2026, 6, 20));
    expect(store.salahDate(Prayer.maghrib), DateTime(2026, 6, 21));
    store.dispose();
  });
}
