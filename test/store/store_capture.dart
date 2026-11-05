import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:productive_muslim/core/l10n/gen/app_localizations.dart';
import 'package:productive_muslim/core/theme/app_theme.dart';

/// Loads every font in the test bundle's FontManifest (app fonts +
/// MaterialIcons) so captures show real glyphs, not Ahem boxes.
Future<void> loadAppFonts() async {
  final manifest =
      jsonDecode(await rootBundle.loadString('FontManifest.json'))
          as List<Object?>;
  for (final entry in manifest.cast<Map<String, Object?>>()) {
    final loader = FontLoader(entry['family']! as String);
    for (final font
        in (entry['fonts']! as List<Object?>).cast<Map<String, Object?>>()) {
      loader.addFont(rootBundle.load(font['asset']! as String));
    }
    await loader.load();
  }
}

/// Key of the [RepaintBoundary] the store harness wraps around the app.
final captureKey = GlobalKey();

/// The app's MaterialApp (theme, l10n) around [home], inside [captureKey].
Widget storeApp(Widget home, {String locale = 'en', bool dark = false}) =>
    RepaintBoundary(
      key: captureKey,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: dark ? AppTheme.dark() : AppTheme.light(),
        locale: Locale(locale),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: home,
      ),
    );

/// [testWidgets] with real shadows (the test default paints none).
void storeShot(String description, WidgetTesterCallback body) =>
    testWidgets(description, (tester) async {
      debugDisableShadows = false;
      try {
        await body(tester);
      } finally {
        debugDisableShadows = true;
      }
    });

/// Sets the test view to [physical] pixels at [dpr].
void setView(WidgetTester tester, Size physical, double dpr) {
  tester.view
    ..physicalSize = physical
    ..devicePixelRatio = dpr;
  addTearDown(tester.view.reset);
}

/// Captures the [captureKey] boundary and writes it to [path] as an
/// opaque RGB PNG (stores reject alpha channels).
Future<void> writeCapture(WidgetTester tester, String path) async {
  await tester.runAsync(() async {
    final boundary =
        captureKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(
      pixelRatio: tester.view.devicePixelRatio,
    );
    // Default format: raw RGBA.
    final rgba = (await image.toByteData())!.buffer.asUint8List();
    final file = File(path)..parent.createSync(recursive: true);
    file.writeAsBytesSync(encodeRgbPng(rgba, image.width, image.height));
    image.dispose();
  });
}

/// Minimal PNG encoder: 8-bit RGB, filter 0, alpha dropped.
Uint8List encodeRgbPng(Uint8List rgba, int width, int height) {
  final raw = BytesBuilder(copy: false);
  for (var y = 0; y < height; y++) {
    final row = Uint8List(1 + width * 3);
    for (var x = 0; x < width; x++) {
      final s = (y * width + x) * 4;
      row.setRange(1 + x * 3, 4 + x * 3, rgba, s);
    }
    raw.add(row);
  }
  final header = ByteData(13)
    ..setUint32(0, width)
    ..setUint32(4, height)
    ..setUint8(8, 8) // bit depth
    ..setUint8(9, 2); // colour type: truecolour
  final out = BytesBuilder(copy: false)
    ..add(const [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]);
  void chunk(String type, List<int> data) {
    final body = [...ascii.encode(type), ...data];
    out
      ..add((ByteData(4)..setUint32(0, data.length)).buffer.asUint8List())
      ..add(body)
      ..add((ByteData(4)..setUint32(0, _crc32(body))).buffer.asUint8List());
  }

  chunk('IHDR', header.buffer.asUint8List());
  chunk('IDAT', ZLibCodec(level: 9).encode(raw.takeBytes()));
  chunk('IEND', const []);
  return out.takeBytes();
}

final _crcTable = List<int>.generate(256, (n) {
  var c = n;
  for (var k = 0; k < 8; k++) {
    c = (c & 1) != 0 ? 0xEDB88320 ^ (c >> 1) : c >> 1;
  }
  return c;
});

int _crc32(List<int> bytes) {
  var c = 0xFFFFFFFF;
  for (final b in bytes) {
    c = _crcTable[(c ^ b) & 0xFF] ^ (c >> 8);
  }
  return c ^ 0xFFFFFFFF;
}
