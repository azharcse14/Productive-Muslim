import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:productive_muslim/core/utils/result.dart';
import 'package:productive_muslim/features/notifications/data/local_notifications_scheduler.dart';
import 'package:productive_muslim/features/notifications/domain/entities/notification_item.dart';
import 'package:productive_muslim/features/notifications/domain/entities/notification_texts.dart';
import 'package:productive_muslim/features/notifications/domain/repositories/notification_scheduler.dart';
import 'package:productive_muslim/features/settings/data/datasources/timezone_clock.dart';
import 'package:productive_muslim/features/settings/domain/entities/city.dart';
import 'package:productive_muslim/features/settings/domain/entities/location_config.dart';
import 'package:productive_muslim/features/settings/domain/entities/prayer_params.dart';
import 'package:productive_muslim/features/settings/domain/repositories/zoned_clock.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:timezone/timezone.dart';

/// Records schedule calls; throws for the ids in [failIds].
final class _FakePlugin implements FlutterLocalNotificationsPlugin {
  final scheduled = <int, NotificationDetails>{};
  final titles = <int, String?>{};
  final failIds = <int>{};
  final pending = <int>{};
  final cancelled = <int>{};
  int cancelAllCalls = 0;
  int cancelPendingCalls = 0;
  int initCalls = 0;
  NotificationAppLaunchDetails? launch;

  @override
  Future<bool?> initialize({
    required InitializationSettings settings,
    DidReceiveNotificationResponseCallback? onDidReceiveNotificationResponse,
    DidReceiveBackgroundNotificationResponseCallback?
    onDidReceiveBackgroundNotificationResponse,
  }) async {
    initCalls++;
    return true;
  }

  @override
  Future<NotificationAppLaunchDetails?>
  getNotificationAppLaunchDetails() async => launch;

  @override
  Future<void> cancelAll() async => cancelAllCalls++;

  @override
  Future<void> cancelAllPendingNotifications() async => cancelPendingCalls++;

  @override
  Future<List<PendingNotificationRequest>>
  pendingNotificationRequests() async => [
    for (final id in pending) PendingNotificationRequest(id, null, null, null),
  ];

  @override
  Future<void> cancel({required int id, String? tag}) async {
    cancelled.add(id);
    pending.remove(id);
  }

  @override
  Future<void> zonedSchedule({
    required int id,
    required TZDateTime scheduledDate,
    required NotificationDetails notificationDetails,
    required AndroidScheduleMode androidScheduleMode,
    String? title,
    String? body,
    String? payload,
    DateTimeComponents? matchDateTimeComponents,
  }) async {
    if (failIds.contains(id)) {
      throw StateError('exact alarms revoked');
    }
    scheduled[id] = notificationDetails;
    titles[id] = title;
    pending.add(id);
  }

  // No platform implementation: exact alarms read as allowed.
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

/// Android with notifications off and every prompt declined.
final class _OffAndroid implements AndroidFlutterLocalNotificationsPlugin {
  @override
  Future<bool?> areNotificationsEnabled() async => false;

  @override
  Future<bool?> requestNotificationsPermission() async => false;

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

final class _AndroidPlugin implements FlutterLocalNotificationsPlugin {
  final android = _OffAndroid();

  @override
  T? resolvePlatformSpecificImplementation<
    T extends FlutterLocalNotificationsPlatform
  >() => android is T ? android as T : null;

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

const _texts = NotificationTexts(
  azanTitle: '',
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

/// Wall clock = UTC + [offset], for any location (a device whose zone moves).
final class _ShiftClock implements ZonedClock {
  _ShiftClock(this.offset);

  Duration offset;

  @override
  DateTime nowAt(LocationConfig location) =>
      instantAt(location, DateTime.now());

  @override
  DateTime instantAt(LocationConfig location, DateTime instant) {
    final w = instant.toUtc().add(offset);
    return DateTime(w.year, w.month, w.day, w.hour, w.minute, w.second);
  }

  @override
  DateTime utcInstantOf(LocationConfig location, DateTime wall) => DateTime.utc(
    wall.year,
    wall.month,
    wall.day,
    wall.hour,
    wall.minute,
    wall.second,
  ).subtract(offset);
}

void main() {
  setUpAll(TimezoneClock.initialize);

  late _FakePlugin plugin;
  late LocalNotificationsScheduler scheduler;
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    plugin = _FakePlugin();
    scheduler = LocalNotificationsScheduler(
      clock: TimezoneClock(),
      currentLocation: () => _dhaka,
      formatTime: (_) => '',
      plugin: plugin,
    );
  });

