// Integrity checks for the bundled hadith asset produced by
// `dart run tool/hadith_db_build.dart`. Opens assets/data/hadith.db directly
// (tests run with the project root as working directory). Each row holds one
// gzip-compressed JSON section blob (see hadith_blob_codec.dart).

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';

void main() {
  const dbPath = 'assets/data/hadith.db';
  late Database db;

  setUpAll(() {
    expect(
      File(dbPath).existsSync(),
      isTrue,
      reason: 'Missing $dbPath — run `dart run tool/hadith_db_build.dart`.',
    );
    db = sqlite3.open(dbPath, mode: OpenMode.readOnly);
  });

  tearDownAll(() => db.close());

  int scalar(String sql, [List<Object?> params = const []]) =>
      db.select(sql, params).first.values.first! as int;

  /// Decodes one section blob the same way the runtime codec does.
  List<dynamic> blob(String sql, List<Object?> params) {
    final data = db.select(sql, params).first.values.first! as List<int>;
    return jsonDecode(utf8.decode(gzip.decode(data))) as List<dynamic>;
  }

  test('schema version is 2', () {
    expect(scalar('PRAGMA user_version'), 2);
  });

  test('has both section tables, populated', () {
    // ~290 fawazahmed0 sections × (ara+eng) + a few ben editions.
    expect(scalar('SELECT COUNT(*) FROM hadith_section'), greaterThan(500));
    // ~330 hadithbangla chapters across the 6 canonical books.
    expect(scalar('SELECT COUNT(*) FROM hadith_bn_section'), greaterThan(250));
  });

  test('every canonical book has both Arabic and English editions', () {
    const ids = [
      'bukhari',
      'muslim',
      'abudawud',
      'tirmidhi',
      'nasai',
      'ibnmajah',
    ];
    for (final id in ids) {
      expect(
        scalar('SELECT COUNT(*) FROM hadith_section WHERE edition = ?',
            ['ara-$id']),
        greaterThan(0),
        reason: 'ara-$id missing',
      );
      expect(
        scalar('SELECT COUNT(*) FROM hadith_section WHERE edition = ?',
            ['eng-$id']),
        greaterThan(0),
        reason: 'eng-$id missing',
      );
    }
  });

  test('Bukhari section 1 decodes to real Arabic hadith + has a bn chapter',
      () {
    final ar = blob(
      'SELECT data FROM hadith_section WHERE edition = ? AND section = 1',
      ['ara-bukhari'],
    );
    expect(ar, isNotEmpty);
    final first = (ar.first as Map)['t'] as String;
    expect(first.trim(), isNotEmpty);
    expect((ar.first as Map)['n'], 1); // first hadith number

    expect(
      scalar('SELECT COUNT(*) FROM hadith_bn_section '
          'WHERE book_id = ? AND section = 1', ['bukhari']),
      greaterThan(0),
    );
  });

  test('catalog section counts match the hadith actually bundled', () {
    final catalog = jsonDecode(
      File('assets/data/hadith_books.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    for (final book in (catalog['books'] as List<dynamic>)
        .cast<Map<String, dynamic>>()) {
      final sections = [
        for (final s in book['sections'] as List<dynamic>)
          ('hadith_section', 'edition', book['edition_ar'], s),
        for (final s in (book['sections_bn'] as List<dynamic>?) ?? [])
          ('hadith_bn_section', 'book_id', book['id'], s),
      ];
      for (final (table, keyColumn, key, s) in sections) {
        final section = s as Map<String, dynamic>;
        expect(
          blob('SELECT data FROM $table WHERE $keyColumn = ? AND section = ?',
              [key, section['n']]).length,
          section['count'],
          reason: '$table $key §${section['n']}',
        );
      }
    }
  });

  test('a Bengali chapter decodes with Bangla text', () {
    final bn = blob(
      'SELECT data FROM hadith_bn_section WHERE book_id = ? AND section = 1',
      ['bukhari'],
    );
    expect(bn, isNotEmpty);
    expect(((bn.first as Map)['b'] as String).trim(), isNotEmpty);
  });

  test('catalog section counts match the hadith actually in the db', () {
    // The sections list shows `count`; it must be the real number of entries
    // (upstream first/last ranges overlap, so they can't be used for this).
    final catalog =
        jsonDecode(File('assets/data/hadith_books.json').readAsStringSync())
            as Map<String, dynamic>;
    List<dynamic>? rows(String sql, List<Object?> params) {
      final r = db.select(sql, params);
      if (r.isEmpty) {
        return null;
      }
      final data = r.first.values.first! as List<int>;
      return jsonDecode(utf8.decode(gzip.decode(data))) as List<dynamic>;
    }

    for (final book
        in (catalog['books'] as List).cast<Map<String, dynamic>>()) {
      final id = book['id'] as String;
      final bnFolder = book['bn_folder'] as String? ?? '';
      for (final (key, fromBn) in [
        ('sections', false),
        ('sections_bn', true),
      ]) {
        for (final s
            in (book[key] as List? ?? const []).cast<Map<String, dynamic>>()) {
          final n = s['n'] as int;
          final data = fromBn && bnFolder.isNotEmpty
              ? rows(
                  'SELECT data FROM hadith_bn_section '
                  'WHERE book_id = ? AND section = ?',
                  [id, n],
                )
              : rows(
                  'SELECT data FROM hadith_section '
                  'WHERE edition = ? AND section = ?',
                  [book['edition_ar'], n],
                );
          expect(data, isNotNull, reason: '$id $key $n missing from db');
          expect(s['count'], data!.length, reason: '$id $key $n count');
        }
      }
    }
  });
}
