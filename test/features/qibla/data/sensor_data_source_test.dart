import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:productive_muslim/features/qibla/data/datasources/sensor_data_source.dart';
import 'package:productive_muslim/features/qibla/domain/repositories/compass_sensor_source.dart';
import 'package:sensors_plus/sensors_plus.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
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

  test('iOS: "no device motion" from the native channel ends the stream '
      'with an error, not a silent wait', () async {
    // Mirrors AppDelegate's CalibratedMagnetometer: the error goes through
    // the event sink (an onListen return value never reaches Dart).
    const channel = EventChannel('com.productivemuslim.app/magnetic');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockStreamHandler(
      channel,
      MockStreamHandler.inline(
        onListen: (_, sink) =>
            sink.error(code: 'UNAVAILABLE', message: 'No device motion'),
      ),
    );
    addTearDown(() => messenger.setMockStreamHandler(channel, null));
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);

    final errors = <Object>[];
    final done = Completer<void>();
    SensorsPlusSource(
      accelerometer: () => accel.stream,
    ).vectors().listen((_) {}, onError: errors.add, onDone: done.complete);
    await done.future;
    expect(
      errors.single,
      isA<PlatformException>().having((e) => e.code, 'code', 'UNAVAILABLE'),
    );
    expect(accel.hasListener, isFalse);
  });
}
