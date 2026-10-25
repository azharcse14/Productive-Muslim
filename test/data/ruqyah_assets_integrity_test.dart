import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../helpers/honorific.dart';

/// Integrity checks for the bundled ruqyah collection. Reads the JSON file
/// directly from disk (flutter test runs with the project root as the
/// working directory).
void main() {
  const allowedIcons = <String>{
    'shield',
    'star',
    'healing',
    'eye',
    'protect',
    'heart',
    'hands',
    'moon',
    'sun',
    'spark',
    'walk',
    'people',
    'beads',
    'book',
    'globe',
    'library',
    'food',
    'mosque',
    'water',
  };
  const allowedRepeats = <int>{1, 3, 7, 100};
  const requiredStrings = <String>['id', 'ar', 'tr', 'en'];

  group('ruqyah.json', () {
    late List<Map<String, Object?>> categories;
    late List<Map<String, Object?>> allItems;

    setUpAll(() {
      final raw = File('assets/data/ruqyah.json').readAsStringSync();
      final decoded =
          (jsonDecode(raw) as Map<dynamic, dynamic>).cast<String, Object?>();
      categories = (decoded['categories']! as List<Object?>)
          .map((Object? e) =>
              (e as Map<dynamic, dynamic>).cast<String, Object?>())
          .toList();
      allItems = categories
          .expand(
            (Map<String, Object?> c) => (c['items']! as List<Object?>).map(
              (Object? e) =>
                  (e as Map<dynamic, dynamic>).cast<String, Object?>(),
            ),
          )
          .toList();
    });

    test('has the 25 expected categories', () {
      expect(
        categories.map((Map<String, Object?> c) => c['id']),
        containsAll(<String>[
          'protection',
          'three_quls',
          'healing',
          'evil_eye',
          'sihr_jinn',
          'anxiety_grief',
          'distress',
          'fever_pain',
          'sleep',
          'morning_evening',
          'waswas',
          'enemies',
          'travel',
          'children',
          'provision',
          'forgiveness',
          'guidance',
          'knowledge',
          'parents',
          'marriage',
          'fitan',
          'food_drink',
          'mosque',
          'rain',
          'night_worship',
        ]),
      );
    });

    test('has at least 60 ruqyah passages in total', () {
      expect(allItems.length, greaterThanOrEqualTo(60));
    });

    test('every category has a non-empty id and an allowed icon', () {
      for (final category in categories) {
        final id = category['id'];
        expect(id, isA<String>());
        expect((id! as String).trim(), isNotEmpty);
        expect(
          category['icon'],
          isIn(allowedIcons),
          reason: 'category "$id" must use an allowed icon',
        );
      }
    });

    test('every item has non-empty id, ar, tr and en fields', () {
      for (final item in allItems) {
        for (final field in requiredStrings) {
          final value = item[field];
          expect(
            value,
            isA<String>(),
            reason: 'item "${item['id']}" field "$field" must be a string',
          );
          expect(
            (value! as String).trim(),
            isNotEmpty,
            reason: 'item "${item['id']}" field "$field" must not be empty',
          );
        }
      }
    });

    test('repeat (when present) is one of 1, 3, 7, 100', () {
      for (final item in allItems) {
        final repeat = item['repeat'];
        if (repeat != null) {
          expect(
            repeat,
            isIn(allowedRepeats),
            reason: 'item "${item['id']}" has an invalid repeat value',
          );
        }
      }
    });

    test('item ids are unique across the whole collection', () {
      final ids = allItems.map((Map<String, Object?> i) => i['id']).toList();
      expect(ids.toSet(), hasLength(ids.length),
          reason: 'duplicate ruqyah ids found');
    });

    test('the three Quls category holds Ikhlas, Falaq and Nas', () {
      final quls = categories
          .firstWhere((Map<String, Object?> c) => c['id'] == 'three_quls');
      final ids = (quls['items']! as List<Object?>)
          .map((Object? e) =>
              (e as Map<dynamic, dynamic>).cast<String, Object?>()['id'])
          .toList();
      expect(ids, containsAll(<String>['ikhlas', 'falaq', 'nas']));
    });
  });

  test('ﷺ in ruqyah.json only follows the Prophet / Messenger / Muhammad', () {
    final decoded =
        jsonDecode(File('assets/data/ruqyah.json').readAsStringSync());
    expect(misplacedSalawat(decoded), isEmpty);
  });

  test('the honorific check flags other prophets and angels', () {
    expect(
      misplacedSalawat(['Jibreel ﷺ recited', 'the Prophet ﷺ said']),
      hasLength(1),
    );
    expect(
      misplacedSalawat({'bn': 'মুহাম্মাদ (ﷺ)', 'x': 'রাসূলুল্লাহ্‌ (ﷺ)'}),
      isEmpty,
    );
  });
}
