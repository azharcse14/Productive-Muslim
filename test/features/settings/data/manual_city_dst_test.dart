import 'package:flutter_test/flutter_test.dart';
import 'package:productive_muslim/core/utils/wall_time.dart';
import 'package:productive_muslim/features/my_mosque/domain/entities/jamaat_config.dart';
import 'package:productive_muslim/features/notifications/domain/entities/notification_item.dart';
import 'package:productive_muslim/features/notifications/domain/usecases/build_notification_plan.dart';
import 'package:productive_muslim/features/prayer_times/data/repositories/prayer_day_repository_impl.dart';
import 'package:productive_muslim/features/prayer_times/domain/entities/countdown_target.dart';
import 'package:productive_muslim/features/prayer_times/domain/entities/prayer_day.dart';
import 'package:productive_muslim/features/prayer_times/domain/entities/special_time.dart';
import 'package:productive_muslim/features/prayer_times/domain/usecases/get_prayer_day.dart';
import 'package:productive_muslim/features/prayer_times/domain/usecases/resolve_special_times.dart';
import 'package:productive_muslim/features/prayer_times/presentation/state/home_store.dart';
import 'package:productive_muslim/features/settings/data/datasources/timezone_clock.dart';
import 'package:productive_muslim/features/settings/domain/entities/app_settings.dart';
import 'package:productive_muslim/features/settings/domain/entities/city.dart';
import 'package:productive_muslim/features/settings/domain/entities/location_config.dart';
import 'package:productive_muslim/features/settings/domain/entities/notification_matrix.dart';
import 'package:productive_muslim/features/settings/domain/entities/prayer_params.dart';
import 'package:productive_muslim/features/settings/domain/repositories/zoned_clock.dart';

import '../../../helpers/mosque_fakes.dart';
import '../../../helpers/settings_fakes.dart';

/// Manual-city wall times flow through prayer times, jamaat, the countdown
/// and the notification plan as floating values: nothing may depend on the
/// device zone. Run with `TZ=America/New_York` to put the device's own DST
/// days (8 Mar / 1 Nov 2026) under these tests.
const _dhaka = ManualCityLocation(
  City(
    name: 'Dhaka',
    countryCode: 'BD',
    latitude: 23.7104,
    longitude: 90.4074,
    timezone: 'Asia/Dhaka',
  ),
);

const _london = ManualCityLocation(
  City(
    name: 'London',
    countryCode: 'GB',
    latitude: 51.5085,
    longitude: -0.1257,
    timezone: 'Europe/London',
  ),
);

/// The real clock, pinned at [utc] (so [nowAt] is its true reading).
final class _PinnedClock implements ZonedClock {
  _PinnedClock(this.utc);

  final DateTime utc;
  final _real = TimezoneClock();

  @override
  DateTime nowAt(LocationConfig location) => _real.instantAt(location, utc);

  @override
  DateTime instantAt(LocationConfig location, DateTime instant) =>
      _real.instantAt(location, instant);

  @override
  DateTime utcInstantOf(LocationConfig location, DateTime wall) =>
      _real.utcInstantOf(location, wall);
}

