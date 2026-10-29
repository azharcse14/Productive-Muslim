import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../helpers/honorific.dart';

/// Integrity checks for the bundled Dua collection and Asmaul Husna data
/// assets. Reads the JSON files directly from disk (flutter test runs with
/// the project root as the working directory).
void main() {
  const allowedIcons = <String>{
    'sun',
    'moon',
    'food',
    'walk',
    'mosque',
    'heart',
    'spark',
    'book',
    'water',
    'shield',
    'speech',
    'people',
  };
  const allowedRepeats = <int>{1, 3, 7, 33, 100};
  const duaFields = <String>['id', 'ar', 'tr', 'en', 'bn', 'ref', 'repeat'];

  group('asmaul_husna.json', () {
    late List<Map<String, Object?>> names;

    setUpAll(() {
      final raw = File('assets/data/asmaul_husna.json').readAsStringSync();
      final decoded = jsonDecode(raw) as List<Object?>;
      names = decoded
          .map((Object? e) => (e as Map<dynamic, dynamic>).cast<String, Object?>())
          .toList();
    });

    test('contains exactly 99 entries', () {
      expect(names, hasLength(99));
    });

    test('entries are sequentially numbered 1..99', () {
      for (var i = 0; i < names.length; i++) {
        expect(names[i]['n'], i + 1, reason: 'entry at index $i must have n=${i + 1}');
      }
    });

    test('every entry has non-empty ar, tr, en and bn fields', () {
      for (final name in names) {
        for (final field in <String>['ar', 'tr', 'en', 'bn']) {
          final value = name[field];
          expect(value, isA<String>(), reason: 'field "$field" of n=${name['n']} must be a string');
          expect(
            (value! as String).trim(),
            isNotEmpty,
            reason: 'field "$field" of n=${name['n']} must not be empty',
          );
        }
      }
    });

    test('first name is Ar-Rahman and last name is As-Sabur', () {
      expect(names.first['tr'], 'Ar-Rahman');
      expect(names.last['tr'], 'As-Sabur');
    });
  });

  group('duas.json', () {
    late List<Map<String, Object?>> categories;
    late List<Map<String, Object?>> allDuas;

    setUpAll(() {
      final raw = File('assets/data/duas.json').readAsStringSync();
      final decoded =
          (jsonDecode(raw) as Map<dynamic, dynamic>).cast<String, Object?>();
      categories = (decoded['categories']! as List<Object?>)
          .map((Object? e) => (e as Map<dynamic, dynamic>).cast<String, Object?>())
          .toList();
      allDuas = categories
          .expand(
            (Map<String, Object?> c) => (c['duas']! as List<Object?>).map(
              (Object? e) => (e as Map<dynamic, dynamic>).cast<String, Object?>(),
            ),
          )
          .toList();
    });

    test('has at least 8 categories', () {
      expect(categories.length, greaterThanOrEqualTo(16));
    });

    test('has at least 32 duas in total', () {
      expect(allDuas.length, greaterThanOrEqualTo(65));
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

    test('every dua has all 7 fields, non-empty', () {
      for (final dua in allDuas) {
        for (final field in duaFields) {
          final value = dua[field];
          expect(
            value,
            isNotNull,
            reason: 'dua "${dua['id']}" is missing field "$field"',
          );
          if (value is String) {
            expect(
              value.trim(),
              isNotEmpty,
              reason: 'field "$field" of dua "${dua['id']}" must not be empty',
            );
          }
        }
      }
    });

    test('every dua repeat value is one of 1, 3, 7, 33, 100', () {
      for (final dua in allDuas) {
        expect(
          dua['repeat'],
          isIn(allowedRepeats),
          reason: 'dua "${dua['id']}" has an invalid repeat value',
        );
      }
    });

    test('passages moved from ruqyah.json sit in their dua categories', () {
      const moved = <String, String>{
        'bismillah_tawakkaltu': 'home',
        'dua_safar': 'travel',
        'allahumma_ikfini': 'distress',
        "audhu_ma'tham_maghram": 'salah',
        'rabbana_zalamna': 'istighfar',
        'bismillah_food': 'food',
        'tahlil_layl': 'waking',
        'rabbana_la_tuzigh': 'knowledge',
        'ya_muqallibal_qulub': 'knowledge',
        'rabbi_zidni_ilma': 'knowledge',
        'rabbir_hamhuma': 'family',
        'rabbanaghfir_walidayya': 'family',
        'barakallahu_laka': 'family',
        'jannibnash_shaytan': 'family',
      };
      final where = {
        for (final c in categories)
          for (final dua in c['duas']! as List<Object?>)
            (dua! as Map<dynamic, dynamic>)['id']: c['id'],
      };
      moved.forEach((id, category) {
        expect(where[id], category, reason: id);
      });
    });

    test('no English field contains Bengali script', () {
      final bengali = RegExp('[ঀ-৿]');
      for (final dua in allDuas) {
        expect(
          bengali.hasMatch(dua['en']! as String),
          isFalse,
          reason: 'dua "${dua['id']}" has Bengali in "en"',
        );
      }
    });

    test('every dua has a Bengali-script transliteration (trBn)', () {
      final bengali = RegExp('[ঀ-৿]');
      for (final dua in allDuas) {
        final trBn = dua['trBn'];
        expect(trBn, isA<String>(), reason: 'dua "${dua['id']}" lacks trBn');
        expect(
          bengali.hasMatch(trBn! as String),
          isTrue,
          reason: 'trBn of dua "${dua['id']}" must be in Bengali script',
        );
      }
    });

    test('dua ids are unique across the whole collection', () {
      final ids = allDuas.map((Map<String, Object?> d) => d['id']).toList();
      expect(ids.toSet(), hasLength(ids.length), reason: 'duplicate dua ids found');
    });
  });

  test('ﷺ in duas.json only follows the Prophet / Messenger / Muhammad', () {
    final decoded =
        jsonDecode(File('assets/data/duas.json').readAsStringSync());
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
