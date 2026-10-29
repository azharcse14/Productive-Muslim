import 'dart:async';
import 'dart:math' as math;

import 'package:signals_flutter/signals_flutter.dart';

import '../../../settings/presentation/state/settings_store.dart';
import '../../data/datasources/sensor_data_source.dart';
import '../../domain/usecases/compass_math.dart';
import '../../domain/usecases/magnetic_declination.dart';

/// Compass status drives which design state renders (design §4.4).
enum QiblaStatus { needsLocation, ready, calibrating, sensorUnavailable }

/// Qibla screen state: smoothed true heading (magnetometer heading plus the
/// WMM declination at the configured location) from raw sensor vectors,
/// bearing/distance from the configured location, aligned within ±3°.
final class QiblaStore {
  QiblaStore({
    required CompassSensorSource sensors,
    required SettingsStore settings,
    this.onAligned,
    this.firstEventTimeout = const Duration(seconds: 3),
    DateTime Function()? now,
  }) : _sensors = sensors,
       _settings = settings,
       _now = now ?? DateTime.now {
    _subscribe();
  }

  final CompassSensorSource _sensors;
  final SettingsStore _settings;
  final DateTime Function() _now;

  /// Haptic hook, injected so the store stays testable.
  final void Function()? onAligned;

  late final heading = signal<double?>(null);
  late final sensorFailed = signal(false);

  /// Earth's magnetic field is ~25–65 µT; far outside ⇒ needs calibration.
  /// Hysteresis: flagged outside 20–80 µT, cleared only back inside
  /// 25–75 µT, so a reading hovering at a limit doesn't flicker the banner.
  late final needsCalibration = signal(false);

  /// Fires [sensorFailed] if the stream never emits (some devices just
  /// stay silent instead of erroring).
  final Duration firstEventTimeout;

  StreamSubscription<SensorVectors>? _subscription;
  Timer? _firstEvent;

  late final bearing = computed<double?>(() {
    final location = _settings.location.value;
    if (location == null) {
      return null;
    }
    return CompassMath.qiblaBearing(location.latitude, location.longitude);
  });

  /// Magnetic → true north correction at the configured location (0 when
  /// none — the needs-location state shows no compass anyway).
  late final declination = computed<double>(() {
    final location = _settings.location.value;
    if (location == null) {
      return 0;
    }
    return MagneticDeclination.at(
      location.latitude,
      location.longitude,
      _now(),
    );
  });

  late final distanceKm = computed<double?>(() {
    final location = _settings.location.value;
    if (location == null) {
      return null;
    }
    return CompassMath.distanceToKaabaKm(location.latitude, location.longitude);
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

  /// Aligned within ±3°, and stays so until beyond ±5° (hysteresis), so
  /// sensor jitter at the edge doesn't re-fire the haptic / live region.
  /// Never while calibrating: the heading can't be trusted then.
  late final aligned = signal(false);

  void _updateAligned() {
    final h = heading.value;
    final b = bearing.value;
    aligned.value =
        !needsCalibration.value &&
        h != null &&
        b != null &&
        CompassMath.isAligned(h, b, toleranceDeg: aligned.value ? 5 : 3);
  }

  void _subscribe() {
    sensorFailed.value = false;
    _firstEvent?.cancel();
    _firstEvent = Timer(firstEventTimeout, () => sensorFailed.value = true);
    _subscription = _sensors.vectors().listen(
      (v) {
        _firstEvent?.cancel();
        sensorFailed.value = false;
        final magnitude = math.sqrt(v.mx * v.mx + v.my * v.my + v.mz * v.mz);
        needsCalibration.value = needsCalibration.value
            ? magnitude < 25 || magnitude > 75
            : magnitude < 20 || magnitude > 80;
        final magnetic = CompassMath.tiltCompensatedHeading(
          ax: v.ax,
          ay: v.ay,
          az: v.az,
          mx: v.mx,
          my: v.my,
          mz: v.mz,
        );
        // qiblaBearing is relative to true north, so the heading must be too.
        final raw = (magnetic + declination.value) % 360;
        final previous = heading.value;
        heading.value = previous == null
            ? raw
            : CompassMath.smoothHeading(previous, raw);
        final wasAligned = aligned.value;
        _updateAligned();
        if (aligned.value && !wasAligned) {
          onAligned?.call();
        }
      },
      onError: (Object _) {
        _firstEvent?.cancel();
        sensorFailed.value = true;
      },
    );
  }

  /// Releases the sensors while the app is hidden (Android keeps them
  /// streaming in the background otherwise).
  void pause() {
    _firstEvent?.cancel();
    unawaited(_subscription?.cancel());
    _subscription = null;
  }

  void resume() {
    if (_subscription == null) {
      _subscribe();
    }
  }

  void dispose() => pause();
}
