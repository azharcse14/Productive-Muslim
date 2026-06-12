import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:qalbee/core/l10n/gen/app_localizations.dart';
import 'package:qalbee/core/theme/app_theme.dart';
import 'package:qalbee/core/utils/result.dart';
import 'package:qalbee/features/qibla/data/datasources/sensor_data_source.dart';
import 'package:qalbee/features/qibla/presentation/screens/qibla_screen.dart';
import 'package:qalbee/features/qibla/presentation/state/qibla_store.dart';
import 'package:qalbee/features/qibla/presentation/widgets/compass_dial.dart';
import 'package:qalbee/features/settings/domain/entities/app_settings.dart';
import 'package:qalbee/features/settings/domain/entities/city.dart';
import 'package:qalbee/features/settings/domain/entities/location_config.dart';
import 'package:qalbee/features/settings/domain/repositories/settings_repository.dart';
import 'package:qalbee/features/settings/domain/usecases/get_settings.dart';
import 'package:qalbee/features/settings/domain/usecases/save_settings.dart';
import 'package:qalbee/features/settings/presentation/state/settings_store.dart';

final class _NeverSensors implements CompassSensorSource {
  @override
  Stream<SensorVectors> vectors() => const Stream.empty();
}

final class _ErrorSensors implements CompassSensorSource {
  @override
  Stream<SensorVectors> vectors() =>
      Stream.error(StateError('no sensor'));
}

final class _InMemoryRepo implements SettingsRepository {
  _InMemoryRepo(this.stored);

  AppSettings stored;

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

Future<void> _register({
  required bool withLocation,
  CompassSensorSource? sensors,
}) async {
  final repo = _InMemoryRepo(
    AppSettings(location: withLocation ? _dhaka : null),
  );
  final settings = SettingsStore(GetSettings(repo), SaveSettings(repo));
  await settings.load();
  GetIt.I
    ..registerSingleton<SettingsStore>(settings)
    ..registerFactory<QiblaStore>(
      () => QiblaStore(
        sensors: sensors ?? _NeverSensors(),
        settings: settings,
      ),
    );
}

Widget _app() => MaterialApp(
      theme: AppTheme.light(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const QiblaScreen(),
    );

void main() {
  tearDown(() => GetIt.I.reset());

  group('QiblaScreen', () {
    testWidgets('location-needed state shows CTA', (tester) async {
      await _register(withLocation: false);
      await tester.pumpWidget(_app());
      expect(
        find.text('Set your location to find the qibla direction'),
        findsOneWidget,
      );
      expect(find.text('Set location'), findsOneWidget);
    });

    testWidgets('ready state renders the dial and distance detail',
        (tester) async {
      await _register(withLocation: true);
      await tester.pumpWidget(_app());
      await tester.pump();
      expect(find.byType(CompassDial), findsOneWidget);
      expect(find.textContaining('km to the Kaaba'), findsOneWidget);
    });

    testWidgets('sensor failure falls back to the verbal bearing',
        (tester) async {
      await _register(withLocation: true, sensors: _ErrorSensors());
      await tester.pumpWidget(_app());
      await tester.pump();
      expect(
        find.text('Compass sensor unavailable on this device'),
        findsOneWidget,
      );
      // Verbal fallback mentions the bearing degrees from north.
      expect(find.textContaining('from north'), findsOneWidget);
      expect(find.byType(CompassDial), findsNothing);
    });
  });
}
