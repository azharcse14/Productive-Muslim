import 'dart:async';
import 'dart:math' as math;

import 'package:signals_flutter/signals_flutter.dart';

import '../../../settings/presentation/state/settings_store.dart';
import '../../data/datasources/sensor_data_source.dart';
import '../../domain/usecases/compass_math.dart';

/// Compass status drives which design state renders (design §4.4).
enum QiblaStatus { needsLocation, ready, calibrating, sensorUnavailable }

/// Qibla screen state: smoothed magnetic heading from raw sensor vectors,
/// bearing/distance from the configured location, aligned within ±3°.
final class QiblaStore {
  QiblaStore({
    required CompassSensorSource sensors,
    required SettingsStore settings,
    this.onAligned,
  })  : _sensors = sensors,
        _settings = settings {
    _subscribe();
  }

  final CompassSensorSource _sensors;
  final SettingsStore _settings;

  /// Haptic hook, injected so the store stays testable.
  final void Function()? onAligned;

  late final heading = signal<double?>(null);
  late final sensorFailed = signal(false);

  /// Earth's magnetic field is ~25–65 µT; far outside ⇒ needs calibration.
  late final needsCalibration = signal(false);

  StreamSubscription<SensorVectors>? _subscription;
  var _wasAligned = false;

  late final bearing = computed<double?>(() {
    final location = _settings.location.value;
    if (location == null) {
      return null;
    }
    return CompassMath.qiblaBearing(location.latitude, location.longitude);
  });

  late final distanceKm = computed<double?>(() {
    final location = _settings.location.value;
    if (location == null) {
      return null;
    }
    return CompassMath.distanceToKaabaKm(
      location.latitude,
      location.longitude,
    );
  });

  late final status = computed<QiblaStatus>(() {
    if (_settings.location.value == null) {
      return QiblaStatus.needsLocation;
    }
    if (sensorFailed.value) {
      return QiblaStatus.sensorUnavailable;
    }
    if (needsCalibration.value) {
      return QiblaStatus.calibrating;
    }
    return QiblaStatus.ready;
  });

  late final aligned = computed(() {
    final h = heading.value;
    final b = bearing.value;
    if (h == null || b == null) {
      return false;
    }
    return CompassMath.isAligned(h, b);
  });

  void _subscribe() {
    _subscription = _sensors.vectors().listen(
      (v) {
        final magnitude = math.sqrt(v.mx * v.mx + v.my * v.my + v.mz * v.mz);
        needsCalibration.value = magnitude < 20 || magnitude > 80;
        final raw = CompassMath.tiltCompensatedHeading(
          ax: v.ax,
          ay: v.ay,
          az: v.az,
          mx: v.mx,
          my: v.my,
          mz: v.mz,
        );
        final previous = heading.value;
        heading.value = previous == null
            ? raw
            : CompassMath.smoothHeading(previous, raw);
        final isAligned = aligned.value;
        if (isAligned && !_wasAligned) {
          onAligned?.call();
        }
        _wasAligned = isAligned;
      },
      onError: (Object _) => sensorFailed.value = true,
    );
  }

  void dispose() {
    unawaited(_subscription?.cancel());
  }
}
