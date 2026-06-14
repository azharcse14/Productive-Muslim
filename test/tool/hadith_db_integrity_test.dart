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

  test('schema version is 1', () {
    expect(scalar('PRAGMA user_version'), 1);
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

  test('a Bengali chapter decodes with Bangla text', () {
    final bn = blob(
      'SELECT data FROM hadith_bn_section WHERE book_id = ? AND section = 1',
      ['bukhari'],
    );
    expect(bn, isNotEmpty);
    expect(((bn.first as Map)['b'] as String).trim(), isNotEmpty);
  });
}
