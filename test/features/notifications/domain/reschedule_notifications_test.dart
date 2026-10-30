import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:productive_muslim/config/app_config.dart';
import 'package:productive_muslim/core/di/locator.dart';
import 'package:productive_muslim/core/utils/result.dart';
import 'package:productive_muslim/features/notifications/domain/entities/notification_item.dart';
import 'package:productive_muslim/features/notifications/domain/entities/notification_texts.dart';
import 'package:productive_muslim/features/notifications/domain/repositories/notification_scheduler.dart';
import 'package:productive_muslim/features/notifications/domain/usecases/build_notification_plan.dart';
import 'package:productive_muslim/features/notifications/domain/usecases/reschedule_notifications.dart';
import 'package:productive_muslim/features/prayer_times/data/repositories/prayer_day_repository_impl.dart';
import 'package:productive_muslim/features/prayer_times/domain/entities/prayer_day.dart';
import 'package:productive_muslim/features/prayer_times/domain/repositories/prayer_day_repository.dart';
import 'package:productive_muslim/features/prayer_times/domain/usecases/get_prayer_day.dart';
import 'package:productive_muslim/features/settings/data/datasources/timezone_clock.dart';
import 'package:productive_muslim/features/settings/domain/entities/app_settings.dart';
import 'package:productive_muslim/features/settings/domain/entities/city.dart';
import 'package:productive_muslim/features/settings/domain/entities/location_config.dart';
import 'package:productive_muslim/features/settings/domain/entities/notification_matrix.dart';
import 'package:productive_muslim/features/settings/domain/entities/prayer_params.dart';
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
  Future<void> openSystemSettings() async {}

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