void main() {
  setUpAll(TimezoneClock.initialize);
  final clock = TimezoneClock();
  WallZone zoneOf(LocationConfig l) => (
    instantOf: (wall) => clock.utcInstantOf(l, wall),
    wallOf: (instant) => clock.instantAt(l, instant),
  );

  group('Dhaka city on a US/EU-zoned device', () {
    test('prayer times on the US spring-forward and fall-back days', () {
      final repo = PrayerDayRepositoryImpl(clock);
      for (final date in [DateTime(2026, 3, 8), DateTime(2026, 11)]) {
        final day = repo
            .prayerDay(
              location: _dhaka,
              params: const PrayerParams(),
              date: date,
            )
            .valueOrNull!;
        expect(day.fajr.day, date.day);
        for (final t in [
          day.ishaYesterday,
          day.fajr,
          day.dhuhr,
          day.isha,
          day.fajrTomorrow,
        ]) {
          expect(t.isUtc, isTrue, reason: 'floating wall time');
          // Dhaka is a fixed UTC+6: the fields are the instant + 6 h.
          expect(
            clock.utcInstantOf(_dhaka, t),
            t.subtract(const Duration(hours: 6)),
          );
        }
      }
    });

    test('a fixed jamaat at 02:30 stays 02:30', () {
      final at = JamaatConfig.placeNear(
        DateTime.utc(2026, 3, 8, 2, 10),
        const ClockTime(2, 30),
      );
      expect(at, DateTime.utc(2026, 3, 8, 2, 30));
    });

    test('a 02:30 daily reminder is planned at 02:30 Dhaka', () {
      final day = PrayerDayRepositoryImpl(clock)
          .prayerDay(
            location: _dhaka,
            params: const PrayerParams(),
            date: DateTime(2026, 3, 8),
          )
          .valueOrNull!;
      final plan = buildNotificationPlan(
        from: DateTime.utc(2026, 3, 8),
        days: [day],
        matrix: const NotificationMatrix(
          dailyReminder: true,
          dailyReminderMinute: 150,
        ),
        jamaat: JamaatConfig.none,
      );
      final reminder = plan.singleWhere(
        (i) => i.kind == NotificationKind.dailyReminder,
      );
      expect(reminder.at, DateTime.utc(2026, 3, 8, 2, 30));
      expect(
        clock.utcInstantOf(_dhaka, reminder.at),
        DateTime.utc(2026, 3, 7, 20, 30),
      );
      // Ordered with the azans on the same (floating) clock.
      final fajr = plan.firstWhere((i) => i.prayer == Prayer.fajr);
      expect(reminder.at.isBefore(fajr.at), isTrue);
    });
  });

  group("London city across its own DST", () {
    test('countdown to Fajr counts real time, not the wall gap', () {
      // Spring: 23:00 GMT → 05:00 BST is 5 real hours.
      final spring = CountdownTarget(
        kind: CountdownKind.waqtStart,
        prayer: Prayer.fajr,
        at: DateTime.utc(2026, 3, 29, 5),
        windowStart: DateTime.utc(2026, 3, 28, 22),
      );
      final instantOf = zoneOf(_london).instantOf;
      expect(
        spring.remainingAt(DateTime.utc(2026, 3, 28, 23), instantOf),
        const Duration(hours: 5),
      );
      // Fall: 23:00 BST → 06:00 GMT is 8 real hours.
      final fall = CountdownTarget(
        kind: CountdownKind.waqtStart,
        prayer: Prayer.fajr,
        at: DateTime.utc(2026, 10, 25, 6),
        windowStart: DateTime.utc(2026, 10, 24, 22),
      );
      expect(
        fall.remainingAt(DateTime.utc(2026, 10, 24, 23), instantOf),
        const Duration(hours: 8),
      );
    });

    test('tahajjud splits the spring-forward night in real hours', () {
      PrayerDay night(DateTime maghrib, DateTime fajrTomorrow) => PrayerDay(
        ishaYesterday: DateTime.utc(2026, 3, 27, 20),
        fajr: DateTime.utc(2026, 3, 28, 5),
        sunrise: DateTime.utc(2026, 3, 28, 6),
        dhuhr: DateTime.utc(2026, 3, 28, 12),
        asr: DateTime.utc(2026, 3, 28, 15),
        maghrib: maghrib,
        isha: DateTime.utc(2026, 3, 28, 20),
        fajrTomorrow: fajrTomorrow,
      );
      DateTime tahajjud(PrayerDay d) => resolveSpecialWindows(
        d,
        zone: zoneOf(_london),
      ).firstWhere((w) => w.time == SpecialTime.tahajjud).start;
      // 18:30 GMT → 05:00 BST = 9.5 real hours; +6h20 = 00:50 GMT.
      expect(
        tahajjud(
          night(
            DateTime.utc(2026, 3, 28, 18, 30),
            DateTime.utc(2026, 3, 29, 5),
          ),
        ),
        DateTime.utc(2026, 3, 29, 0, 50),
      );
      // 18:30 GMT → 06:30 BST = 11 real hours; +7h20 = 01:50 UTC = 02:50 BST.
      expect(
        tahajjud(
          night(
            DateTime.utc(2026, 3, 28, 18, 30),
            DateTime.utc(2026, 3, 29, 6, 30),
          ),
        ),
        DateTime.utc(2026, 3, 29, 2, 50),
      );
    });
  });

  group("London's repeated fall-back hour (25 Oct 2026)", () {
    // 00:30 UTC = 01:30 BST, the first time London reads 01:30.
    final first = DateTime.utc(2026, 10, 25, 0, 30);
    final wall = DateTime.utc(2026, 10, 25, 1, 30);

    test('nowInstant takes the device instant over the guess', () {
      DateTime instantOf(DateTime w) => clock.utcInstantOf(_london, w);
      DateTime wallOf(DateTime i) => clock.instantAt(_london, i);
      expect(wallOf(first), wall);
      // The wall time alone resolves to the second 01:30 (GMT).
      expect(instantOf(wall), DateTime.utc(2026, 10, 25, 1, 30));
      expect(
        nowInstant(
          wall,
          deviceUtc: first,
          instantOf: instantOf,
          wallOf: wallOf,
        ),
        first,
      );
      // A pinned wall clock that the device doesn't read falls back.
      expect(
        nowInstant(
          wall,
          deviceUtc: DateTime.utc(2020),
          instantOf: instantOf,
          wallOf: wallOf,
        ),
        instantOf(wall),
      );
    });

    test('the home countdown counts from the real instant', () async {
      final settings = await makeSettingsStore(
        const AppSettings(location: _london),
      );
      final (mosque, _) = await makeMosqueStore();
      final store = HomeStore(
        getPrayerDay: GetPrayerDay(PrayerDayRepositoryImpl(clock)),
        clock: _PinnedClock(first),
        settings: settings,
        mosque: mosque,
        utcNow: () => first,
      );
      addTearDown(store.dispose);
      expect(store.now.value, wall);
      final target = store.countdownTarget.value!;
      expect(
        store.remaining.value,
        clock.utcInstantOf(_london, target.at).difference(first),
      );
    });
  });
}
