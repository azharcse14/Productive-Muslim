import 'package:flutter_test/flutter_test.dart';
import 'package:productive_muslim/core/utils/result.dart';
import 'package:productive_muslim/features/notifications/domain/entities/notification_item.dart';
import 'package:productive_muslim/features/notifications/domain/entities/notification_texts.dart';
import 'package:productive_muslim/features/notifications/domain/repositories/notification_scheduler.dart';
import 'package:productive_muslim/features/notifications/domain/usecases/reschedule_notifications.dart';
import 'package:productive_muslim/features/notifications/presentation/state/notification_controller.dart';
import 'package:productive_muslim/features/prayer_times/data/repositories/prayer_day_repository_impl.dart';
import 'package:productive_muslim/features/prayer_times/domain/usecases/get_prayer_day.dart';
import 'package:productive_muslim/features/settings/data/datasources/timezone_clock.dart';
import 'package:productive_muslim/features/settings/domain/entities/app_settings.dart';
import 'package:productive_muslim/features/settings/domain/entities/city.dart';
import 'package:productive_muslim/features/settings/domain/entities/location_config.dart';
import 'package:productive_muslim/features/settings/domain/entities/prayer_params.dart';
import 'package:productive_muslim/features/settings/domain/repositories/settings_repository.dart';
import 'package:productive_muslim/features/settings/domain/usecases/get_settings.dart';
import 'package:productive_muslim/features/settings/domain/usecases/save_settings.dart';
import 'package:productive_muslim/features/settings/presentation/state/settings_store.dart';

import '../../../helpers/mosque_fakes.dart';

final class _CountingScheduler implements NotificationScheduler {
  int initCalls = 0;
  int rescheduleCalls = 0;
  NotificationTexts? lastTexts;

  @override
  Future<void> initialize(NotificationTexts texts) async {
    initCalls++;
  }

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
    rescheduleCalls++;
    lastTexts = texts;
    return const Result.success(null);
  }

  @override
  Future<void> cancelAll() async {}
}

final class _InMemoryRepo implements SettingsRepository {
  AppSettings stored;
  _InMemoryRepo(this.stored);

  @override
  Future<Result<AppSettings>> load() async => Result.success(stored);

  @override
  Future<Result<void>> save(AppSettings settings) async {
    stored = settings;
    return const Result.success(null);
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

  test('start initializes, schedules once, and reschedules on changes',
      () async {
    final scheduler = _CountingScheduler();
    final repo = _InMemoryRepo(const AppSettings(location: _dhaka));
    final settings = SettingsStore(GetSettings(repo), SaveSettings(repo));
    await settings.load();
    final (mosqueStore, _) = await makeMosqueStore();
    final controller = NotificationController(
      reschedule: RescheduleNotifications(
        getPrayerDay: GetPrayerDay(PrayerDayRepositoryImpl(TimezoneClock())),
        scheduler: scheduler,
        clock: TimezoneClock(),
      ),
      scheduler: scheduler,
      settings: settings,
      mosque: mosqueStore,
    );

    await controller.start();
    expect(scheduler.initCalls, 1);
    expect(scheduler.rescheduleCalls, 1);

    // A prayer-param change triggers a debounced reschedule.
    await settings.setMadhab(Madhab.shafi);
    await Future<void>.delayed(const Duration(milliseconds: 600));
    expect(scheduler.rescheduleCalls, 2);

    // Locale change re-resolves the texts.
    await settings.setLocale('bn');
    await Future<void>.delayed(const Duration(milliseconds: 600));
    expect(scheduler.rescheduleCalls, 3);
    expect(scheduler.lastTexts!.channelAzanName, 'আজান');

    // start() is idempotent.
    await controller.start();
    expect(scheduler.initCalls, 1);

    controller.dispose();
  });
}
