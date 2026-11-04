import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:productive_muslim/features/qibla/data/datasources/sensor_data_source.dart';
import 'package:productive_muslim/features/qibla/domain/repositories/compass_sensor_source.dart';
import 'package:sensors_plus/sensors_plus.dart';

void main() {
  late StreamController<AccelerometerEvent> accel;
  late StreamController<MagnetometerEvent> mag;
  late SensorsPlusSource source;
  final t = DateTime(2026);

  setUp(() {
    accel = StreamController<AccelerometerEvent>();
    mag = StreamController<MagnetometerEvent>();
    source = SensorsPlusSource(
      accelerometer: () => accel.stream,
      magnetometer: () => mag.stream,
    );
  });

  tearDown(() {
    // Not awaited: a never-listened controller's close() never completes.
    unawaited(accel.close());
    unawaited(mag.close());
  });

  test('pairs each magnetometer event with the latest accelerometer', () async {
    final out = <SensorVectors>[];
    final sub = source.vectors().listen(out.add);
    mag.add(MagnetometerEvent(9, 9, 9, t)); // no accel yet: dropped
    accel.add(AccelerometerEvent(1, 2, 3, t));
    await pumpEventQueue();
    mag.add(MagnetometerEvent(4, 5, 6, t));
    await pumpEventQueue();
    expect(out, [(ax: 1.0, ay: 2.0, az: 3.0, mx: 4.0, my: 5.0, mz: 6.0)]);
    await sub.cancel();
  });

  test(
    'cancel stops both sensors even if the magnetometer never emits',
    () async {
      final sub = source.vectors().listen((_) {});
      accel.add(AccelerometerEvent(1, 2, 3, t));
      await pumpEventQueue();
      expect(accel.hasListener, isTrue);
      expect(mag.hasListener, isTrue);

      await sub.cancel();
      expect(accel.hasListener, isFalse);
      expect(mag.hasListener, isFalse);
    },
  );

  test('a sensor error is forwarded, ends the stream, stops both', () async {
    final errors = <Object>[];
    final done = Completer<void>();
    source.vectors().listen((_) {}, onError: errors.add, onDone: done.complete);
    mag.addError(StateError('no sensor'));
    await done.future;
    expect(errors.single, isA<StateError>());
    expect(accel.hasListener, isFalse);
    expect(mag.hasListener, isFalse);
  });
}
