import 'package:flutter_test/flutter_test.dart';
import 'package:productive_muslim/core/utils/result.dart';
import 'package:productive_muslim/core/utils/wall_time.dart';
import 'package:productive_muslim/features/my_mosque/domain/entities/jamaat_config.dart';
import 'package:productive_muslim/features/my_mosque/domain/entities/mosque_profile.dart';
import 'package:productive_muslim/features/my_mosque/domain/entities/mosque_schedule.dart';
import 'package:productive_muslim/features/my_mosque/domain/entities/mosque_state.dart';
import 'package:productive_muslim/features/my_mosque/domain/repositories/mosque_repository.dart';
import 'package:productive_muslim/features/my_mosque/domain/usecases/get_mosque_state.dart';
import 'package:productive_muslim/features/my_mosque/domain/usecases/save_mosque_state.dart';
import 'package:productive_muslim/features/my_mosque/presentation/state/mosque_store.dart';
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
    return now.floating;
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
      ishaYesterday: DateTime.utc(2026, 6, 18, 20, 30),
      fajr: DateTime.utc(2026, 6, 19, 3, 45),
      sunrise: DateTime.utc(2026, 6, 19, 5, 10),
      dhuhr: DateTime.utc(2026, 6, 19, 12, 10),
      asr: DateTime.utc(2026, 6, 19, 15, 30),
      maghrib: DateTime.utc(2026, 6, 19, 18, 50),
      isha: DateTime.utc(2026, 6, 19, 20, 15),
      fajrTomorrow: DateTime.utc(2026, 6, 20, 3, 45),
    ),
  );
}

/// Loads [stored]; every save fails (and is counted).
final class _FailingSaves implements MosqueRepository {
  _FailingSaves(this.stored);

  final MosqueState stored;
  int saves = 0;

  @override
  Future<Result<MosqueState>> load() async => Result.success(stored);

  @override
  Future<Result<void>> save(MosqueState state) async {
    saves++;
    return const Result.failure(UnexpectedFailure('disk full'));
  }
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
        DateTime.utc(2026, 6, 19, 13),
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
      expect(target.at, DateTime.utc(2026, 6, 19, 13, 30));
      expect(store.rowJamaat.value[Prayer.dhuhr], target.at);
      store.dispose();
    },
  );

  group('a waqt follows the mosque active at its start', () {
    // A (13:30) Mon–Fri 12:00–14:00, B (14:15) by default; Dhuhr from
    // 12:10 — A's waqt, as the reminders schedule it.
    const state = MosqueState(
      profiles: [
        MosqueProfile(
          id: 'b',
          name: 'B',
          entries: {Prayer.dhuhr: FixedJamaat(ClockTime(14, 15))},
        ),
        MosqueProfile(
          id: 'a',
          name: 'A',
          entries: {Prayer.dhuhr: FixedJamaat(ClockTime(13, 30))},
        ),
      ],
      mode: ScheduleMode.auto,
      defaultId: 'b',
      rules: [
        MosqueRule(
          mosqueId: 'a',
          start: ClockTime(12, 0),
          end: ClockTime(14, 0),
          days: {
            DateTime.monday,
            DateTime.tuesday,
            DateTime.wednesday,
            DateTime.thursday,
            DateTime.friday,
          },
        ),
      ],
    );

    test("after A's window: A's past jamaat → waqt end, not B's", () async {
      final (store, _) = await at(
        DateTime.utc(2026, 6, 19, 14, 5),
        mosqueState: state,
      );
      expect(store.mosqueResolution.value.profile?.id, 'b');
      final target = store.countdownTarget.value!;
      expect(target.kind, CountdownKind.waqtEnd);
      expect(target.at, DateTime.utc(2026, 6, 19, 15, 30));
      expect(
        store.rowJamaat.value[Prayer.dhuhr],
        DateTime.utc(2026, 6, 19, 13, 30),
      );
      store.dispose();
    });

    test("inside A's window: counts to A's 13:30", () async {
      final (store, _) = await at(
        DateTime.utc(2026, 6, 19, 13),
        mosqueState: state,
      );
      final target = store.countdownTarget.value!;
      expect(target.kind, CountdownKind.jamaat);
      expect(target.at, DateTime.utc(2026, 6, 19, 13, 30));
      store.dispose();
    });
  });

  testWidgets('the store starts on the slow tick until resumed', (
    tester,
  ) async {
    final (store, clock) = await at(DateTime.utc(2026, 6, 19, 13));
    final created = clock.reads;
    await tester.pump(const Duration(seconds: 5));
    expect(clock.reads, created, reason: 'no per-second tick before Home');

    store.resume();
    final resumed = clock.reads;
    await tester.pump(const Duration(seconds: 3));
    expect(clock.reads, resumed + 3);
    store.dispose();
  });

  group('override expiry', () {
    final friday = DateTime.utc(2026, 6, 19, 13);
    MosqueState withOverride(MosqueOverride o) => MosqueState(
      profiles: const [
        MosqueProfile(id: 'home', name: 'Home'),
        MosqueProfile(id: 'work', name: 'Work'),
      ],
      mode: ScheduleMode.auto,
      defaultId: 'home',
      activeOverride: o,
    );

    Future<HomeStore> home(MosqueStore mosque) async => HomeStore(
      getPrayerDay: GetPrayerDay(_FridayDays()),
      clock: _CountingClock(friday),
      settings: await makeSettingsStore(const AppSettings(location: _dhaka)),
      mosque: mosque,
    );

    test('a live override is kept', () async {
      final (mosque, repo) = await makeMosqueStore(
        withOverride(
          MosqueOverride(
            mosqueId: 'work',
            baselineAutoId: 'home',
            setOn: DateTime.utc(2026, 6, 19),
          ),
        ),
      );
      final store = await home(mosque);
      await pumpEventQueue();
      expect(repo.saves, 0);
      expect(mosque.state.value.activeOverride, isNotNull);
      store.dispose();
    });

    for (final (why, override) in [
      (
        'the schedule moved on',
        MosqueOverride(
          mosqueId: 'work',
          baselineAutoId: 'gone',
          setOn: DateTime.utc(2026, 6, 19),
        ),
      ),
      (
        'its day ended',
        MosqueOverride(
          mosqueId: 'work',
          baselineAutoId: 'home',
          setOn: DateTime.utc(2026, 6, 18),
        ),
      ),
    ]) {
      test('is cleared once when $why', () async {
        final (mosque, repo) = await makeMosqueStore(withOverride(override));
        final store = await home(mosque);
        await pumpEventQueue();
        expect(mosque.state.value.activeOverride, isNull);
        expect(repo.stored.activeOverride, isNull);
        expect(repo.saves, 1);
        store.dispose();
      });
    }

    test('a failed clear is not retried in a loop', () async {
      final repo = _FailingSaves(
        withOverride(
          MosqueOverride(
            mosqueId: 'work',
            baselineAutoId: 'gone',
            setOn: DateTime.utc(2026, 6, 19),
          ),
        ),
      );
      final mosque = MosqueStore(GetMosqueState(repo), SaveMosqueState(repo));
      await mosque.load();
      final store = await home(mosque);
      await pumpEventQueue();
      expect(repo.saves, 1);
      expect(mosque.state.value.activeOverride, isNull);
      store.dispose();
    });
  });
}