  test(
    'off before the first prompt is notRequested, after it denied',
    () async {
      SharedPreferencesAsyncPlatform.instance =
          InMemorySharedPreferencesAsync.empty();
      final android = LocalNotificationsScheduler(
        clock: TimezoneClock(),
        currentLocation: () => _dhaka,
        formatTime: (_) => '',
        plugin: _AndroidPlugin(),
      );
      expect(
        await android.permissionStatus(),
        NotificationPermission.notRequested,
      );
      await android.requestPermission();
      expect(await android.permissionStatus(), NotificationPermission.denied);
    },
  );

  // Well in the future at any test run time.
  final at = DateTime.now().add(const Duration(days: 1));
  NotificationItem azan(Prayer prayer, {bool beep = false}) => NotificationItem(
    kind: NotificationKind.azan,
    prayer: prayer,
    at: at.add(Duration(hours: prayer.index)),
    beepOnly: beep,
  );

  test('reschedule keeps shown notifications (cancels pending only)', () async {
    await scheduler.reschedule([azan(Prayer.fajr)], _texts);
    expect(plugin.cancelPendingCalls, 0);
    expect(plugin.cancelAllCalls, 0);
  });

  test(
    'reschedule cancels only dropped ids, never one that just came due',
    () async {
      final now = TimezoneClock().nowAt(_dhaka);
      // Dhuhr due 10 min ago, deferred by Android: still pending, unshown.
      final overdue = NotificationItem(
        kind: NotificationKind.azan,
        prayer: Prayer.dhuhr,
        at: now.subtract(const Duration(minutes: 10)),
      );
      // Lost alarm from yesterday (e.g. app force-stopped).
      final stale = NotificationItem(
        kind: NotificationKind.azan,
        prayer: Prayer.fajr,
        at: now.subtract(const Duration(days: 1)),
      );
      final kept = azan(Prayer.asr);
      final dropped = azan(Prayer.isha); // e.g. its azan was switched off
      plugin.pending.addAll([overdue.id, stale.id, kept.id, dropped.id]);

      await scheduler.reschedule([kept], _texts);

      expect(plugin.cancelled, {stale.id, dropped.id});
      expect(plugin.pending, {overdue.id, kept.id});
      expect(plugin.scheduled.keys, {kept.id});
    },
  );

  test(
    'after a zone change, overdue is read on the clock the ids were planned in',
    () async {
      // GPS: the device zone moves Dhaka (+6) → Bangkok (+7) between runs.
      final clock = _ShiftClock(const Duration(hours: 6));
      var now = DateTime.now().toUtc();
      LocalNotificationsScheduler build() => LocalNotificationsScheduler(
        clock: clock,
        currentLocation: () => const GpsLocation(latitude: 0, longitude: 0),
        formatTime: (_) => '',
        plugin: plugin,
        now: () => now,
      );
      final dhakaNow = clock.instantAt(_dhaka, now);
      // A Dhaka azan due 5 min after the second run: on Bangkok's clock
      // it would look 55 min overdue and survive the 1h grace.
      final oldAzan = NotificationItem(
        kind: NotificationKind.azan,
        prayer: Prayer.maghrib,
        at: dhakaNow.add(const Duration(minutes: 20)),
      );
      // Due 10 min before the second run, not fired yet: the grace keeps it.
      final justDue = NotificationItem(
        kind: NotificationKind.azan,
        prayer: Prayer.asr,
        at: dhakaNow.add(const Duration(minutes: 5)),
      );
      await build().reschedule([oldAzan, justDue], _texts);
      now = now.add(const Duration(minutes: 15));
      clock.offset = const Duration(hours: 7);

      // A fresh instance: the fire times survive a cold start.
      await build().reschedule([azan(Prayer.isha)], _texts);

      expect(plugin.cancelled, contains(oldAzan.id));
      expect(plugin.pending, contains(justDue.id));
    },
  );

