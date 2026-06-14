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

    test('every entry is topic-tagged with a known topic', () {
      const known = {
        'intention', 'faith', 'character', 'speech', 'knowledge',
        'charity', 'mercy', 'worship', 'dunya', 'other',
      };
      for (final h in hadith) {
        expect(
          known,
          contains(h['topic']),
          reason: 'unknown topic "${h['topic']}" on "${h['id']}"',
        );
      }
    });

    test('every hadith is graded authentic (Sahih or Hasan)', () {
      for (final h in hadith) {
        expect(
          <String>['Sahih', 'Hasan'],
          contains(h['grade']),
          reason: '"${h['id']}" must be Sahih or Hasan, got "${h['grade']}"',
        );
      }
    });
  });

  group('hadith_books.json catalog', () {
    late List<Map<String, Object?>> books;

    setUpAll(() {
      final raw = File('assets/data/hadith_books.json').readAsStringSync();
      final decoded =
          (jsonDecode(raw) as Map<dynamic, dynamic>).cast<String, Object?>();
      books = (decoded['books']! as List<Object?>)
          .map((e) => (e as Map<dynamic, dynamic>).cast<String, Object?>())
          .toList();
    });

    test('includes the two Sahihs marked as wholly authentic', () {
      final sahih = books
          .where((b) => b['kind'] == 'sahih')
          .map((b) => b['id'])
          .toSet();
      expect(sahih, containsAll(<String>['bukhari', 'muslim']));
    });

    test('every book has edition keys and at least one section', () {
      for (final b in books) {
        for (final field in <String>['edition_ar', 'edition_en', 'edition_bn']) {
          expect((b[field]! as String).trim(), isNotEmpty);
        }
        expect(b['sections'], isA<List<Object?>>());
        expect(b['sections']! as List<Object?>, isNotEmpty);
      }
    });

    test('hadithbangla books carry a bn_folder and Bengali chapters', () {
      // The six canonical collections served in Bengali by the hadithbangla
      // repo must have both a folder and a non-empty Bengali chapter list.
      const bnBooks = {
        'bukhari', 'muslim', 'abudawud', 'tirmidhi', 'nasai', 'ibnmajah',
      };
      for (final b in books) {
        if (bnBooks.contains(b['id'])) {
          expect((b['bn_folder']! as String).trim(), isNotEmpty,
              reason: '${b['id']} should have a bn_folder');
          expect(b['sections_bn']! as List<Object?>, isNotEmpty,
              reason: '${b['id']} should have Bengali chapters');
        }
      }
    });

    test('a book with no Bengali anywhere is flagged bn_available=false', () {
      final qudsi = books.firstWhere((b) => b['id'] == 'qudsi');
      expect(qudsi['bn_available'], isFalse);
      expect((qudsi['bn_folder'] as String?) ?? '', isEmpty);
    });
  });
}
