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
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:timezone/timezone.dart';

/// Records schedule calls; throws for the ids in [failIds].
final class _FakePlugin implements FlutterLocalNotificationsPlugin {
  final scheduled = <int, NotificationDetails>{};
  final titles = <int, String?>{};
  final failIds = <int>{};
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

void main() {
  setUpAll(TimezoneClock.initialize);

  late _FakePlugin plugin;
  late LocalNotificationsScheduler scheduler;
  setUp(() {
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
    expect(plugin.cancelPendingCalls, 1);
    expect(plugin.cancelAllCalls, 0);
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
