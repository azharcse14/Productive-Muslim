import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:productive_muslim/core/l10n/gen/app_localizations.dart';
import 'package:productive_muslim/core/theme/app_theme.dart';
import 'package:productive_muslim/core/utils/result.dart';
import 'package:productive_muslim/features/notifications/domain/entities/notification_item.dart';
import 'package:productive_muslim/features/notifications/domain/entities/notification_texts.dart';
import 'package:productive_muslim/features/notifications/domain/repositories/notification_scheduler.dart';
import 'package:productive_muslim/features/notifications/domain/usecases/reschedule_notifications.dart';
import 'package:productive_muslim/features/notifications/presentation/screens/notification_settings_screen.dart';
import 'package:productive_muslim/features/notifications/presentation/state/notification_controller.dart';
import 'package:productive_muslim/features/prayer_times/data/repositories/prayer_day_repository_impl.dart';
import 'package:productive_muslim/features/prayer_times/domain/usecases/get_prayer_day.dart';
import 'package:productive_muslim/features/settings/data/datasources/timezone_clock.dart';
import 'package:productive_muslim/features/settings/domain/entities/app_settings.dart';
import 'package:productive_muslim/features/settings/domain/entities/city.dart';
import 'package:productive_muslim/features/settings/domain/entities/location_config.dart';
import 'package:productive_muslim/features/settings/domain/entities/notification_matrix.dart';
import 'package:productive_muslim/features/settings/domain/entities/prayer_params.dart';
import 'package:productive_muslim/features/settings/domain/repositories/settings_repository.dart';
import 'package:productive_muslim/features/settings/domain/usecases/get_settings.dart';
import 'package:productive_muslim/features/settings/domain/usecases/save_settings.dart';
import 'package:productive_muslim/features/settings/presentation/state/settings_store.dart';

import '../../../helpers/mosque_fakes.dart';

final class _InMemoryRepo implements SettingsRepository {
  AppSettings stored = const AppSettings();

  @override
  Future<Result<AppSettings>> load() async => Result.success(stored);

  @override
  Future<Result<void>> save(AppSettings settings) async {
    stored = settings;
    return const Result.success(null);
  }
}

final class _FakeScheduler implements NotificationScheduler {
  _FakeScheduler({
    this.permission = NotificationPermission.granted,
    this.exactAlarms = true,
    this.promptResult = NotificationPermission.granted,
  });

  /// What the OS prompt answers ([requestPermission]).
  final NotificationPermission promptResult;
  int prompts = 0;

  NotificationPermission permission;
  bool exactAlarms;
  bool exactRequested = false;

  @override
  Future<void> initialize(NotificationTexts texts) async {}

  @override
  Future<NotificationPermission> permissionStatus() async => permission;

  @override
  Future<NotificationPermission> requestPermission() async {
    prompts++;
    return permission = promptResult;
  }

  @override
  Future<bool> canScheduleExactAlarms() async => exactAlarms;

  @override
  Future<void> requestExactAlarmPermission() async {
    exactRequested = true;
    exactAlarms = true;
  }

  bool settingsOpened = false;

  @override
  Future<void> openSystemSettings() async => settingsOpened = true;

  @override
  Future<Result<void>> reschedule(
    List<NotificationItem> items,
    NotificationTexts texts,
  ) async =>
      const Result.success(null);

  @override
  Future<void> cancelAll() async {}
}

late _InMemoryRepo _repo;
late NotificationController _controller;

Future<void> _register(
  _FakeScheduler scheduler, {
  AppSettings settings = const AppSettings(),
}) async {
  _repo = _InMemoryRepo()..stored = settings;
  final store = SettingsStore(GetSettings(_repo), SaveSettings(_repo));
  await store.load();
  final (mosque, _) = await makeMosqueStore();
  _controller = NotificationController(
    reschedule: RescheduleNotifications(
      getPrayerDay: GetPrayerDay(PrayerDayRepositoryImpl(TimezoneClock())),
      scheduler: scheduler,
      clock: TimezoneClock(),
    ),
    scheduler: scheduler,
    settings: store,
    mosque: mosque,
  );
  GetIt.I
    ..registerSingleton<SettingsStore>(store)
    ..registerSingleton<NotificationScheduler>(scheduler)
    ..registerSingleton<NotificationController>(_controller);
}

