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

  test(
    'writes a fresh PNG per share, pruning only ones over an hour old',
    () async {
      final cache = Directory.systemTemp.createTempSync('share_test');
      addTearDown(() => cache.deleteSync(recursive: true));
      final calls = <MethodCall>[];
      messenger.setMockMethodCallHandler(channel, (call) async {
        calls.add(call);
        return null;
      });
      var now = DateTime.fromMillisecondsSinceEpoch(1000);
      final sheet = PlatformShareSheet(
        cacheDir: () async => cache,
        now: () => now,
      );
      final png = Uint8List.fromList([137, 80, 78, 71]);
      expect(await sheet.shareImage(png, 'hi'), isTrue);
      now = DateTime.fromMillisecondsSinceEpoch(2000);
      expect(await sheet.shareImage(png, 'again'), isTrue);
      final paths = [
        for (final c in calls) (c.arguments as Map<Object?, Object?>)['path'],
      ];
      expect(calls.map((c) => c.method), ['shareImage', 'shareImage']);
      expect(paths, [
        '${cache.path}/share/productive_muslim_1000.png',
        '${cache.path}/share/productive_muslim_2000.png',
      ]);
      List<String> files() =>
          [for (final f in Directory('${cache.path}/share').listSync()) f.path]
            ..sort();
      // A target app may still be reading the first one.
      expect(files(), paths);
      expect(File(paths.last! as String).readAsBytesSync(), png);
      expect((calls.last.arguments as Map<Object?, Object?>)['text'], 'again');

      now = DateTime.fromMillisecondsSinceEpoch(
        1500 + PlatformShareSheet.keepFor.inMilliseconds,
      );
      expect(await sheet.shareImage(png, 'later'), isTrue);
      expect(files(), [
        '${cache.path}/share/productive_muslim_2000.png',
        '${cache.path}/share/productive_muslim_${now.millisecondsSinceEpoch}'
            '.png',
      ]);
    },
  );

  test('a failing native side reports false', () async {
    final cache = Directory.systemTemp.createTempSync('share_test');
    addTearDown(() => cache.deleteSync(recursive: true));
    messenger.setMockMethodCallHandler(
      channel,
      (_) async => throw PlatformException(code: 'NO_UI'),
    );
    final sheet = PlatformShareSheet(cacheDir: () async => cache);
    expect(await sheet.shareImage(Uint8List(1), 'hi'), isFalse);
  });

  test('an unwritable cache shares nothing and reports false', () async {
    final calls = <MethodCall>[];
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return null;
    });
    final file = File('${Directory.systemTemp.path}/share_not_a_dir')
      ..writeAsStringSync('x');
    addTearDown(file.deleteSync);
    final shown = await PlatformShareSheet(
      cacheDir: () async => Directory(file.path),
    ).shareImage(Uint8List(1), 'hi');
    expect(shown, isFalse);
    expect(calls, isEmpty);
  });
}
