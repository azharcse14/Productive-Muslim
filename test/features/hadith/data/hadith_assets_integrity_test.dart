import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Integrity checks for the bundled hadith collection asset. Reads the JSON
/// file directly from disk (flutter test runs with the project root as the
/// working directory).
void main() {
  group('hadith.json', () {
    late List<Map<String, Object?>> hadith;

    setUpAll(() {
      final raw = File('assets/data/hadith.json').readAsStringSync();
      final decoded =
          (jsonDecode(raw) as Map<dynamic, dynamic>).cast<String, Object?>();
      hadith = (decoded['hadith']! as List<Object?>)
          .map((Object? e) => (e as Map<dynamic, dynamic>).cast<String, Object?>())
          .toList();
    });

    test('contains exactly 40 entries', () {
      expect(hadith, hasLength(40));
    });

    test('ids are unique across the whole collection', () {
      final ids = hadith.map((Map<String, Object?> h) => h['id']).toList();
      expect(ids.toSet(), hasLength(ids.length), reason: 'duplicate ids found');
    });

    test('every entry has non-empty en, bn, narrator and ref fields', () {
      for (final h in hadith) {
        for (final field in <String>['en', 'bn', 'narrator', 'ref']) {
          final value = h[field];
          expect(
            value,
            isA<String>(),
            reason: 'field "$field" of "${h['id']}" must be a string',
          );
          expect(
            (value! as String).trim(),
            isNotEmpty,
            reason: 'field "$field" of "${h['id']}" must not be empty',
          );
        }
      }
    });
  });
}
