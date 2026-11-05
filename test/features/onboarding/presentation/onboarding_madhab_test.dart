import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:productive_muslim/core/l10n/gen/app_localizations.dart';
import 'package:productive_muslim/core/settings/settings_store.dart';
import 'package:productive_muslim/core/theme/app_theme.dart';
import 'package:productive_muslim/core/utils/result.dart';
import 'package:productive_muslim/features/notifications/domain/repositories/notification_scheduler.dart';
import 'package:productive_muslim/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:productive_muslim/features/settings/domain/entities/app_settings.dart';
import 'package:productive_muslim/features/settings/domain/entities/city.dart';
import 'package:productive_muslim/features/settings/domain/entities/location_config.dart';
import 'package:productive_muslim/features/settings/domain/entities/prayer_params.dart';
import 'package:productive_muslim/features/settings/domain/repositories/settings_repository.dart';
import 'package:productive_muslim/features/settings/domain/usecases/get_settings.dart';
import 'package:productive_muslim/features/settings/domain/usecases/save_settings.dart';

final class _Repo implements SettingsRepository {
  _Repo(this.stored);
  AppSettings stored;

  @override
  Future<Result<AppSettings>> load() async => Result.success(stored);

  @override
  Future<Result<void>> save(AppSettings settings) async {
    stored = settings;
    return const Result.success(null);
  }
}

final class _NoopScheduler implements NotificationScheduler {
  /// Holds the OS prompt open until completed.
  final prompt = Completer<NotificationPermission>();
  int prompts = 0;

  @override
  Future<NotificationPermission> requestPermission() {
    prompts++;
    return prompt.future;
  }

  @override
  Future<bool> canScheduleExactAlarms() async => true;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Grants notifications; exact alarms not yet allowed.
final class _GrantingScheduler extends _NoopScheduler {
  bool exactRequested = false;

  @override
  Future<NotificationPermission> requestPermission() async =>
      NotificationPermission.granted;

  @override
  Future<bool> canScheduleExactAlarms() async => false;

  @override
  Future<void> requestExactAlarmPermission() async => exactRequested = true;
}

const _cairo = ManualCityLocation(
  City(
    name: 'Cairo',
    countryCode: 'EG',
    latitude: 30.04,
    longitude: 31.24,
    timezone: 'Africa/Cairo',
  ),
);

Future<_Repo> _pumpToLocationStep(
  WidgetTester tester, {
  PrayerParams params = const PrayerParams(),
  bool rerun = false,
  LocationConfig location = _cairo,
  NotificationScheduler? scheduler,
}) async {
  final repo = _Repo(AppSettings(location: location, prayerParams: params));
  final store = SettingsStore(GetSettings(repo), SaveSettings(repo));
  await store.load();
  GetIt.I
    ..registerSingleton<SettingsStore>(store)
    ..registerSingleton<NotificationScheduler>(scheduler ?? _NoopScheduler());
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: OnboardingScreen(rerun: rerun),
    ),
  );
  // Welcome (with the language picker) → location.
  await tester.tap(find.text('Next').hitTestable());
  await tester.pumpAndSettle();
  return repo;
}

