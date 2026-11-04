import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:productive_muslim/core/utils/result.dart';
import 'package:productive_muslim/core/utils/wall_time.dart';
import 'package:productive_muslim/features/home_widget/data/prayer_widget_service.dart';
import 'package:productive_muslim/features/my_mosque/domain/entities/jamaat_config.dart';
import 'package:productive_muslim/features/my_mosque/domain/entities/mosque_profile.dart';
import 'package:productive_muslim/features/my_mosque/domain/entities/mosque_schedule.dart';
import 'package:productive_muslim/features/my_mosque/domain/entities/mosque_state.dart';
import 'package:productive_muslim/features/prayer_times/data/repositories/prayer_day_repository_impl.dart';
import 'package:productive_muslim/features/prayer_times/domain/entities/prayer_day.dart';
import 'package:productive_muslim/features/prayer_times/domain/repositories/prayer_day_repository.dart';
import 'package:productive_muslim/features/prayer_times/domain/usecases/get_prayer_day.dart';
import 'package:productive_muslim/features/settings/data/datasources/timezone_clock.dart';
import 'package:productive_muslim/features/settings/domain/entities/app_settings.dart';
import 'package:productive_muslim/features/settings/domain/entities/city.dart';
import 'package:productive_muslim/features/settings/domain/entities/location_config.dart';
import 'package:productive_muslim/features/settings/domain/entities/prayer_params.dart';
import 'package:productive_muslim/features/settings/domain/repositories/zoned_clock.dart';

import '../../helpers/mosque_fakes.dart';
import '../../helpers/settings_fakes.dart';

final class _FixedClock implements ZonedClock {
  _FixedClock(this.now);

  final DateTime now;
  final real = TimezoneClock();

  @override
  DateTime nowAt(LocationConfig location) => now.floating;

  @override
  DateTime instantAt(LocationConfig location, DateTime instant) =>
      real.instantAt(location, instant);

  @override
  DateTime utcInstantOf(LocationConfig location, DateTime wall) =>
      real.utcInstantOf(location, wall);
}

final class _BrokenClock implements ZonedClock {
  @override
  DateTime nowAt(LocationConfig location) => throw StateError('no tz');

  @override
  DateTime instantAt(LocationConfig location, DateTime instant) =>
      throw StateError('no tz');

  @override
  DateTime utcInstantOf(LocationConfig location, DateTime wall) =>
      throw StateError('no tz');
}

/// Returns [day] for the requested date, or a failure when [fail].
final class _FakeDays implements PrayerDayRepository {
  _FakeDays(this.day, {this.fail = false});

  final PrayerDay Function(DateTime date) day;
  final bool fail;

  @override
  Result<PrayerDay> prayerDay({
    required LocationConfig location,
    required PrayerParams params,
    required DateTime date,
  }) => fail
      ? const Result.failure(UnexpectedFailure('boom'))
      : Result.success(day(date));
}

PrayerDay _dayOn(DateTime d, {DateTime? fajrTomorrow}) => PrayerDay(
  ishaYesterday: DateTime.utc(d.year, d.month, d.day - 1, 20),
  fajr: DateTime.utc(d.year, d.month, d.day, 4),
  sunrise: DateTime.utc(d.year, d.month, d.day, 5, 30),
  dhuhr: DateTime.utc(d.year, d.month, d.day, 12),
  asr: DateTime.utc(d.year, d.month, d.day, 15, 30),
  maghrib: DateTime.utc(d.year, d.month, d.day, 18),
  isha: DateTime.utc(d.year, d.month, d.day, 19, 30),
  fajrTomorrow: fajrTomorrow ?? DateTime.utc(d.year, d.month, d.day + 1, 4),
);

