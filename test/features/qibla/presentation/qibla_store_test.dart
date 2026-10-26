import 'dart:async';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:productive_muslim/core/utils/result.dart';
import 'package:productive_muslim/features/qibla/data/datasources/sensor_data_source.dart';
import 'package:productive_muslim/features/qibla/domain/usecases/magnetic_declination.dart';
import 'package:productive_muslim/features/qibla/presentation/state/qibla_store.dart';
import 'package:productive_muslim/features/settings/domain/entities/app_settings.dart';
import 'package:productive_muslim/features/settings/domain/entities/city.dart';
import 'package:productive_muslim/features/settings/domain/entities/location_config.dart';
import 'package:productive_muslim/features/settings/domain/repositories/settings_repository.dart';
import 'package:productive_muslim/features/settings/domain/usecases/get_settings.dart';
import 'package:productive_muslim/features/settings/domain/usecases/save_settings.dart';
import 'package:productive_muslim/features/settings/presentation/state/settings_store.dart';

final class _FakeSensors implements CompassSensorSource {
  final controller = StreamController<SensorVectors>.broadcast();

  @override
  Stream<SensorVectors> vectors() => controller.stream;

  /// Device flat, field strength realistic (~46 µT), pointing [deg]
  /// clockwise from magnetic north.
  void emitHeading(double deg) {
    // For a flat device the tilt-compensated heading reduces to the
    // horizontal magnetometer components; emit a vector whose horizontal
    // projection points `deg` away from the device's top edge.
    final rad = deg * math.pi / 180;
    controller.add(
      (
        ax: 0,
        ay: 0,
        az: 9.81,
        mx: -30 * math.sin(rad),
        my: 30 * math.cos(rad),
        mz: -35,
      ),
    );
  }

  void emitWeakField() =>
      controller.add((ax: 0, ay: 0, az: 9.81, mx: 1, my: 2, mz: 1));

  void emitError() => controller.addError(StateError('no sensor'));
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

Future<(QiblaStore, _FakeSensors, List<int>)> _make({
  bool withLocation = true,
}) async {
  final repo = _InMemoryRepo(
    AppSettings(location: withLocation ? _dhaka : null),
  );
  final settings = SettingsStore(GetSettings(repo), SaveSettings(repo));
  await settings.load();
  final sensors = _FakeSensors();
  final haptics = <int>[];
  final store = QiblaStore(
    sensors: sensors,
    settings: settings,
    onAligned: () => haptics.add(1),
    now: () => DateTime.utc(2026, 7, 2, 12),
  );
  return (store, sensors, haptics);
}

void main() {
  group('QiblaStore', () {
    test('needsLocation when no location is configured', () async {
      final (store, _, _) = await _make(withLocation: false);
      expect(store.status.value, QiblaStatus.needsLocation);
      expect(store.bearing.value, isNull);
      store.dispose();
    });

    test('bearing and distance derive from the location', () async {
      final (store, _, _) = await _make();
      expect(store.bearing.value, closeTo(278, 1.5));
      expect(store.distanceKm.value, closeTo(5173, 100));
      store.dispose();
    });

    test('sensor stream drives a smoothed heading', () async {
      final (store, sensors, _) = await _make();
      sensors.emitHeading(10);
      await Future<void>.delayed(Duration.zero);
      expect(store.heading.value, isNotNull);
      expect(store.status.value, QiblaStatus.ready);
      store.dispose();
    });

    test('heading is corrected from magnetic to true north', () async {
      final (store, sensors, _) = await _make();
      expect(
        store.declination.value,
        MagneticDeclination.at(
          _dhaka.latitude,
          _dhaka.longitude,
          DateTime.utc(2026, 7, 2, 12),
        ),
      );
      expect(store.declination.value, isNot(0));
      sensors.emitHeading(10);
      await Future<void>.delayed(Duration.zero);
      expect(store.heading.value, closeTo(10 + store.declination.value, 1e-9));
      store.dispose();
    });

    test('weak magnetic field flags calibration', () async {
      final (store, sensors, _) = await _make();
      sensors.emitWeakField();
      await Future<void>.delayed(Duration.zero);
      expect(store.status.value, QiblaStatus.calibrating);
      store.dispose();
    });

    test('stream error flips to sensorUnavailable but keeps the bearing',
        () async {
      final (store, sensors, _) = await _make();
      sensors.emitError();
      await Future<void>.delayed(Duration.zero);
      expect(store.status.value, QiblaStatus.sensorUnavailable);
      expect(store.bearing.value, isNotNull); // verbal fallback possible
      store.dispose();
    });

    test('haptic fires once on entering alignment', () async {
      final (store, sensors, haptics) = await _make();
      // The sensor reads magnetic north; the store adds the declination.
      final bearing = store.bearing.value! - store.declination.value;
      // Repeat so exponential smoothing converges within tolerance.
      for (var i = 0; i < 60; i++) {
        sensors.emitHeading(bearing);
        await Future<void>.delayed(Duration.zero);
      }
      expect(store.aligned.value, isTrue);
      expect(haptics.length, 1, reason: 'edge-triggered, not per sample');
      store.dispose();
    });
  });
}
