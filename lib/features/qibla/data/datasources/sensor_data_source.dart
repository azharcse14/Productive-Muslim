import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../../domain/repositories/compass_sensor_source.dart';

final class SensorsPlusSource implements CompassSensorSource {
  /// The source streams are injectable for tests; defaults read the device.
  const SensorsPlusSource({
    this.accelerometer = _deviceAccelerometer,
    this.magnetometer = _deviceMagnetometer,
  });

  final Stream<AccelerometerEvent> Function() accelerometer;
  final Stream<MagnetometerEvent> Function() magnetometer;

  static const _interval = SensorInterval.uiInterval;

  /// Pairs each magnetometer reading with the latest accelerometer one; the
  /// magnetometer drives emission cadence. The first error from either
  /// sensor is forwarded and ends the stream.
  ///
  /// A plain controller rather than `async*`: cancelling an `async*` stream
  /// only takes effect at its next `yield`, so a silent magnetometer kept
  /// the accelerometer listening forever.
  @override
  Stream<SensorVectors> vectors() {
    late final StreamController<SensorVectors> controller;
    StreamSubscription<AccelerometerEvent>? accelSub;
    StreamSubscription<MagnetometerEvent>? magSub;
    AccelerometerEvent? lastAccel;
    var active = 2;

    Future<void> cancelSources() async {
      await accelSub?.cancel();
      await magSub?.cancel();
    }

    void onDone() {
      if (--active == 0) {
        unawaited(controller.close());
      }
    }

    void onError(Object error, StackTrace stack) {
      controller.addError(error, stack);
      unawaited(cancelSources());
      unawaited(controller.close());
    }

    controller = StreamController<SensorVectors>(
      onListen: () {
        accelSub = accelerometer().listen(
          (accel) => lastAccel = accel,
          onError: onError,
          onDone: onDone,
        );
        magSub = magnetometer().listen(
          (mag) {
            final accel = lastAccel;
            if (accel != null) {
              controller.add((
                ax: accel.x,
                ay: accel.y,
                az: accel.z,
                mx: mag.x,
                my: mag.y,
                mz: mag.z,
              ));
            }
          },
          onError: onError,
          onDone: onDone,
        );
      },
      onPause: () {
        accelSub?.pause();
        magSub?.pause();
      },
      onResume: () {
        accelSub?.resume();
        magSub?.resume();
      },
      onCancel: cancelSources,
    );
    return controller.stream;
  }

  static Stream<AccelerometerEvent> _deviceAccelerometer() =>
      accelerometerEventStream(samplingPeriod: _interval);

  /// iOS: the bias-corrected field from Core Motion (AppDelegate), not the
  /// raw magnetometer sensors_plus reads there.
  static Stream<MagnetometerEvent> _deviceMagnetometer() =>
      defaultTargetPlatform == TargetPlatform.iOS
      ? const EventChannel(
          'com.productivemuslim.app/magnetic',
        ).receiveBroadcastStream().map((event) {
          final v = (event as List).cast<num>();
          return MagnetometerEvent(
            v[0].toDouble(),
            v[1].toDouble(),
            v[2].toDouble(),
            DateTime.now(),
          );
        })
      : magnetometerEventStream(samplingPeriod: _interval);
}
