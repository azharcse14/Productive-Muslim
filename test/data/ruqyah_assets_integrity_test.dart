import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../helpers/arabic.dart';
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
      final decoded = (jsonDecode(raw) as Map<dynamic, dynamic>)
          .cast<String, Object?>();
      categories = (decoded['categories']! as List<Object?>)
          .map(
            (Object? e) => (e as Map<dynamic, dynamic>).cast<String, Object?>(),
          )
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

    test(
      'has exactly the ruqyah categories (everyday duas live in duas.json)',
      () {
        expect(categories.map((Map<String, Object?> c) => c['id']), <String>[
          'protection',
          'three_quls',
          'healing',
          'evil_eye',
          'sihr_jinn',
          'anxiety_grief',
          'sleep',
          'morning_evening',
          'enemies',
          'children',
          'fitan',
        ]);
      },
    );

    test('has at least 37 ruqyah passages in total', () {
      expect(allItems.length, greaterThanOrEqualTo(37));
    });

    test('no passage appears twice', () {
      final seen = <String, Object?>{};
      for (final item in allItems) {
        final key = bareArabic(item['ar']! as String);
        expect(
          seen[key],
          isNull,
          reason: '${item['id']} duplicates ${seen[key]}',
        );
        seen[key] = item['id'];
      }
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
      expect(
        ids.toSet(),
        hasLength(ids.length),
        reason: 'duplicate ruqyah ids found',
      );
    });

    test('the three Quls category holds Ikhlas, Falaq and Nas', () {
      final quls = categories.firstWhere(
        (Map<String, Object?> c) => c['id'] == 'three_quls',
      );
      final ids = (quls['items']! as List<Object?>)
          .map(
            (Object? e) =>
                (e as Map<dynamic, dynamic>).cast<String, Object?>()['id'],
          )
          .toList();
      expect(ids, containsAll(<String>['ikhlas', 'falaq', 'nas']));
    });
  });

  test('tibb_nabawi.json: complete bilingual items, unique ids, no ruqyah '
      'overlap', () {
    List<Map<String, Object?>> items(String path) {
      final root =
          (jsonDecode(File(path).readAsStringSync()) as Map<dynamic, dynamic>)
              .cast<String, Object?>();
      return [
        for (final c in root['categories']! as List<Object?>)
          for (final i
              in (c! as Map<dynamic, dynamic>)['items'] as List<Object?>)
            (i! as Map<dynamic, dynamic>).cast<String, Object?>(),
      ];
    }

    final tibb = items('assets/data/tibb_nabawi.json');
    final ruqyahIds = items('assets/data/ruqyah.json').map((i) => i['id']);
    expect(tibb.length, greaterThanOrEqualTo(20));
    for (final item in tibb) {
      for (final field in [
        'id',
        'titleEn',
        'titleBn',
        'ar',
        'tr',
        'en',
        'bn',
        'ref',
        'detailsEn',
        'detailsBn',
      ]) {
        expect(
          (item[field] as String?)?.trim(),
          isNotEmpty,
          reason: '${item['id']}.$field',
        );
      }
    }
    final ids = tibb.map((i) => i['id']).toList();
    expect(ids.toSet(), hasLength(ids.length));
    expect(ids.toSet().intersection(ruqyahIds.toSet()), isEmpty);
    expect(
      misplacedSalawat(
        jsonDecode(File('assets/data/tibb_nabawi.json').readAsStringSync()),
      ),
      isEmpty,
    );
  });

  test('ﷺ in ruqyah.json only follows the Prophet / Messenger / Muhammad', () {
    final decoded = jsonDecode(
      File('assets/data/ruqyah.json').readAsStringSync(),
    );
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
