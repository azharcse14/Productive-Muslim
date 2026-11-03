import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:productive_muslim/features/share/data/platform_share_sheet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('com.productivemuslim.app/share');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  test('sends the text to the native share sheet', () async {
    final calls = <MethodCall>[];
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return null;
    });
    await PlatformShareSheet().shareText('hello');
    expect(calls.single.method, 'shareText');
    expect(calls.single.arguments, 'hello');
  });

  test('a missing or failing native side is not an error', () async {
    await PlatformShareSheet().shareText('hello');
    messenger.setMockMethodCallHandler(
      channel,
      (_) async => throw PlatformException(code: 'NO_UI'),
    );
    await PlatformShareSheet().shareText('hello');
  });
}
