import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:productive_muslim/core/l10n/gen/app_localizations.dart';
import 'package:productive_muslim/core/theme/app_theme.dart';
import 'package:productive_muslim/core/utils/result.dart';
import 'package:productive_muslim/features/nearby_mosques/domain/external_launcher.dart';
import 'package:productive_muslim/features/notifications/data/jamaat_focus_bridge.dart';
import 'package:productive_muslim/features/notifications/domain/entities/notification_item.dart';
import 'package:productive_muslim/features/notifications/domain/entities/notification_texts.dart';
import 'package:productive_muslim/features/notifications/domain/repositories/jamaat_focus_control.dart';
import 'package:productive_muslim/features/notifications/domain/repositories/notification_scheduler.dart';
import 'package:productive_muslim/features/notifications/domain/usecases/reschedule_notifications.dart';
import 'package:productive_muslim/features/notifications/presentation/screens/notification_settings_screen.dart';
import 'package:productive_muslim/features/notifications/presentation/screens/notifications_screen.dart';
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
import 'package:productive_muslim/features/settings/domain/repositories/zoned_clock.dart';
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
  ) async => const Result.success(null);

  @override
  Future<void> cancelAll() async {}
}

final class _FakeLauncher implements ExternalLauncher {
  _FakeLauncher({this.accept = true});

  final bool accept;
  final launched = <Uri>[];

  @override
  Future<bool> launch(Uri uri) async {
    launched.add(uri);
    return accept;
  }
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
    ..registerSingleton<NotificationController>(_controller)
    ..registerSingleton<ZonedClock>(TimezoneClock())
    ..registerSingleton<JamaatFocusControl>(const JamaatFocusBridge());
}

