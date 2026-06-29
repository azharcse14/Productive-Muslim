import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:productive_muslim/core/l10n/gen/app_localizations.dart';
import 'package:productive_muslim/core/theme/app_theme.dart';
import 'package:productive_muslim/core/utils/result.dart';
import 'package:productive_muslim/features/notifications/domain/entities/notification_item.dart';
import 'package:productive_muslim/features/notifications/domain/entities/notification_texts.dart';
import 'package:productive_muslim/features/notifications/domain/repositories/notification_scheduler.dart';
import 'package:productive_muslim/features/notifications/presentation/screens/notification_settings_screen.dart';
import 'package:productive_muslim/features/settings/domain/entities/app_settings.dart';
import 'package:productive_muslim/features/settings/domain/entities/notification_matrix.dart';
import 'package:productive_muslim/features/settings/domain/entities/prayer_params.dart';
import 'package:productive_muslim/features/settings/domain/repositories/settings_repository.dart';
import 'package:productive_muslim/features/settings/domain/usecases/get_settings.dart';
import 'package:productive_muslim/features/settings/domain/usecases/save_settings.dart';
import 'package:productive_muslim/features/settings/presentation/state/settings_store.dart';

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
  });

  NotificationPermission permission;
  bool exactAlarms;
  bool exactRequested = false;

  @override
  Future<void> initialize(NotificationTexts texts) async {}

  @override
  Future<NotificationPermission> permissionStatus() async => permission;

  @override
  Future<NotificationPermission> requestPermission() async =>
      permission = NotificationPermission.granted;

  @override
  Future<bool> canScheduleExactAlarms() async => exactAlarms;

  @override
  Future<void> requestExactAlarmPermission() async {
    exactRequested = true;
    exactAlarms = true;
  }

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

Future<void> _register(_FakeScheduler scheduler) async {
  _repo = _InMemoryRepo();
  final store = SettingsStore(GetSettings(_repo), SaveSettings(_repo));
  await store.load();
  GetIt.I
    ..registerSingleton<SettingsStore>(store)
    ..registerSingleton<NotificationScheduler>(scheduler);
}

Widget _app() => MaterialApp(
      theme: AppTheme.light(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const NotificationSettingsScreen(),
    );

void main() {
  tearDown(() => GetIt.I.reset());

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
  });
}
