import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../../domain/repositories/compass_sensor_source.dart';

final class SensorsPlusSource implements CompassSensorSource {
  const SensorsPlusSource();

  static const _interval = SensorInterval.uiInterval;

  @override
  Stream<SensorVectors> vectors() async* {
    AccelerometerEvent? lastAccel;
    await for (final event in _merged()) {
      switch (event) {
        case final AccelerometerEvent accel:
          lastAccel = accel;
        case final MagnetometerEvent mag:
          final accel = lastAccel;
          if (accel != null) {
            yield (
              ax: accel.x,
              ay: accel.y,
              az: accel.z,
              mx: mag.x,
              my: mag.y,
              mz: mag.z,
            );
          }
      }
    }
  }

  Stream<Object> _merged() async* {
    // Interleave both streams; magnetometer drives emission cadence.
    yield* StreamGroupLite.merge([
      accelerometerEventStream(samplingPeriod: _interval),
      _magnetometer(),
    ]);
  }

  /// iOS: the bias-corrected field from Core Motion (AppDelegate), not the
  /// raw magnetometer sensors_plus reads there.
  Stream<MagnetometerEvent> _magnetometer() =>
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

/// Minimal stream merge (avoids an `async` package dependency for one
/// call site).
abstract final class StreamGroupLite {
  static Stream<T> merge<T>(List<Stream<T>> streams) {
    late final StreamController<T> controller;
    final subscriptions = <StreamSubscription<T>>[];
    var active = 0;
    controller = StreamController<T>(
      onListen: () {
        active = streams.length;
        for (final stream in streams) {
          subscriptions.add(
            stream.listen(
              controller.add,
              onError: controller.addError,
              onDone: () {
                active--;
                if (active == 0) {
                  unawaited(controller.close());
                }
              },
            ),
          );
        }
      },
      onCancel: () async {
        await Future.wait(subscriptions.map((sub) => sub.cancel()));
      },
    );
    return controller.stream;
  }
}
