import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:productive_muslim/core/l10n/gen/app_localizations.dart';
import 'package:productive_muslim/core/theme/app_theme.dart';
import 'package:productive_muslim/core/utils/result.dart';
import 'package:productive_muslim/features/settings/domain/entities/app_settings.dart';
import 'package:productive_muslim/features/settings/domain/entities/city.dart';
import 'package:productive_muslim/features/settings/domain/entities/location_config.dart';
import 'package:productive_muslim/features/settings/domain/entities/prayer_params.dart';
import 'package:productive_muslim/features/settings/domain/repositories/city_repository.dart';
import 'package:productive_muslim/features/settings/domain/repositories/location_repository.dart';
import 'package:productive_muslim/features/settings/domain/usecases/get_current_location.dart';
import 'package:productive_muslim/features/settings/domain/usecases/search_cities.dart';
import 'package:productive_muslim/features/settings/presentation/screens/location_picker_screen.dart';
import 'package:productive_muslim/features/settings/presentation/state/settings_store.dart';

import '../../../helpers/settings_fakes.dart';

const _cairo = City(
  name: 'Cairo',
  countryCode: 'EG',
  latitude: 30.04,
  longitude: 31.24,
  timezone: 'Africa/Cairo',
);

/// Makes the city search fail (reset per test).
var _citiesFail = false;

final class _Cities implements CityRepository {
  @override
  Future<Result<List<City>>> search(String query, {int limit = 30}) async =>
      _citiesFail
      ? const Result.failure(UnexpectedFailure('boom'))
      : const Result.success([_cairo]);
}

final class _NoGps implements LocationRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// A GPS fix that arrives only when the test completes [fix].
final class _SlowGps implements LocationRepository {
  final fix = Completer<Result<GpsLocation>>();

  @override
  Future<Result<GpsLocation>> getCurrentLocation({
    bool requestPermission = true,
  }) => fix.future;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<SettingsStore> _pump(
  WidgetTester tester, {
  required bool setup,
  LocationRepository? gps,
}) async {
  final store = await makeSettingsStore(
    AppSettings(
      setupComplete: setup,
      location: const ManualCityLocation(
        City(
          name: 'Dhaka',
          countryCode: 'BD',
          latitude: 23.71,
          longitude: 90.41,
          timezone: 'Asia/Dhaka',
        ),
      ),
    ),
  );
  GetIt.I
    ..registerSingleton<SettingsStore>(store)
    ..registerSingleton(SearchCities(_Cities()))
    ..registerSingleton(GetCurrentLocation(gps ?? _NoGps()));
  final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (_, _) => const Scaffold()),
      GoRoute(path: '/l', builder: (_, _) => const LocationPickerScreen()),
    ],
  );
  await tester.pumpWidget(
    MaterialApp.router(
      theme: AppTheme.light(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    ),
  );
  unawaited(router.push<void>('/l'));
  await tester.pumpAndSettle();
  return store;
}

void main() {
  tearDown(() {
    _citiesFail = false;
    return GetIt.I.reset();
  });

  testWidgets('marks the current city as selected', (tester) async {
    final store = await _pump(tester, setup: true);
    expect(find.byIcon(Icons.check), findsNothing);
    await store.setLocation(const ManualCityLocation(_cairo));
    await tester.pump();
    expect(find.byIcon(Icons.check), findsOneWidget);
  });

  testWidgets('a failed search offers a retry', (tester) async {
    _citiesFail = true;
    await _pump(tester, setup: true);
    expect(find.text('Cairo'), findsNothing);
    _citiesFail = false;
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(find.text('Cairo'), findsOneWidget);
  });

  testWidgets('moving country offers that region\'s method and madhab', (
    tester,
  ) async {
    final store = await _pump(tester, setup: true);
    await tester.tap(find.text('Cairo'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Use the suggested method for'), findsOne);
    await tester.tap(find.text('Use suggested'));
    await tester.pumpAndSettle();
    expect(store.prayerParams.value.method, CalculationMethodId.egyptian);
    expect(store.prayerParams.value.madhab, Madhab.shafi);
    expect(find.byType(LocationPickerScreen), findsNothing);
  });

  testWidgets('first setup does not ask (its own steps pre-select)', (
    tester,
  ) async {
    final store = await _pump(tester, setup: false);
    await tester.tap(find.text('Cairo'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Use the suggested method for'), findsNothing);
    expect(store.prayerParams.value.method, CalculationMethodId.karachi);
  });

  testWidgets('a GPS fix landing after a city pick is dropped', (
    tester,
  ) async {
    final gps = _SlowGps();
    final store = await _pump(tester, setup: true, gps: gps);
    await tester.tap(find.text('Use my location'));
    await tester.pump();
    // The pick saves Cairo and keeps the screen up behind the region dialog.
    await tester.tap(find.text('Cairo'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Use the suggested method for'), findsOne);
    gps.fix.complete(
      const Result.success(GpsLocation(latitude: 1, longitude: 2)),
    );
    await tester.pumpAndSettle();
    expect(store.location.value, const ManualCityLocation(_cairo));
    expect(find.byType(AlertDialog), findsOne);
  });
}
