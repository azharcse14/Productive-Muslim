import 'package:flutter_local_notifications/flutter_local_notifications.dart';
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
    FlutterLocalNotificationsPlugin? plugin,
  })  : _clock = clock,
        _currentLocation = currentLocation,
        _formatTime = formatTime,
        _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  static const _azanCategoryId = 'qalbee_azan';
  static const _markPrayedActionId = 'mark_prayed';

  final FlutterLocalNotificationsPlugin _plugin;
  final ZonedClock _clock;

  /// Scheduling needs the active location to convert wall → instant.
  final LocationConfig? Function() _currentLocation;

  /// Locale-aware time formatting injected from the composition root.
  final String Function(DateTime) _formatTime;

  bool _initialized = false;

  @override
  Future<void> initialize(NotificationTexts texts) async {
    if (_initialized) {
      return;
    }
    await _plugin.initialize(
      settings: InitializationSettings(
        android: const AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
          notificationCategories: [
            DarwinNotificationCategory(
              _azanCategoryId,
              actions: [
                DarwinNotificationAction.plain(
                  _markPrayedActionId,
                  texts.markAsPrayedAction,
                ),
              ],
            ),
          ],
        ),
      ),
    );
    _initialized = true;
  }

  AndroidFlutterLocalNotificationsPlugin? get _android =>
      _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

  IOSFlutterLocalNotificationsPlugin? get _ios =>
      _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();

  @override
  Future<NotificationPermission> permissionStatus() async {
    final android = _android;
    if (android != null) {
      final enabled = await android.areNotificationsEnabled() ?? false;
      return enabled
          ? NotificationPermission.granted
          : NotificationPermission.denied;
    }
    final ios = _ios;
    if (ios != null) {
      final settings = await ios.checkPermissions();
      return switch (settings?.isAlertEnabled) {
        true => NotificationPermission.granted,
        false => NotificationPermission.denied,
        null => NotificationPermission.notRequested,
      };
    }
    return NotificationPermission.notRequested;
  }

  @override
  Future<NotificationPermission> requestPermission() async {
    final android = _android;
    if (android != null) {
      final granted = await android.requestNotificationsPermission() ?? false;
      return granted
          ? NotificationPermission.granted
          : NotificationPermission.denied;
    }
    final ios = _ios;
    if (ios != null) {
      final granted =
          await ios.requestPermissions(alert: true, badge: true, sound: true);
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
      await _plugin.cancelAll();
      final exact = await canScheduleExactAlarms();
      final mode = exact
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle;
      for (final item in items) {
        final utc = _clock.utcInstantOf(location, item.at);
        final (title, body) = _texts(item, texts);
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
            _ => '/home',
          },
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
    final time = _formatTime(item.at);
    final prayer = t.prayerNames[item.prayer?.name] ?? '';
    String f(String template) => NotificationTexts.fill(
          template,
          prayer: prayer,
          time: time,
        );
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
    };
  }

  NotificationDetails _details(NotificationItem item, NotificationTexts t) {
    final (channelId, channelName, sound) = switch (item.kind) {
      NotificationKind.azan when item.silent => (
          'qalbee_silent',
          t.channelSilentName,
          false,
        ),
      NotificationKind.azan => ('qalbee_azan', t.channelAzanName, true),
      _ => ('qalbee_reminders', t.channelRemindersName, true),
    };
    return NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        channelName,
        importance: item.silent ? Importance.low : Importance.high,
        priority: item.silent ? Priority.low : Priority.high,
        playSound: sound,
        category: AndroidNotificationCategory.reminder,
        actions: item.kind == NotificationKind.azan
            ? [
                AndroidNotificationAction(
                  _markPrayedActionId,
                  t.markAsPrayedAction,
                  showsUserInterface: true,
                ),
              ]
            : null,
      ),
      iOS: DarwinNotificationDetails(
        categoryIdentifier:
            item.kind == NotificationKind.azan ? _azanCategoryId : null,
        presentSound: sound,
        interruptionLevel: item.silent
            ? InterruptionLevel.passive
            : InterruptionLevel.timeSensitive,
      ),
    );
  }
}
