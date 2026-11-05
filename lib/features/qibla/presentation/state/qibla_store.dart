import 'dart:async';
import 'dart:math' as math;

import 'package:signals_flutter/signals_flutter.dart';

import '../../../../core/settings/settings_store.dart';
import '../../domain/repositories/compass_sensor_source.dart';
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
    // Sensors only while a location exists (the needs-location state shows
    // no compass); subscribes as soon as one is set.
    _disposeLocationEffect = effect(() {
      final hasLocation = _settings.location.value != null;
      untracked(() {
        if (!hasLocation) {
          _release();
        } else if (!_hidden && _subscription == null) {
          _subscribe();
        }
      });
    });
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

  /// Phone held too far from flat for a trustworthy heading (see
  /// [CompassMath.maxTiltDeg]): the heading holds, nothing reads aligned.
  late final tooTilted = signal(false);

  /// Screen is in landscape, where the top-edge heading is 90° off (some
  /// devices ignore the portrait lock): nothing reads aligned.
  late final landscape = signal(false);

  /// Fires [sensorFailed] if the stream never emits (some devices just
  /// stay silent instead of erroring).
  final Duration firstEventTimeout;

  StreamSubscription<SensorVectors>? _subscription;
  Timer? _firstEvent;
  late final void Function() _disposeLocationEffect;
  bool _hidden = false;

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
  /// Never while calibrating or tilted: the heading can't be trusted then.
  late final aligned = signal(false);

  void _updateAligned() {
    final h = heading.value;
    final b = bearing.value;
    aligned.value =
        !needsCalibration.value &&
        !tooTilted.value &&
        !landscape.value &&
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
        tooTilted.value = CompassMath.isTooTilted(
          CompassMath.tiltDegrees(ax: v.ax, ay: v.ay, az: v.az),
          wasTilted: tooTilted.value,
        );
        if (magnitude < 1 || tooTilted.value) {
          // No field at all (iOS sends zeros below medium accuracy): atan2(0, 0)
          // would read as north. Tilted: roll is unstable. Either way keep
          // the last heading.
          _updateAligned();
          return;
        }
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
    _hidden = true;
    _release();
  }

  void resume() {
    _hidden = false;
    if (_subscription == null && _settings.location.value != null) {
      _subscribe();
    }
  }

  void _release() {
    _firstEvent?.cancel();
    unawaited(_subscription?.cancel());
    _subscription = null;
  }

  /// Re-subscribes from scratch after the sensor failed or timed out
  /// ([resume] alone keeps a stalled subscription).
  void retry() {
    _release();
    resume();
  }

  void dispose() {
    _disposeLocationEffect();
    pause();
  }
}
