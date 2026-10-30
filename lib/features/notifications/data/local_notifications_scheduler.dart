import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../../core/utils/result.dart';
import '../../settings/domain/entities/location_config.dart';
import '../../settings/domain/repositories/zoned_clock.dart';
import '../domain/entities/notification_item.dart';
import '../domain/entities/notification_texts.dart';
import '../domain/repositories/notification_scheduler.dart';

/// flutter_local_notifications implementation. The ONLY class touching
/// the plugin (guide §5). Channels are created on the fly per item.
final class LocalNotificationsScheduler implements NotificationScheduler {
  LocalNotificationsScheduler({
    required ZonedClock clock,
    required LocationConfig? Function() currentLocation,
    required String Function(DateTime) formatTime,
    void Function(String? payload, String? actionId)? onTap,
    FlutterLocalNotificationsPlugin? plugin,
    SharedPreferencesAsync? prefs,
  }) : _prefs = prefs,
       _clock = clock,
       _currentLocation = currentLocation,
       _formatTime = formatTime,
       _onTap = onTap,
       _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  static const _azanCategoryId = 'productive_muslim_azan';

  /// Set once the OS prompt has been shown. Before that, iOS (sometimes)
  /// and Android 13+ report "off", which is not the same as "denied".
  static const _promptedKey = 'notif_permission_prompted';

  /// The last cold-start tap replayed. Android hands back the same launch
  /// intent when the app is recreated from recents; replay each tap once.
  static const _launchKey = 'notif_last_launch_tap';

  final SharedPreferencesAsync? _prefs;
  late final SharedPreferencesAsync _store = _prefs ?? SharedPreferencesAsync();

  Future<bool> _prompted() async {
    try {
      return await _store.getBool(_promptedKey) ?? false;
    } on Exception {
      return true; // unknown: keep the old "off = denied" reading
    }
  }

  /// Action id of the azan "mark as prayed" button.
  static const markPrayedActionId = 'mark_prayed';

  final FlutterLocalNotificationsPlugin _plugin;
  final ZonedClock _clock;

  /// Scheduling needs the active location to convert wall → instant.
  final LocationConfig? Function() _currentLocation;

  /// Locale-aware time formatting injected from the composition root.
  final String Function(DateTime) _formatTime;

  /// Tap / action callback with the item's payload (an in-app route).
  final void Function(String? payload, String? actionId)? _onTap;

  void _dispatch(NotificationResponse response) =>
      _onTap?.call(response.payload, response.actionId);

  /// Action title the plugin was initialized with; null until it succeeds.
  String? _initializedWith;