Widget _app({Widget home = const NotificationSettingsScreen()}) => MaterialApp(
  theme: AppTheme.light(),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: home,
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
  tearDown(() async {
    _controller.dispose();
    await GetIt.I.reset();
  });

  group('NotificationSettingsScreen', () {
    testWidgets('renders the per-prayer matrix for all 5 prayers', (
      tester,
    ) async {
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
      expect(_repo.stored.notifications.modeFor(Prayer.fajr), AzanMode.silent);
    });

    testWidgets('toggling jamaat reminder persists and reveals lead row', (
      tester,
    ) async {
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
      // The lead row names what it's for (sahri has one too).
      final lead = find.bySemanticsLabel('Decrease Jamaat reminder Lead time');
      await tester.scrollUntilVisible(lead, 100);
      expect(lead, findsOneWidget);
    });

    testWidgets('iOS: Shortcuts guide opens and launches Shortcuts', (
      tester,
    ) async {
      final launcher = _FakeLauncher(accept: false);
      await _register(_FakeScheduler());
      GetIt.I.registerSingleton<ExternalLauncher>(launcher);
      // Jamaat focus has its own page, linked from notification settings.
      await tester.pumpWidget(_app(home: const JamaatFocusSettingsScreen()));
      await tester.pump();
      // No lock/strict on iOS — the OS doesn't allow them.
      expect(find.text('Strict mode'), findsNothing);
      await tester.scrollUntilVisible(
        find.text('Auto-silent with Shortcuts'),
        200,
      );
      await tester.ensureVisible(find.text('Auto-silent with Shortcuts'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Auto-silent with Shortcuts'));
      await tester.pumpAndSettle();
      expect(find.text('Auto-silent on iPhone'), findsOneWidget);
      await tester.tap(find.text('Open Shortcuts'));
      await tester.pump();
      expect(launcher.launched, [Uri.parse('shortcuts://')]);
      // A refused launch says so, visibly (not hidden under the sheet).
      await tester.pumpAndSettle();
      expect(
        find
            .text(
              "Couldn't open Shortcuts. Make sure the Shortcuts app is "
              'installed.',
            )
            .hitTestable(),
        findsOneWidget,
      );
    }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));

    testWidgets('denied permission shows education banner and CTA', (
      tester,
    ) async {
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

    testWidgets('no Enable CTA before the permission is known', (tester) async {
      await _register(
        _FakeScheduler(permission: NotificationPermission.notRequested),
      );
      await tester.pumpWidget(_app());
      expect(find.text('Enable notifications'), findsNothing);
      await tester.pump();
      // Never asked: explained too, not just a bare button.
      expect(
        find.textContaining("Notifications aren't on yet"),
        findsOneWidget,
      );
      expect(find.text('Enable notifications'), findsOneWidget);
    });

    testWidgets('previously denied still tries the OS prompt first', (
      tester,
    ) async {
      final scheduler = _FakeScheduler(
        permission: NotificationPermission.denied,
      );
      await _register(scheduler);
      await tester.pumpWidget(_app());
      await tester.pump();
      await tester.tap(find.text('Enable notifications'));
      await tester.pump();
      expect(scheduler.prompts, 1);
      expect(scheduler.settingsOpened, isFalse);
      expect(find.text('Enable notifications'), findsNothing);
    });

    testWidgets('truly denied falls through to system settings', (
      tester,
    ) async {
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

    testWidgets('declining a real first prompt stays on the screen', (
      tester,
    ) async {
      final scheduler = _FakeScheduler(
        permission: NotificationPermission.notRequested,
        promptResult: NotificationPermission.denied,
      );
      await _register(scheduler);
      await tester.pumpWidget(_app());
      await tester.pump();
      await tester.tap(find.text('Enable notifications'));
      await tester.pump();
      expect(scheduler.prompts, 1);
      expect(scheduler.settingsOpened, isFalse);
    });

    testWidgets('missing exact-alarm permission shows guidance', (
      tester,
    ) async {
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

    testWidgets('shows how far ahead reminders are scheduled', (tester) async {
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

    testWidgets('per-prayer segments name the prayer for screen readers', (
      tester,
    ) async {
      await _register(_FakeScheduler());
      await tester.pumpWidget(_app());
      await tester.pump();
      expect(find.bySemanticsLabel('Fajr: Azan'), findsOneWidget);
      expect(find.bySemanticsLabel('Isha: Off'), findsOneWidget);
    });

    testWidgets('hadith/dua of the day has its own switch', (tester) async {
      await _register(_FakeScheduler());
      await tester.pumpWidget(_app());
      await tester.pump();
      final title = find.text('Daily reminder');
      await tester.scrollUntilVisible(title, 200);
      final toggle = find.descendant(
        of: find.ancestor(of: title, matching: find.byType(Row)),
        matching: find.byType(Switch),
      );
      await tester.ensureVisible(toggle.first);
      await tester.pumpAndSettle();
      await tester.tap(toggle.first);
      await tester.pump();
      expect(_repo.stored.notifications.dailyReminder, isTrue);
    });
  });

  group('NotificationsScreen', () {
    testWidgets('lists the real plan: an Off prayer is absent', (tester) async {
      await _register(
        _FakeScheduler(),
        settings: const AppSettings(
          location: _dhaka,
          notifications: NotificationMatrix(
            prayerModes: {Prayer.fajr: AzanMode.off},
          ),
        ),
      );
      await tester.runAsync(_controller.start);
      await tester.pumpWidget(_app(home: const NotificationsScreen()));
      await tester.pump();
      expect(find.text("It's time for Dhuhr."), findsOneWidget);
      expect(find.text("It's time for Fajr."), findsNothing);
    });

    testWidgets('denied permission offers to enable', (tester) async {
      await _register(
        _FakeScheduler(permission: NotificationPermission.denied),
        settings: const AppSettings(location: _dhaka),
      );
      await tester.pumpWidget(_app(home: const NotificationsScreen()));
      await tester.pump();
      expect(find.text('Enable notifications'), findsOneWidget);
    });

    testWidgets('no location offers to set one', (tester) async {
      await _register(_FakeScheduler());
      await tester.pumpWidget(_app(home: const NotificationsScreen()));
      await tester.pump();
      expect(find.text('Set location'), findsOneWidget);
    });
  });

  group('Jamaat focus without the blocking service (Android)', () {
    const focus = MethodChannel('com.productivemuslim.app/focus');

    /// Native side of a build with or without `focusBlocking`.
    void mockNative(WidgetTester tester, {required bool blocking}) {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        focus,
        (call) async => switch (call.method) {
          'isBlockingAvailable' => blocking,
          'status' => <String, Object?>{'active': false},
          'hasDndAccess' || 'hasBlockAccess' => true,
          _ => null,
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          focus,
          null,
        ),
      );
    }

    // Everything on, including the lock and nafs lock the build can't serve.
    const settings = AppSettings(
      notifications: NotificationMatrix(jamaatFocus: true, nafsLock: true),
    );

    Future<void> pumpTall(WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 6000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      // Jamaat focus has its own page, linked from notification settings.
      await tester.pumpWidget(_app(home: const JamaatFocusSettingsScreen()));
      await tester.pumpAndSettle();
    }

    testWidgets('with the service: lock and nafs lock are offered', (
      tester,
    ) async {
      mockNative(tester, blocking: true);
      await _register(_FakeScheduler(), settings: settings);
      await pumpTall(tester);
      expect(find.text('Silent & lock at jamaat'), findsOneWidget);
      expect(find.text('Lock the phone'), findsOneWidget);
      expect(find.text('Shake to lock'), findsOneWidget);
    });

    testWidgets('without it: lock, nafs lock and disclosure are hidden', (
      tester,
    ) async {
      mockNative(tester, blocking: false);
      await _register(
        _FakeScheduler(),
        settings: const AppSettings(
          notifications: NotificationMatrix(nafsLock: true),
        ),
      );
      await pumpTall(tester);
      expect(find.text('Lock the phone'), findsNothing);
      expect(find.text('NAFS LOCK'), findsNothing);
      expect(find.text('Shake to lock'), findsNothing);
      expect(find.text('Accessibility access'), findsNothing);

      // DND-only focus still works: the switch turns it on and persists...
      final toggle = find.descendant(
        of: find.ancestor(
          of: find.text('Silent at jamaat'),
          matching: find.byType(Row),
        ),
        matching: find.byType(Switch),
      );
      await tester.tap(toggle.first);
      await tester.pumpAndSettle();
      expect(_repo.stored.notifications.jamaatFocus, isTrue);
      expect(find.text('Strict mode'), findsOneWidget);
      // ...and the stored lock settings are left as the user set them.
      expect(_repo.stored.notifications.jamaatFocusBlock, isTrue);
      expect(_repo.stored.notifications.nafsLock, isTrue);
    });
  });
}
