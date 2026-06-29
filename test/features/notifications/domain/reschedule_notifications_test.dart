import 'package:flutter_test/flutter_test.dart';
import 'package:productive_muslim/core/utils/result.dart';
import 'package:productive_muslim/features/notifications/domain/entities/notification_item.dart';
import 'package:productive_muslim/features/notifications/domain/entities/notification_texts.dart';
import 'package:productive_muslim/features/notifications/domain/repositories/notification_scheduler.dart';
import 'package:productive_muslim/features/notifications/domain/usecases/reschedule_notifications.dart';
import 'package:productive_muslim/features/prayer_times/data/repositories/prayer_day_repository_impl.dart';
import 'package:productive_muslim/features/prayer_times/domain/usecases/get_prayer_day.dart';
import 'package:productive_muslim/features/settings/data/datasources/timezone_clock.dart';
import 'package:productive_muslim/features/settings/domain/entities/app_settings.dart';
import 'package:productive_muslim/features/settings/domain/entities/city.dart';
import 'package:productive_muslim/features/settings/domain/entities/location_config.dart';
import 'package:productive_muslim/features/settings/domain/repositories/zoned_clock.dart';

final class _FakeScheduler implements NotificationScheduler {
  List<NotificationItem>? lastPlan;
  int cancelCalls = 0;

  @override
  Future<void> initialize(NotificationTexts texts) async {}

  @override
  Future<NotificationPermission> permissionStatus() async =>
      NotificationPermission.granted;

  @override
  Future<NotificationPermission> requestPermission() async =>
      NotificationPermission.granted;

  @override
  Future<bool> canScheduleExactAlarms() async => true;

  @override
  Future<void> requestExactAlarmPermission() async {}

  @override
  Future<Result<void>> reschedule(
    List<NotificationItem> items,
    NotificationTexts texts,
  ) async {
    lastPlan = items;
    return const Result.success(null);
  }

  @override
  Future<void> cancelAll() async {
    cancelCalls++;
  }
}

final class _FixedClock implements ZonedClock {
  _FixedClock(this.now, this.real);

  final DateTime now;
  final TimezoneClock real;

  @override
  DateTime nowAt(LocationConfig location) => now;

  @override
  DateTime instantAt(LocationConfig location, DateTime instant) =>
      real.instantAt(location, instant);

  @override
  DateTime utcInstantOf(LocationConfig location, DateTime wall) =>
      real.utcInstantOf(location, wall);
}

const _texts = NotificationTexts(
  azanTitle: '{prayer} · {time}',
  azanBody: '',
  jamaatTitle: '',
  jamaatBody: '',
  sahriTitle: '',
  sahriBody: '',
  iftarTitle: '',
  iftarBody: '',
  muhasabaTitle: '',
  muhasabaBody: '',
  dailyReminderTitle: '',
  dailyReminderBody: '',
  dailyReminderRoute: '/hadith',
  markAsPrayedAction: '',
  channelAzanName: '',
  channelRemindersName: '',
  channelSilentName: '',
  prayerNames: {},
);

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

  group('RescheduleNotifications', () {
    test('no location cancels everything and schedules nothing', () async {
      final scheduler = _FakeScheduler();
      final usecase = RescheduleNotifications(
        getPrayerDay: GetPrayerDay(PrayerDayRepositoryImpl(TimezoneClock())),
        scheduler: scheduler,
        clock: _FixedClock(DateTime(2026, 6, 12, 4), TimezoneClock()),
      );
      final result = await usecase(
        settings: const AppSettings(),
        texts: _texts,
      );
      expect(result.valueOrNull, 0);
      expect(scheduler.cancelCalls, 1);
      expect(scheduler.lastPlan, isNull);
    });

    test('with a location fills ~48h across three computed days', () async {
      final scheduler = _FakeScheduler();
      final usecase = RescheduleNotifications(
        getPrayerDay: GetPrayerDay(PrayerDayRepositoryImpl(TimezoneClock())),
        scheduler: scheduler,
        clock: _FixedClock(DateTime(2026, 6, 12, 4), TimezoneClock()),
      );
      final result = await usecase(
        settings: const AppSettings(location: _dhaka),
        texts: _texts,
      );
      final plan = scheduler.lastPlan!;
      expect(result.valueOrNull, plan.length);
      // Defaults: azan×5/day + sahri + iftar within window — at least a
      // dozen items, all in the future and inside 48h.
      expect(plan.length, greaterThanOrEqualTo(12));
      final from = DateTime(2026, 6, 12, 4);
      expect(plan.every((i) => i.at.isAfter(from)), isTrue);
      expect(
        plan.every(
          (i) => !i.at.isAfter(from.add(const Duration(hours: 48))),
        ),
        isTrue,
      );
    });
  });

  group('TimezoneClock.utcInstantOf', () {
    test('manual city wall time converts to the correct UTC instant', () {
      final clock = TimezoneClock();
      final utc =
          clock.utcInstantOf(_dhaka, DateTime(2026, 6, 12, 18, 45));
      expect(utc, DateTime.utc(2026, 6, 12, 12, 45)); // Dhaka = UTC+6
    });

    test('round-trips with instantAt', () {
      final clock = TimezoneClock();
      final wall = DateTime(2026, 6, 12, 3, 45);
      final utc = clock.utcInstantOf(_dhaka, wall);
      expect(clock.instantAt(_dhaka, utc), wall);
    });
  });
}