/// High-latitude summer: every day's isha starts at 00:30 the next day.
final class _LateIshaRepository implements PrayerDayRepository {
  @override
  Result<PrayerDay> prayerDay({
    required LocationConfig location,
    required PrayerParams params,
    required DateTime date,
  }) {
    DateTime at(int day, int h, [int m = 0]) =>
        DateTime(date.year, date.month, date.day + day, h, m);
    return Result.success(
      PrayerDay(
        fajr: at(0, 2, 30),
        sunrise: at(0, 4),
        dhuhr: at(0, 13),
        asr: at(0, 17),
        maghrib: at(0, 22),
        isha: at(1, 0, 30),
        fajrTomorrow: at(1, 2, 30),
        ishaYesterday: at(0, 0, 30),
      ),
    );
  }
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
  keepAliveTitle: '',
  keepAliveBody: '',
  markAsPrayedAction: '',
  channelAzanName: '',
  channelRemindersName: '',
  channelSilentName: '',
  channelBeepName: '',
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

// Fixed clock dates sit in Ramadan 1447 (March 2026) so sahri/iftar plan.
void main() {
  setUpAll(TimezoneClock.initialize);

  group('RescheduleNotifications', () {
    test('no location cancels everything and schedules nothing', () async {
      final scheduler = _FakeScheduler();
      final usecase = RescheduleNotifications(
        getPrayerDay: GetPrayerDay(PrayerDayRepositoryImpl(TimezoneClock())),
        scheduler: scheduler,
        clock: _FixedClock(DateTime(2026, 3, 12, 4), TimezoneClock()),
      );
      final result = await usecase(
        settings: const AppSettings(),
        texts: _texts,
      );
      expect(result.valueOrNull, isEmpty);
      expect(scheduler.cancelCalls, 1);
      expect(scheduler.lastPlan, isNull);
    });

    test('with a location fills ~48h across three computed days', () async {
      final scheduler = _FakeScheduler();
      final usecase = RescheduleNotifications(
        getPrayerDay: GetPrayerDay(PrayerDayRepositoryImpl(TimezoneClock())),
        scheduler: scheduler,
        clock: _FixedClock(DateTime(2026, 3, 12, 4), TimezoneClock()),
      );
      final result = await usecase(
        settings: const AppSettings(location: _dhaka),
        texts: _texts,
      );
      final plan = scheduler.lastPlan!;
      expect(result.valueOrNull, plan);
      // Defaults: azan×5/day + sahri + iftar within window — at least a
      // dozen items, all in the future and inside 48h (keep-alive excepted).
      expect(plan.length, greaterThanOrEqualTo(12));
      final from = DateTime(2026, 3, 12, 4);
      expect(plan.every((i) => i.at.isAfter(from)), isTrue);
      final reminders = plan.where((i) => i.kind != NotificationKind.keepAlive);
      expect(
        reminders.every(
          (i) => !i.at.isAfter(from.add(const Duration(hours: 48))),
        ),
        isTrue,
      );
      expect(
        plan.where((i) => i.kind == NotificationKind.keepAlive),
        hasLength(1),
      );
    });

    test("keeps yesterday's isha that starts after midnight", () async {
      final scheduler = _FakeScheduler();
      await RescheduleNotifications(
        getPrayerDay: GetPrayerDay(_LateIshaRepository()),
        scheduler: scheduler,
        clock: _FixedClock(DateTime(2026, 6, 15, 0, 10), TimezoneClock()),
      )(
        settings: const AppSettings(location: _dhaka),
        texts: _texts,
      );
      final ishas = scheduler.lastPlan!.where(
        (i) => i.kind == NotificationKind.azan && i.prayer == Prayer.isha,
      );
      expect(ishas.first.at, DateTime(2026, 6, 15, 0, 30));
      expect(ishas.first.prayerDay, DateTime(2026, 6, 14));
    });

    Future<List<NotificationItem>> planFor(TargetPlatform platform) async {
      final scheduler = _FakeScheduler();
      await RescheduleNotifications(
        getPrayerDay: GetPrayerDay(PrayerDayRepositoryImpl(TimezoneClock())),
        scheduler: scheduler,
        clock: _FixedClock(DateTime(2026, 3, 12, 4), TimezoneClock()),
        window: AppConfig.notificationSchedulingWindow,
        maxItems: notificationCapFor(platform),
      )(
        // 9 items/day × 7 days exceeds the iOS cap.
        settings: const AppSettings(
          location: _dhaka,
          notifications: NotificationMatrix(
            muhasabaEveningReminder: true,
            dailyReminder: true,
          ),
        ),
        texts: _texts,
      );
      return scheduler.lastPlan!;
    }

    test('Android fills the full 7-day window, uncapped', () async {
      final plan = await planFor(TargetPlatform.android);
      final from = DateTime(2026, 3, 12, 4);
      final azans = plan.where((i) => i.kind == NotificationKind.azan);
      // 5 prayers × 7 days (fajr on day one may already be past).
      expect(azans.length, greaterThanOrEqualTo(34));
      expect(
        azans.every((i) => !i.at.isAfter(from.add(const Duration(days: 7)))),
        isTrue,
      );
      expect(azans.last.at.isAfter(from.add(const Duration(days: 6))), isTrue);
      final nudge = plan.singleWhere(
        (i) => i.kind == NotificationKind.keepAlive,
      );
      expect(nudge.at, plan.last.at.subtract(keepAliveLead));
    });

    test('iOS caps at 60 pending items, keeping the earliest', () async {
      final ios = await planFor(TargetPlatform.iOS);
      final android = await planFor(TargetPlatform.android);
      expect(android.length, greaterThan(60));
      expect(ios.length, 60);
      final iosReminders = ios
          .where((i) => i.kind != NotificationKind.keepAlive)
          .toList();
      final androidReminders = android
          .where((i) => i.kind != NotificationKind.keepAlive)
          .toList();
      expect(iosReminders, androidReminders.take(iosReminders.length).toList());
      // Well before the capped plan's last reminder, not after it.
      final nudge = ios.singleWhere(
        (i) => i.kind == NotificationKind.keepAlive,
      );
      expect(nudge.at, iosReminders.last.at.subtract(keepAliveLead));
    });
  });

  group('TimezoneClock.utcInstantOf', () {
    test('manual city wall time converts to the correct UTC instant', () {
      final clock = TimezoneClock();
      final utc = clock.utcInstantOf(_dhaka, DateTime(2026, 6, 12, 18, 45));
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
