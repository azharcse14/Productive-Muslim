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
    // Source names are proper nouns written in the credits screen itself.
    final credits =
        '${arb['creditsQuranText']} '
        '${File('lib/features/settings/presentation/screens/credits_screen.dart').readAsStringSync()}';
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

  test(
    'credits claim no license for Pickthall and no hardcoded qualifiers',
    () {
      final screen = File(
        'lib/features/settings/presentation/screens/credits_screen.dart',
      ).readAsStringSync();
      expect(screen, isNot(contains('public domain')));
      expect(screen, isNot(contains('(Unlicense)')));
    },
  );

  test('both ARBs credit the bundled Asmaul Husna and Tibb an-Nabawi', () {
    for (final path in files) {
      final arb =
          jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;
      for (final key in [
        'creditsAsmaulHusnaSource',
        'creditsTibbNabawiSource',
        'creditsBnHadithNawawiMalik',
        'creditsUnlicense',
      ]) {
        expect(arb[key], isA<String>(), reason: '$path $key');
      }
    }
  });
}
