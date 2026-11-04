import 'package:flutter_test/flutter_test.dart';
import 'package:productive_muslim/core/settings/settings_store.dart';
import 'package:productive_muslim/core/utils/result.dart';
import 'package:productive_muslim/core/utils/wall_time.dart';
import 'package:productive_muslim/features/my_mosque/domain/entities/jamaat_config.dart';
import 'package:productive_muslim/features/my_mosque/domain/entities/mosque_profile.dart';
import 'package:productive_muslim/features/my_mosque/domain/entities/mosque_schedule.dart';
import 'package:productive_muslim/features/my_mosque/domain/entities/mosque_state.dart';
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
  DateTime nowAt(LocationConfig location) => now.floating;

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
      maghribYesterday: DateTime.utc(2026, 6, 20, 21, 20),
      ishaYesterday: DateTime.utc(2026, 6, 21, 0, 30),
      fajr: DateTime.utc(2026, 6, 21, 2, 50),
      sunrise: DateTime.utc(2026, 6, 21, 4, 43),
      dhuhr: DateTime.utc(2026, 6, 21, 13, 2),
      asr: DateTime.utc(2026, 6, 21, 17, 25),
      maghrib: DateTime.utc(2026, 6, 21, 21, 21),
      isha: DateTime.utc(2026, 6, 22, 0, 31),
      fajrTomorrow: DateTime.utc(2026, 6, 22, 2, 51),
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

  Future<HomeStore> at(
    DateTime now, {
    MosqueState mosqueState = const MosqueState(),
  }) async {
    final repo = _Repo(const AppSettings(location: _london));
    final settings = SettingsStore(GetSettings(repo), SaveSettings(repo));
    await settings.load();
    final (mosque, _) = await makeMosqueStore(mosqueState);
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
      final store = await at(DateTime.utc(2026, 6, 21, 0, 10));
      expect(store.activeWaqt.value?.prayer, Prayer.maghrib);
      expect(store.overnightWaqt.value, Prayer.maghrib);
      expect(store.lockedPrayers.value, isNot(contains(Prayer.maghrib)));
      expect(store.lockedPrayers.value, contains(Prayer.isha));
      expect(store.salahDate(Prayer.maghrib), DateTime(2026, 6, 20));
      store.dispose();
    },
  );

  test("once it starts, yesterday's isha is the overnight waqt", () async {
    final store = await at(DateTime.utc(2026, 6, 21, 1));
    expect(store.overnightWaqt.value, Prayer.isha);
    expect(store.lockedPrayers.value, isNot(contains(Prayer.isha)));
    expect(store.salahDate(Prayer.isha), DateTime(2026, 6, 20));
    expect(store.salahDate(Prayer.maghrib), DateTime(2026, 6, 21));
    store.dispose();
  });

  test("the overnight row's jamaat and range are yesterday's", () async {
    final store = await at(
      DateTime.utc(2026, 6, 21, 1),
      mosqueState: const MosqueState(
        profiles: [
          MosqueProfile(
            id: 'a',
            name: 'A',
            entries: {Prayer.isha: OffsetJamaat(Duration(minutes: 10))},
          ),
        ],
        activeId: 'a',
      ),
    );
    // Yesterday's isha 00:30 → today's fajr 02:50, not tonight's 00:31 → …
    expect(store.waqtRangeOf(Prayer.isha), (
      DateTime.utc(2026, 6, 21, 0, 30),
      DateTime.utc(2026, 6, 21, 2, 50),
    ));
    expect(
      store.rowJamaat.value[Prayer.isha],
      DateTime.utc(2026, 6, 21, 0, 40),
    );
    // Other rows keep today's window.
    expect(store.waqtRangeOf(Prayer.maghrib), (
      DateTime.utc(2026, 6, 21, 21, 21),
      DateTime.utc(2026, 6, 22, 0, 31),
    ));
    store.dispose();
  });

  test("the overnight row's jamaat comes from the mosque active at its "
      'start, not the one active now', () async {
    final store = await at(
      DateTime.utc(2026, 6, 21, 1),
      mosqueState: const MosqueState(
        profiles: [
          MosqueProfile(
            id: 'a',
            name: 'A',
            entries: {Prayer.isha: OffsetJamaat(Duration(minutes: 10))},
          ),
          MosqueProfile(
            id: 'b',
            name: 'B',
            entries: {Prayer.isha: OffsetJamaat(Duration(minutes: 40))},
          ),
        ],
        mode: ScheduleMode.auto,
        // A until 00:45 (covers isha's 00:30 start), B after.
        rules: [
          MosqueRule(
            mosqueId: 'a',
            start: ClockTime(0, 0),
            end: ClockTime(0, 45),
          ),
        ],
        defaultId: 'b',
      ),
    );
    expect(store.mosqueResolution.value.profile?.id, 'b');
    expect(
      store.rowJamaat.value[Prayer.isha],
      DateTime.utc(2026, 6, 21, 0, 40),
    );
    // The countdown agrees: A's 00:40 has passed, so it targets the waqt
    // end, not B's 01:10.
    expect(store.countdownTarget.value?.at, DateTime.utc(2026, 6, 21, 2, 50));
    store.dispose();
  });

  test('a jamaat at or past its waqt end is left off the row', () async {
    final store = await at(
      DateTime.utc(2026, 6, 21, 12),
      mosqueState: const MosqueState(
        profiles: [
          MosqueProfile(
            id: 'a',
            name: 'A',
            entries: {
              // Asr ends at Maghrib 21:21: a stale summer 22:00 is dropped.
              Prayer.asr: FixedJamaat(ClockTime(22, 0)),
              Prayer.maghrib: FixedJamaat(ClockTime(21, 30)),
            },
          ),
        ],
        activeId: 'a',
      ),
    );
    expect(store.rowJamaat.value.containsKey(Prayer.asr), isFalse);
    expect(
      store.rowJamaat.value[Prayer.maghrib],
      DateTime.utc(2026, 6, 21, 21, 30),
    );
    store.dispose();
  });
}
