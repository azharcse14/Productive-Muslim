import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:productive_muslim/features/keep_awake/data/platform_screen_wake.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('com.productivemuslim.app/screen');
  final calls = <Object?>[];

  setUp(() {
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          expect(call.method, 'keepOn');
          calls.add(call.arguments);
          return null;
        });
  });

  tearDown(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null),
  );

  test('the flag follows the outermost hold', () async {
    final wake = PlatformScreenWake();

    await wake.hold(on: true);
    // A replacing screen opens before the old one disposes.
    await wake.hold(on: true);
    await wake.hold(on: false);
    expect(calls, [true]);

    await wake.hold(on: false);
    expect(calls, [true, false]);

    // An unmatched release never goes negative or re-sends.
    await wake.hold(on: false);
    await wake.hold(on: true);
    expect(calls, [true, false, true]);
  });

  test('a missing native side is not an error', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    await PlatformScreenWake().hold(on: true);
  });
}
