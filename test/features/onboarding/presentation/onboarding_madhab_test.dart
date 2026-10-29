import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:productive_muslim/core/l10n/gen/app_localizations.dart';
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
import 'package:productive_muslim/features/settings/presentation/state/settings_store.dart';

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
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
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
}) async {
  final repo = _Repo(AppSettings(location: _cairo, prayerParams: params));
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
}