  group('across a DST change (America/New_York)', () {
    const newYork = ManualCityLocation(
      City(
        name: 'New York',
        countryCode: 'US',
        latitude: 40.7128,
        longitude: -74.006,
        timezone: 'America/New_York',
      ),
    );
    late DateTime now;
    LocalNotificationsScheduler build() => LocalNotificationsScheduler(
      clock: TimezoneClock(),
      currentLocation: () => newYork,
      formatTime: (_) => '',
      plugin: plugin,
      now: () => now,
    );

    test('fall-back: a switched-off azan still due is cancelled', () async {
      // Sat 23:00 EDT (-4); clocks fall back Sun 02:00 → 01:00 EST (-5).
      now = DateTime.utc(2026, 11, 1, 3);
      final fajr = NotificationItem(
        kind: NotificationKind.azan,
        prayer: Prayer.fajr,
        at: DateTime(2026, 11, 1, 5, 50), // EST = 10:50 UTC
      );
      await build().reschedule([fajr], _texts);

      // Sun 05:10 EST: the user switches Fajr's azan off.
      now = DateTime.utc(2026, 11, 1, 10, 10);
      await build().reschedule([], _texts);

      expect(plugin.cancelled, contains(fajr.id));
    });

    test('spring-forward: a just-due alarm is left to fire', () async {
      // Sat 23:00 EST (-5); clocks spring forward Sun 02:00 → 03:00 EDT.
      now = DateTime.utc(2026, 3, 8, 4);
      final fajr = NotificationItem(
        kind: NotificationKind.azan,
        prayer: Prayer.fajr,
        at: DateTime(2026, 3, 8, 6), // EDT = 10:00 UTC
      );
      await build().reschedule([fajr], _texts);

      // Sun 06:10 EDT: due 10 min ago, deferred by Android, not fired yet.
      now = DateTime.utc(2026, 3, 8, 10, 10);
      await build().reschedule([], _texts);

      expect(plugin.cancelled, isNot(contains(fajr.id)));
      expect(plugin.pending, contains(fajr.id));
    });
  });

  test(
    'one failing item still schedules the rest; only all-failed fails',
    () async {
      final items = [azan(Prayer.fajr), azan(Prayer.dhuhr), azan(Prayer.asr)];
      plugin.failIds.add(items[1].id);
      final result = await scheduler.reschedule(items, _texts);
      expect(result, isA<Success<void>>(), reason: 'partial success');
      expect(plugin.scheduled.keys, {items[0].id, items[2].id});

      plugin.failIds.addAll(items.map((i) => i.id));
      expect(
        await scheduler.reschedule(items, _texts),
        isA<FailureResult<void>>(),
      );
    },
  );

  test('a cold-start tap replays once, not again on app recreation', () async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    final taps = <String?>[];
    Future<void> coldStart() async {
      final p = _FakePlugin()
        ..launch = const NotificationAppLaunchDetails(
          true,
          notificationResponse: NotificationResponse(
            notificationResponseType:
                NotificationResponseType.selectedNotification,
            id: 7,
            payload: '/muhasaba',
          ),
        );
      await LocalNotificationsScheduler(
        clock: TimezoneClock(),
        currentLocation: () => _dhaka,
        formatTime: (_) => '',
        plugin: p,
        onTap: (payload, _) => taps.add(payload),
      ).initialize(_texts);
    }

    await coldStart();
    await coldStart(); // recreated from recents: same launch intent
    expect(taps, ['/muhasaba']);
  });

  test('re-initializes only when the action title changes', () async {
    await scheduler.initialize(_texts);
    await scheduler.initialize(_texts);
    expect(plugin.initCalls, 1);
    await scheduler.initialize(
      const NotificationTexts(
        azanTitle: '',
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
        markAsPrayedAction: 'নামাজ পড়েছি',
        channelAzanName: '',
        channelRemindersName: '',
        channelSilentName: '',
        channelBeepName: '',
        prayerNames: {},
      ),
    );
    expect(plugin.initCalls, 2);
  });

  test("Friday's Dhuhr with a Jumu'ah time is named Jumu'ah", () async {
    const texts = NotificationTexts(
      azanTitle: '{prayer}',
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
      prayerNames: {'dhuhr': 'Dhuhr', jumuahNameKey: "Jumu'ah"},
    );
    final dhuhr = azan(Prayer.dhuhr);
    final jumuah = NotificationItem(
      kind: NotificationKind.azan,
      prayer: Prayer.dhuhr,
      at: at.add(const Duration(hours: 9)),
      jumuah: true,
    );
    await scheduler.reschedule([dhuhr, jumuah], texts);
    expect(plugin.titles[dhuhr.id], 'Dhuhr');
    expect(plugin.titles[jumuah.id], "Jumu'ah");
  });

  test('beep and azan use different channels and urgency', () async {
    final full = azan(Prayer.fajr);
    final beep = azan(Prayer.dhuhr, beep: true);
    await scheduler.reschedule([full, beep], _texts);
    final fullAndroid = plugin.scheduled[full.id]!.android!;
    final beepAndroid = plugin.scheduled[beep.id]!.android!;
    expect(beepAndroid.channelId, isNot(fullAndroid.channelId));
    expect(fullAndroid.importance, Importance.high);
    expect(beepAndroid.importance, Importance.defaultImportance);
    expect(beepAndroid.playSound, isTrue);
    expect(
      plugin.scheduled[beep.id]!.iOS!.interruptionLevel,
      InterruptionLevel.active,
    );
  });
}