Widget _app() => MaterialApp(
      theme: AppTheme.light(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const NotificationSettingsScreen(),
    );

void main() {
  setUpAll(TimezoneClock.initialize);
  tearDown(() async {
    _controller.dispose();
    await GetIt.I.reset();
  });

  group('NotificationSettingsScreen', () {
    testWidgets('renders the per-prayer matrix for all 5 prayers',
        (tester) async {
      await _register(_FakeScheduler());
      await tester.pumpWidget(_app());
      await tester.pump();
      for (final name in ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha']) {
        expect(find.text(name), findsOneWidget);
      }
      expect(find.text('Azan'), findsNWidgets(5));
      expect(find.text('Off'), findsNWidgets(5));
    });

    testWidgets('changing a mode persists to settings', (tester) async {
      await _register(_FakeScheduler());
      await tester.pumpWidget(_app());
      await tester.pump();
      // Fajr row → tap its "Silent" segment.
      await tester.tap(find.text('Silent').first);
      await tester.pump();
      expect(
        _repo.stored.notifications.modeFor(Prayer.fajr),
        AzanMode.silent,
      );
    });

    testWidgets('toggling jamaat reminder persists and reveals lead row',
        (tester) async {
      await _register(_FakeScheduler());
      await tester.pumpWidget(_app());
      await tester.pump();
      await tester.scrollUntilVisible(find.text('Jamaat reminder'), 200);
      final jamaatSwitch = find.descendant(
        of: find.ancestor(
          of: find.text('Jamaat reminder'),
          matching: find.byType(Row),
        ),
        matching: find.byType(Switch),
      );
      await tester.ensureVisible(jamaatSwitch.first);
      await tester.pumpAndSettle();
      await tester.tap(jamaatSwitch.first);
      await tester.pump();
      expect(_repo.stored.notifications.jamaatReminder, isTrue);
      expect(find.text('Lead time'), findsNWidgets(2)); // sahri + jamaat
    });

    testWidgets('denied permission shows education banner and CTA',
        (tester) async {
      await _register(
        _FakeScheduler(permission: NotificationPermission.denied),
      );
      await tester.pumpWidget(_app());
      await tester.pump();
      expect(
        find.textContaining('Productive Muslim stays fully useful'),
        findsOneWidget,
      );
      expect(find.text('Enable notifications'), findsOneWidget);
    });

    testWidgets('never-asked (reads as denied) still gets the OS prompt',
        (tester) async {
      final scheduler =
          _FakeScheduler(permission: NotificationPermission.denied);
      await _register(scheduler);
      await tester.pumpWidget(_app());
      await tester.pump();
      await tester.tap(find.text('Enable notifications'));
      await tester.pump();
      expect(scheduler.prompts, 1);
      expect(scheduler.settingsOpened, isFalse);
      expect(find.text('Enable notifications'), findsNothing);
    });

    testWidgets('truly denied falls through to system settings',
        (tester) async {
      final scheduler = _FakeScheduler(
        permission: NotificationPermission.denied,
        promptResult: NotificationPermission.denied,
      );
      await _register(scheduler);
      await tester.pumpWidget(_app());
      await tester.pump();
      await tester.tap(find.text('Enable notifications'));
      await tester.pump();
      expect(scheduler.settingsOpened, isTrue);
    });

    testWidgets('missing exact-alarm permission shows guidance',
        (tester) async {
      final scheduler = _FakeScheduler(exactAlarms: false);
      await _register(scheduler);
      await tester.pumpWidget(_app());
      await tester.pump();
      expect(find.text('Allow exact alarms'), findsOneWidget);
      await tester.tap(find.text('Allow exact alarms'));
      await tester.pump();
      expect(scheduler.exactRequested, isTrue);
    });
  
    testWidgets('nothing scheduled says so', (tester) async {
      await _register(_FakeScheduler());
      await tester.pumpWidget(_app());
      await tester.pump();
      await tester.scrollUntilVisible(
        find.text('No reminders are scheduled right now.'),
        200,
      );
      expect(
        find.text('No reminders are scheduled right now.'),
        findsOneWidget,
      );
    });

    testWidgets('shows how far ahead reminders are scheduled',
        (tester) async {
      await _register(
        _FakeScheduler(),
        settings: const AppSettings(
          location: ManualCityLocation(
            City(
              name: 'Dhaka',
              countryCode: 'BD',
              latitude: 23.7104,
              longitude: 90.4074,
              timezone: 'Asia/Dhaka',
            ),
          ),
        ),
      );
      await tester.runAsync(_controller.start);
      await tester.pumpWidget(_app());
      await tester.pump();
      final until = find.textContaining('Reminders scheduled until ');
      await tester.scrollUntilVisible(until, 200);
      expect(until, findsOneWidget);
    });
  });
}
