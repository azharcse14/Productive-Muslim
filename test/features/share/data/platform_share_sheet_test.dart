import 'dart:io';

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
  test('writes the PNG to the cache share folder and sends its path', () async {
    final cache = Directory.systemTemp.createTempSync('share_test');
    addTearDown(() => cache.deleteSync(recursive: true));
    final calls = <MethodCall>[];
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return null;
    });
    final png = Uint8List.fromList([137, 80, 78, 71]);
    await PlatformShareSheet(cacheDir: () async => cache).shareImage(png, 'hi');
    expect(calls.single.method, 'shareImage');
    final args = calls.single.arguments as Map<Object?, Object?>;
    final path = args['path']! as String;
    expect(path, '${cache.path}/share/productive_muslim_share.png');
    expect(File(path).readAsBytesSync(), png);
    expect(args['text'], 'hi');
  });

  test('an unwritable cache shares nothing and is not an error', () async {
    final calls = <MethodCall>[];
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return null;
    });
    final file = File('${Directory.systemTemp.path}/share_not_a_dir')
      ..writeAsStringSync('x');
    addTearDown(file.deleteSync);
    await PlatformShareSheet(
      cacheDir: () async => Directory(file.path),
    ).shareImage(Uint8List(1), 'hi');
    expect(calls, isEmpty);
  });
}
