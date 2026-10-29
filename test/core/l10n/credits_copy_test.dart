import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Bundled content must be credited in-app: Tanzil's terms ask for the
/// source name and a link to tanzil.net, and the upstream hadithbangla repo
/// carries no license, so the app must not call it open source.
void main() {
  const files = [
    'lib/core/l10n/arb/app_en.arb',
    'lib/core/l10n/arb/app_bn.arb',
  ];

  for (final path in files) {
    test('$path links to tanzil.net', () {
      expect(File(path).readAsStringSync(), contains('tanzil.net'));
    });

    test('$path never calls hadithbangla open source', () {
      final arb =
          jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;
      final offenders = [
        for (final MapEntry(:key, :value) in arb.entries)
          if (value is String &&
              value.contains('hadithbangla') &&
              RegExp(
                'open source|ওপেন সোর্স',
                caseSensitive: false,
              ).hasMatch(value))
            key,
      ];
      expect(offenders, isEmpty);
    });
  }

  test('English credits name every bundled source', () {
    final arb =
        jsonDecode(File(files.first).readAsStringSync())
            as Map<String, dynamic>;
    final credits = '${arb['creditsQuranText']} ${arb['creditsBody']}';
    for (final name in [
      'Tanzil',
      'Pickthall',
      'Muhiuddin Khan',
      'fawazahmed0/hadith-api',
      'hadithbangla',
      'Hisnul Muslim',
      'GeoNames',
    ]) {
      expect(credits, contains(name));
    }
  });
}