void main() {
  tearDown(GetIt.I.reset);

  testWidgets('leaving the location step pre-selects the region madhab', (
    tester,
  ) async {
    final repo = await _pumpToLocationStep(tester);
    await tester.tap(find.text('Next').hitTestable());
    await tester.pumpAndSettle();
    expect(repo.stored.prayerParams.madhab, Madhab.shafi); // Egypt
  });

  testWidgets('a madhab already changed from the default is kept', (
    tester,
  ) async {
    final repo = await _pumpToLocationStep(
      tester,
      params: const PrayerParams(madhab: Madhab.maliki),
    );
    await tester.tap(find.text('Next').hitTestable());
    await tester.pumpAndSettle();
    expect(repo.stored.prayerParams.madhab, Madhab.maliki);
  });

  testWidgets('a rerun keeps a saved Hanafi / Karachi choice', (tester) async {
    final repo = await _pumpToLocationStep(tester, rerun: true);
    await tester.tap(find.text('Next').hitTestable());
    await tester.pumpAndSettle();
    const defaults = PrayerParams();
    expect(repo.stored.prayerParams.madhab, defaults.madhab);
    expect(repo.stored.prayerParams.method, defaults.method);
  });

  testWidgets('leaving the location step pre-selects the region method', (
    tester,
  ) async {
    final repo = await _pumpToLocationStep(tester);
    await tester.tap(find.text('Next').hitTestable());
    await tester.pumpAndSettle();
    expect(repo.stored.prayerParams.method, CalculationMethodId.egyptian);
  });

  testWidgets('two Asr choices; skipping notifications reaches Bismillah', (
    tester,
  ) async {
    await _pumpToLocationStep(tester);
    await tester.tap(find.text('Next').hitTestable());
    await tester.pumpAndSettle();
    expect(find.text('Standard (Shafiʿi, Maliki, Hanbali)'), findsOneWidget);
    expect(find.text('Maliki'), findsNothing);
    await tester.tap(find.text('Next').hitTestable()); // madhab
    await tester.pumpAndSettle();
    expect(find.text('Suggested for your region'), findsOneWidget);
    await tester.tap(find.text('Next').hitTestable()); // method
    await tester.pumpAndSettle();
    await tester.tap(find.text('Maybe later').hitTestable());
    await tester.pumpAndSettle();
    expect(find.text('Bismillah'), findsOneWidget);
    expect(find.text('Begin'), findsOneWidget);
  });

  testWidgets('a GPS fix with no nearby city reads "Current location"', (
    tester,
  ) async {
    await _pumpToLocationStep(
      tester,
      location: const GpsLocation(latitude: 10, longitude: 20),
    );
    expect(find.text('Current location'), findsOneWidget);
    expect(find.text('Not set'), findsNothing);
  });

  testWidgets('a double tap on Allow asks once and moves one step', (
    tester,
  ) async {
    final scheduler = _NoopScheduler();
    await _pumpToLocationStep(tester, scheduler: scheduler);
    for (var i = 0; i < 3; i++) {
      await tester.tap(find.text('Next').hitTestable());
      await tester.pumpAndSettle();
    }
    final allow = find.text('Allow notifications').hitTestable();
    await tester.tap(allow);
    await tester.pump();
    await tester.tap(allow, warnIfMissed: false);
    await tester.pump();
    scheduler.prompt.complete(NotificationPermission.granted);
    await tester.pumpAndSettle();
    expect(scheduler.prompts, 1);
    expect(find.text('Bismillah'), findsOneWidget);
  });

  testWidgets('a failing permission plugin still advances, as denied', (
    tester,
  ) async {
    final scheduler = _NoopScheduler();
    await _pumpToLocationStep(tester, scheduler: scheduler);
    for (var i = 0; i < 3; i++) {
      await tester.tap(find.text('Next').hitTestable());
      await tester.pumpAndSettle();
    }
    await tester.tap(find.text('Allow notifications').hitTestable());
    await tester.pump();
    scheduler.prompt.completeError(PlatformException(code: 'boom'));
    await tester.pumpAndSettle();
    expect(find.text('Bismillah'), findsOneWidget);
    expect(find.byType(SnackBar), findsOneWidget);
  });

  testWidgets('with no location the location step says Set location', (
    tester,
  ) async {
    final repo = _Repo(const AppSettings());
    final store = SettingsStore(GetSettings(repo), SaveSettings(repo));
    await store.load();
    GetIt.I
      ..registerSingleton<SettingsStore>(store)
      ..registerSingleton<NotificationScheduler>(_NoopScheduler());
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const OnboardingScreen(),
      ),
    );
    await tester.tap(find.text('Next').hitTestable());
    await tester.pumpAndSettle();
    expect(find.text('Set location').hitTestable(), findsOneWidget);
  });
  testWidgets('the location step offers GPS and a city search directly', (
    tester,
  ) async {
    await _pumpToLocationStep(tester);
    expect(find.text('Use my location'), findsOneWidget);
    expect(find.text('Choose city manually'), findsOneWidget);
    expect(find.textContaining('Cairo'), findsOneWidget); // current choice
  });

  for (final (accept, label) in [
    (true, 'Allow exact alarms'),
    (false, 'Maybe later'),
  ]) {
    testWidgets('Android: exact alarms are explained first ($label)', (
      tester,
    ) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      final scheduler = _GrantingScheduler();
      await _pumpToLocationStep(tester, scheduler: scheduler);
      for (var i = 0; i < 3; i++) {
        // location → madhab → method → notifications
        await tester.tap(find.text('Next').hitTestable());
        await tester.pumpAndSettle();
      }
      await tester.tap(find.text('Allow notifications').hitTestable());
      await tester.pumpAndSettle();
      expect(find.text('One more permission'), findsOneWidget);
      expect(scheduler.exactRequested, isFalse);
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text(label),
        ),
      );
      await tester.pumpAndSettle();
      expect(scheduler.exactRequested, accept);
      expect(find.text('Bismillah'), findsOneWidget);
      debugDefaultTargetPlatformOverride = null;
    });
  }
}
