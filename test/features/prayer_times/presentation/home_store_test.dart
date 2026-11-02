import 'package:flutter_test/flutter_test.dart';
import 'package:productive_muslim/core/utils/result.dart';
import 'package:productive_muslim/features/my_mosque/domain/entities/jamaat_config.dart';
import 'package:productive_muslim/features/my_mosque/domain/entities/mosque_profile.dart';
import 'package:productive_muslim/features/my_mosque/domain/entities/mosque_schedule.dart';
import 'package:productive_muslim/features/my_mosque/domain/entities/mosque_state.dart';
import 'package:productive_muslim/features/prayer_times/domain/entities/countdown_target.dart';
import 'package:productive_muslim/features/prayer_times/domain/entities/prayer_day.dart';
import 'package:productive_muslim/features/prayer_times/domain/repositories/prayer_day_repository.dart';
import 'package:productive_muslim/features/prayer_times/domain/usecases/get_prayer_day.dart';
import 'package:productive_muslim/features/prayer_times/presentation/state/home_store.dart';
import 'package:productive_muslim/features/settings/data/datasources/timezone_clock.dart';
import 'package:productive_muslim/features/settings/domain/entities/app_settings.dart';
import 'package:productive_muslim/features/settings/domain/entities/city.dart';
import 'package:productive_muslim/features/settings/domain/entities/location_config.dart';
import 'package:productive_muslim/features/settings/domain/entities/prayer_params.dart';
import 'package:productive_muslim/features/settings/domain/repositories/zoned_clock.dart';

import '../../../helpers/mosque_fakes.dart';
import '../../../helpers/settings_fakes.dart';

final class _CountingClock implements ZonedClock {
  _CountingClock(this.now);

  final DateTime now;
  final _real = TimezoneClock();
  int reads = 0;

  @override
  DateTime nowAt(LocationConfig location) {
    reads++;
    return now;
  }

  @override
  DateTime instantAt(LocationConfig location, DateTime instant) =>
      _real.instantAt(location, instant);

  @override
  DateTime utcInstantOf(LocationConfig location, DateTime wall) =>
      _real.utcInstantOf(location, wall);
}

/// Friday 19 June 2026, Dhuhr 12:10.
final class _FridayDays implements PrayerDayRepository {
  @override
  Result<PrayerDay> prayerDay({
    required LocationConfig location,
    required PrayerParams params,
    required DateTime date,
  }) => Result.success(
    PrayerDay(
      ishaYesterday: DateTime(2026, 6, 18, 20, 30),
      fajr: DateTime(2026, 6, 19, 3, 45),
      sunrise: DateTime(2026, 6, 19, 5, 10),
      dhuhr: DateTime(2026, 6, 19, 12, 10),
      asr: DateTime(2026, 6, 19, 15, 30),
      maghrib: DateTime(2026, 6, 19, 18, 50),
      isha: DateTime(2026, 6, 19, 20, 15),
      fajrTomorrow: DateTime(2026, 6, 20, 3, 45),
    ),
  );
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

  Future<(HomeStore, _CountingClock)> at(
    DateTime now, {
    MosqueState mosqueState = const MosqueState(),
  }) async {
    final settings = await makeSettingsStore(
      const AppSettings(location: _dhaka),
    );
    final (mosque, _) = await makeMosqueStore(mosqueState);
    final clock = _CountingClock(now);
    final store = HomeStore(
      getPrayerDay: GetPrayerDay(_FridayDays()),
      clock: clock,
      settings: settings,
      mosque: mosque,
    );
    return (store, clock);
  }

  test(
    "Friday's countdown targets the Jumu'ah of the mosque at Dhuhr",
    () async {
      // Work (Jumu'ah 13:30) until 13:00 on Fridays, Home (13:45) otherwise.
      final (store, _) = await at(
        DateTime(2026, 6, 19, 13),
        mosqueState: const MosqueState(
          profiles: [
            MosqueProfile(id: 'home', name: 'Home', jumuah: ClockTime(13, 45)),
            MosqueProfile(id: 'work', name: 'Work', jumuah: ClockTime(13, 30)),
          ],
          mode: ScheduleMode.auto,
          defaultId: 'home',
          rules: [
            MosqueRule(
              mosqueId: 'work',
              start: ClockTime(9, 0),
              end: ClockTime(13, 0),
              days: {DateTime.friday},
            ),
          ],
        ),
      );
      final target = store.countdownTarget.value!;
      expect(target.kind, CountdownKind.jamaat);
      expect(target.at, DateTime(2026, 6, 19, 13, 30));
      expect(store.rowJamaat.value[Prayer.dhuhr], target.at);
      store.dispose();
    },
  );

  testWidgets('the store starts on the slow tick until resumed', (
    tester,
  ) async {
    final (store, clock) = await at(DateTime(2026, 6, 19, 13));
    final created = clock.reads;
    await tester.pump(const Duration(seconds: 5));
    expect(clock.reads, created, reason: 'no per-second tick before Home');

    store.resume();
    final resumed = clock.reads;
    await tester.pump(const Duration(seconds: 3));
    expect(clock.reads, resumed + 3);
    store.dispose();
  });
}
