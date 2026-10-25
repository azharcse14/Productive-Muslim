import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Nearby Mosques opens Maps with the user's coordinates and full hadith
/// books download from a CDN, so user-facing copy must not promise that
/// nothing ever leaves the device.
void main() {
  const files = [
    'lib/core/l10n/arb/app_en.arb',
    'lib/core/l10n/arb/app_bn.arb',
    'ios/Runner/Info.plist',
  ];
  final banned = RegExp(
    'never leaves|nothing ever leaves|nothing leaves|no network|'
    'never sent|ফোনের বাইরে যায় না|কখনো ফোনের বাইরে',
    caseSensitive: false,
  );

  for (final path in files) {
    test('$path makes no absolute "nothing leaves the device" claim', () {
      final text = File(path).readAsStringSync();
      expect(banned.allMatches(text).map((m) => m[0]), isEmpty);
    });
  }

  test('location permission copy discloses the Maps hand-off', () {
    final plist = File('ios/Runner/Info.plist').readAsStringSync();
    final usage = RegExp(
      '<key>NSLocationWhenInUseUsageDescription</key>\\s*<string>([^<]*)',
    ).firstMatch(plist)![1]!;
    expect(usage, contains('Maps'));
    final en = File('lib/core/l10n/arb/app_en.arb').readAsStringSync();
    expect(
      RegExp('"locationPrimingBody": "[^"]*Maps').hasMatch(en),
      isTrue,
    );
  });
}