  @override
  Future<void> initialize(NotificationTexts texts) async {
    final first = _initializedWith == null;
    if (_initializedWith == texts.markAsPrayedAction) {
      return;
    }
    // Re-initializing re-registers the iOS category (setNotificationCategories
    // replaces them), localizing "Mark as prayed" after a language change.
    await _plugin.initialize(
      settings: InitializationSettings(
        android: const AndroidInitializationSettings(
          '@drawable/ic_stat_notify',
        ),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
          notificationCategories: [
            DarwinNotificationCategory(
              _azanCategoryId,
              actions: [
                // Foreground: opens the app so the in-app handler records it.
                DarwinNotificationAction.plain(
                  markPrayedActionId,
                  texts.markAsPrayedAction,
                  options: {DarwinNotificationActionOption.foreground},
                ),
              ],
            ),
          ],
        ),
      ),
      onDidReceiveNotificationResponse: _dispatch,
    );
    _initializedWith = texts.markAsPrayedAction;
    if (!first) {
      return;
    }
    // Cold start from a tap: replay it once the app is up.
    final launch = await _plugin.getNotificationAppLaunchDetails();
    final response = launch?.notificationResponse;
    if ((launch?.didNotificationLaunchApp ?? false) && response != null) {
      final tap = '${response.id}|${response.actionId}|${response.payload}';
      try {
        if (await _store.getString(_launchKey) == tap) {
          return;
        }
        await _store.setString(_launchKey, tap);
      } on Exception {
        // Unreadable: replaying a stale tap beats dropping a real one.
      }
      _dispatch(response);
    }
  }

  AndroidFlutterLocalNotificationsPlugin? get _android => _plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  IOSFlutterLocalNotificationsPlugin? get _ios => _plugin
      .resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin
      >();

  @override
  Future<NotificationPermission> permissionStatus() async {
    final android = _android;
    if (android != null) {
      final enabled = await android.areNotificationsEnabled() ?? false;
      if (enabled) {
        return NotificationPermission.granted;
      }
      return await _prompted()
          ? NotificationPermission.denied
          : NotificationPermission.notRequested;
    }
    final ios = _ios;
    if (ios != null) {
      final settings = await ios.checkPermissions();
      return switch (settings?.isAlertEnabled) {
        true => NotificationPermission.granted,
        false when !await _prompted() => NotificationPermission.notRequested,
        false => NotificationPermission.denied,
        null => NotificationPermission.notRequested,
      };
    }
    return NotificationPermission.notRequested;
  }

  @override
  Future<NotificationPermission> requestPermission() async {
    try {
      await _store.setBool(_promptedKey, true);
    } on Exception {
      // Best-effort: worst case the next tap re-prompts instead of
      // opening system settings.
    }
    final android = _android;
    if (android != null) {
      final granted = await android.requestNotificationsPermission() ?? false;
      return granted
          ? NotificationPermission.granted
          : NotificationPermission.denied;
    }
    final ios = _ios;
    if (ios != null) {
      final granted = await ios.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return (granted ?? false)
          ? NotificationPermission.granted
          : NotificationPermission.denied;
    }
    return NotificationPermission.notRequested;
  }

  @override
  Future<bool> canScheduleExactAlarms() async =>
      await _android?.canScheduleExactNotifications() ?? true;

  @override
  Future<void> requestExactAlarmPermission() async =>
      _android?.requestExactAlarmsPermission();

  // geolocator is already a dependency and opens the app's settings page
  // on both platforms.
  @override
  Future<void> openSystemSettings() async => Geolocator.openAppSettings();

  @override
  Future<Result<void>> reschedule(
    List<NotificationItem> items,
    NotificationTexts texts,
  ) async {
    try {
      final location = _currentLocation();
      if (location == null) {
        await cancelAll();
        return const Result.success(null);
      }
      // Pending only: cancelAll() would also clear azans already in the
      // tray, taking their "mark as prayed" action with them.
      await _plugin.cancelAllPendingNotifications();
      final exact = await canScheduleExactAlarms();
      final mode = exact
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle;
      // One bad item (e.g. exact-alarm permission revoked mid-loop) must not
      // leave the rest unscheduled. Partial success is success (logged), so
      // the caller still records the run; only all-failed is a failure.
      Object? firstError;
      var failed = 0;
      var attempted = 0;
      for (final item in items) {
        final utc = _clock.utcInstantOf(location, item.at);
        // zonedSchedule throws on a past instant; an item that came due
        // while planning is simply skipped, not reported as a failure.
        if (!utc.isAfter(DateTime.now().add(const Duration(seconds: 5)))) {
          continue;
        }
        final (title, body) = _texts(item, texts);
        attempted++;
        try {
          await _plugin.zonedSchedule(
            id: item.id,
            title: title,
            body: body,
            scheduledDate: tz.TZDateTime.from(utc, tz.UTC),
            notificationDetails: _details(item, texts),
            androidScheduleMode: mode,
            payload: switch (item.kind) {
              NotificationKind.muhasabaEvening => '/muhasaba',
              NotificationKind.dailyReminder => texts.dailyReminderRoute,
              NotificationKind.dailyAyah => '/home',
              NotificationKind.dailyHadith => '/hadith',
              // Prayer + its prayer-day date ride along for the "mark as
              // prayed" action, so a late (or after-midnight isha) tap
              // files the right day.
              NotificationKind.azan =>
                '/home?prayer=${item.prayer?.name}'
                    '&date=${_dateParam(item.prayerDay ?? item.at)}',
              // Tap → after-salah duas; the action files the prayer.
              NotificationKind.focusEnd =>
                '/dua?category=salah&prayer=${item.prayer?.name}'
                    '&date=${_dateParam(item.prayerDay ?? item.at)}',
              _ => '/home',
            },
          );
        } on Object catch (e) {
          firstError ??= e;
          failed++;
        }
      }
      if (failed > 0) {
        debugPrint('$failed/$attempted notifications failed: $firstError');
      }
      if (failed > 0 && failed == attempted) {
        return Result.failure(
          UnexpectedFailure('Failed to schedule notifications', firstError),
        );
      }
      return const Result.success(null);
    } on Object catch (e) {
      return Result.failure(
        UnexpectedFailure('Failed to schedule notifications', e),
      );
    }
  }

  @override
  Future<void> cancelAll() => _plugin.cancelAll();

  (String, String) _texts(NotificationItem item, NotificationTexts t) {
    final time = _formatTime(item.eventAt ?? item.at);
    final prayer =
        (item.jumuah ? t.prayerNames[jumuahNameKey] : null) ??
        t.prayerNames[item.prayer?.name] ??
        '';
    String f(String template) =>
        NotificationTexts.fill(template, prayer: prayer, time: time);
    return switch (item.kind) {
      NotificationKind.azan => (f(t.azanTitle), f(t.azanBody)),
      NotificationKind.jamaat => (f(t.jamaatTitle), f(t.jamaatBody)),
      NotificationKind.sahriWarning => (f(t.sahriTitle), f(t.sahriBody)),
      NotificationKind.iftar => (f(t.iftarTitle), f(t.iftarBody)),
      NotificationKind.muhasabaEvening => (
        f(t.muhasabaTitle),
        f(t.muhasabaBody),
      ),
      NotificationKind.dailyReminder => (
        f(t.dailyReminderTitle),
        f(t.dailyReminderBody),
      ),
      NotificationKind.dailyAyah => (
        t.dailyAyahTitle.isEmpty
            ? f(t.dailyReminderTitle)
            : f(t.dailyAyahTitle),
        t.dailyAyahBody.isEmpty ? f(t.dailyReminderBody) : f(t.dailyAyahBody),
      ),
      NotificationKind.dailyHadith => (
        t.dailyHadithTitle.isEmpty
            ? f(t.dailyReminderTitle)
            : f(t.dailyHadithTitle),
        t.dailyHadithBody.isEmpty
            ? f(t.dailyReminderBody)
            : f(t.dailyHadithBody),
      ),
      NotificationKind.keepAlive => (t.keepAliveTitle, t.keepAliveBody),
      NotificationKind.jamaatFocus => (f(t.focusTitle), f(t.focusBody)),
      NotificationKind.focusEnd => (f(t.focusEndTitle), f(t.focusEndBody)),
    };
  }

  NotificationDetails _details(NotificationItem item, NotificationTexts t) {
    // Quiet like a silent azan: no sound, low priority, passive on iOS.
    final quiet = item.silent || item.kind == NotificationKind.keepAlive;
    // Beep: one short default tone on its own default-importance channel —
    // no heads-up, vibration, or time-sensitive break-through. Azan keeps
    // the high-importance channel.
    // ponytail: azan plays the default sound too; real adhan audio needs a
    // bundled file (android/app/src/main/res/raw + iOS bundle) wired via
    // `sound:` on a NEW channel id (Android channels are immutable).
    final beep = item.kind == NotificationKind.azan && item.beepOnly;
    final (channelId, channelName, sound) = switch (item.kind) {
      NotificationKind.azan when item.silent => (
        'productive_muslim_silent',
        t.channelSilentName,
        false,
      ),
      NotificationKind.azan when item.beepOnly => (
        'productive_muslim_beep',
        t.channelBeepName,
        true,
      ),
      NotificationKind.azan => (
        'productive_muslim_azan',
        t.channelAzanName,
        true,
      ),
      // Own low-importance channel: Android 8+ takes importance from the
      // channel, not the notification.
      NotificationKind.keepAlive => (
        'productive_muslim_keep_alive',
        t.keepAliveTitle,
        false,
      ),
      _ => ('productive_muslim_reminders', t.channelRemindersName, true),
    };
    return NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        channelName,
        importance: quiet
            ? Importance.low
            : (beep ? Importance.defaultImportance : Importance.high),
        priority: quiet
            ? Priority.low
            : (beep ? Priority.defaultPriority : Priority.high),
        playSound: sound,
        enableVibration: !beep,
        category: AndroidNotificationCategory.reminder,
        actions:
            item.kind == NotificationKind.azan ||
                item.kind == NotificationKind.focusEnd
            ? [
                AndroidNotificationAction(
                  markPrayedActionId,
                  t.markAsPrayedAction,
                  showsUserInterface: true,
                ),
              ]
            : null,
      ),
      iOS: DarwinNotificationDetails(
        categoryIdentifier:
            item.kind == NotificationKind.azan ||
                item.kind == NotificationKind.focusEnd
            ? _azanCategoryId
            : null,
        presentSound: sound,
        interruptionLevel: quiet
            ? InterruptionLevel.passive
            : beep
            ? InterruptionLevel.active
            : InterruptionLevel.timeSensitive,
      ),
    );
  }
}

/// yyyy-mm-dd of a wall-clock [at] (parsed back by `DateTime.parse`).
String _dateParam(DateTime at) =>
    '${at.year.toString().padLeft(4, '0')}-'
    '${at.month.toString().padLeft(2, '0')}-'
    '${at.day.toString().padLeft(2, '0')}';
