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

final class _Cities implements CityRepository {
  @override
  Future<Result<List<City>>> search(String query, {int limit = 30}) async =>
      const Result.success([_cairo]);
}

final class _NoGps implements LocationRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<SettingsStore> _pump(WidgetTester tester, {required bool setup}) async {
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
    ..registerSingleton(GetCurrentLocation(_NoGps()));
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
  tearDown(GetIt.I.reset);

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
}
