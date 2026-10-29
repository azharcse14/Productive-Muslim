import 'package:flutter_test/flutter_test.dart';
import 'package:productive_muslim/core/utils/hijri_date.dart';
import 'package:productive_muslim/core/utils/result.dart';
import 'package:productive_muslim/features/prayer_times/data/repositories/prayer_day_repository_impl.dart';
import 'package:productive_muslim/features/prayer_times/domain/entities/countdown_target.dart';
import 'package:productive_muslim/features/prayer_times/domain/usecases/get_prayer_day.dart';
import 'package:productive_muslim/features/prayer_times/presentation/state/home_store.dart';
import 'package:productive_muslim/features/settings/data/datasources/timezone_clock.dart';
import 'package:productive_muslim/features/settings/domain/entities/app_settings.dart';
import 'package:productive_muslim/features/settings/domain/entities/city.dart';
import 'package:productive_muslim/features/settings/domain/entities/location_config.dart';
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

const _dhaka = ManualCityLocation(
  City(
    name: 'Dhaka',
    countryCode: 'BD',
    latitude: 23.7104,
    longitude: 90.4074,
    timezone: 'Asia/Dhaka',
  ),
);

void main() {
  setUpAll(TimezoneClock.initialize);

  // 18 Feb 2026 = tabular 1 Ramadan 1447; 03:00 is before fajr, where the
  // Ramadan override targets sahri end.
  Future<HomeStore> make(int offset) async {
    final settings = SettingsStore(
      GetSettings(
        _Repo(AppSettings(location: _dhaka, hijriOffsetDays: offset)),
      ),
      SaveSettings(_Repo(const AppSettings())),
    );
    await settings.load();
    final (mosque, _) = await makeMosqueStore();
    return HomeStore(
      getPrayerDay: GetPrayerDay(PrayerDayRepositoryImpl(TimezoneClock())),
      clock: _FixedClock(DateTime(2026, 2, 18, 3)),
      settings: settings,
      mosque: mosque,
    );
  }

  test('offset 0: tabular 1 Ramadan → Ramadan mode, sahri countdown', () async {
    final store = await make(0);
    expect(store.hijriDate.value, const HijriDate(1447, 9, 1));
    expect(store.ramadanMode.value, isTrue);
    expect(store.countdownTarget.value?.kind, CountdownKind.sahriEnd);
    store.dispose();
  });

  test('offset −1: still Sha\'ban → no Ramadan override', () async {
    final store = await make(-1);
    expect(store.hijriDate.value, const HijriDate(1447, 8, 29));
    expect(store.ramadanMode.value, isFalse);
    expect(store.countdownTarget.value?.kind, isNot(CountdownKind.sahriEnd));
    store.dispose();
  });
}