/// Runs [service].update() and returns the delays of the timers it armed.
Future<List<Duration>> _armedTimers(
  PrayerWidgetService service,
  List<Timer> created,
) async {
  final delays = <Duration>[];
  await runZoned(
    service.update,
    zoneSpecification: ZoneSpecification(
      createTimer: (self, parent, zone, duration, f) {
        final t = parent.createTimer(zone, duration, f);
        created.add(t);
        delays.add(duration);
        return t;
      },
    ),
  );
  return delays;
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
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    TimezoneClock.initialize();
    await initializeDateFormatting('en');
  });

  test("Jumu'ah follows the mosque active on Friday, not today's", () async {
    const channel = MethodChannel('com.productivemuslim.app/widget');
    Map<Object?, Object?>? pushed;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          pushed = call.arguments as Map<Object?, Object?>;
          return null;
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null),
    );

    // Default mosque has a Jumu'ah time; on Fridays the schedule switches
    // to one without.
    final (mosque, _) = await makeMosqueStore(
      const MosqueState(
        profiles: [
          MosqueProfile(id: 'a', name: 'A', jumuah: ClockTime(13, 30)),
          MosqueProfile(id: 'b', name: 'B'),
        ],
        mode: ScheduleMode.auto,
        defaultId: 'a',
        rules: [
          MosqueRule(
            mosqueId: 'b',
            start: ClockTime(0, 0),
            end: ClockTime(0, 0),
            days: {DateTime.friday},
          ),
        ],
      ),
    );
    final clock = _FixedClock(DateTime.utc(2026, 6, 11, 10)); // a Thursday
    final service = PrayerWidgetService(
      getPrayerDay: GetPrayerDay(PrayerDayRepositoryImpl(clock)),
      clock: clock,
      settings: await makeSettingsStore(const AppSettings(location: _dhaka)),
      mosqueState: () => mosque.state.value,
    );

    await service.update();
    expect(pushed!['widget_strips'], isNot(contains("Jumu'ah")));
  });

  test('a failed update is logged and retried later', () async {
    final logs = <String?>[];
    final original = debugPrint;
    debugPrint = (message, {wrapWidth}) => logs.add(message);
    addTearDown(() => debugPrint = original);
    final timers = <(Duration, Timer)>[];
    addTearDown(() {
      for (final (_, t) in timers) {
        t.cancel();
      }
    });

    final clock = _BrokenClock();
    final service = PrayerWidgetService(
      getPrayerDay: GetPrayerDay(PrayerDayRepositoryImpl(TimezoneClock())),
      clock: clock,
      settings: await makeSettingsStore(const AppSettings(location: _dhaka)),
    );
    await runZoned(
      service.update,
      zoneSpecification: ZoneSpecification(
        createTimer: (self, parent, zone, duration, f) {
          final t = parent.createTimer(zone, duration, f);
          timers.add((duration, t));
          return t;
        },
      ),
    );

    expect(logs.single, contains('Home widget update failed'));
    expect(timers.map((t) => t.$1), [PrayerWidgetService.retryAfterFailure]);
  });

  group('boundary timer', () {
    late List<Timer> timers;
    Map<Object?, Object?>? pushed;
    const channel = MethodChannel('com.productivemuslim.app/widget');

    setUp(() {
      timers = [];
      pushed = null;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            pushed = call.arguments as Map<Object?, Object?>;
            return null;
          });
    });
    tearDown(() {
      for (final t in timers) {
        t.cancel();
      }
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    Future<PrayerWidgetService> service(
      DateTime now,
      PrayerDayRepository repo,
    ) async => PrayerWidgetService(
      getPrayerDay: GetPrayerDay(repo),
      clock: _FixedClock(now),
      settings: await makeSettingsStore(const AppSettings(location: _dhaka)),
    );

    const slack = Duration(seconds: 1);

    test(
      'arms for the next prayer start when it comes before midnight',
      () async {
        final s = await service(
          DateTime.utc(2026, 6, 11, 10),
          _FakeDays(_dayOn),
        );
        expect(await _armedTimers(s, timers), [
          const Duration(hours: 2) + slack,
        ]);
      },
    );

    test("after Isha it arms for midnight, not tomorrow's Fajr", () async {
      final s = await service(DateTime.utc(2026, 6, 11, 21), _FakeDays(_dayOn));
      expect(await _armedTimers(s, timers), [const Duration(hours: 3) + slack]);
    });

    test(
      'a past next start falls back to midnight (no zero-delay loop)',
      () async {
        // Bogus data: tomorrow's Fajr already behind now.
        final s = await service(
          DateTime.utc(2026, 6, 11, 23),
          _FakeDays(
            (d) => _dayOn(
              d,
              fajrTomorrow: DateTime.utc(d.year, d.month, d.day, 22),
            ),
          ),
        );
        expect(await _armedTimers(s, timers), [
          const Duration(hours: 1) + slack,
        ]);
      },
    );

    test(
      "today's times failing keeps the widget configured and retries",
      () async {
        final s = await service(
          DateTime.utc(2026, 6, 11, 10),
          _FakeDays(_dayOn, fail: true),
        );
        expect(await _armedTimers(s, timers), [
          PrayerWidgetService.retryAfterFailure,
        ]);
        expect(pushed?['widget_configured'], '1');
        expect(pushed?['widget_schedule'], '');
      },
    );
  });
}
