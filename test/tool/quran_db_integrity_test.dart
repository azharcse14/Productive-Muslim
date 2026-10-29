// Integrity checks for the bundled Quran asset produced by
// `dart run tool/quran_db_build.dart`. Opens assets/data/quran.db directly
// (tests run with the project root as working directory).

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';

void main() {
  const dbPath = 'assets/data/quran.db';
  late Database db;

  setUpAll(() {
    expect(
      File(dbPath).existsSync(),
      isTrue,
      reason: 'Missing $dbPath — run `dart run tool/quran_db_build.dart`.',
    );
    db = sqlite3.open(dbPath, mode: OpenMode.readOnly);
  });

  tearDownAll(() => db.close());

  int scalar(String sql) =>
      db.select(sql).first.values.first! as int;

  test('schema version is 2', () {
    expect(scalar('PRAGMA user_version'), 2);
  });

  test('contains exactly 114 surahs and 6236 ayahs', () {
    expect(scalar('SELECT COUNT(*) FROM surahs'), 114);
    expect(scalar('SELECT COUNT(*) FROM ayahs'), 6236);
  });

  test('surah 1 has 7 ayahs and opens with the bismillah', () {
    expect(scalar('SELECT ayah_count FROM surahs WHERE id = 1'), 7);
    expect(scalar('SELECT COUNT(*) FROM ayahs WHERE surah = 1'), 7);

    final arabic = db
        .select('SELECT arabic FROM ayahs WHERE surah = 1 AND number = 1')
        .first
        .values
        .first! as String;
    expect(
      arabic.startsWith('بِسْمِ') || arabic.startsWith('بِّسْمِ'),
      isTrue,
      reason: 'Ayah 1:1 should start with the bismillah, got "$arabic"',
    );
  });

  test('ayah 1 of other surahs does not carry the basmala', () {
    // 1:1 is the basmala itself; every other ayah 1 must not start with it.
    expect(
      scalar('''
        SELECT COUNT(*) FROM ayahs
        WHERE number = 1 AND surah != 1
          AND instr(arabic, (SELECT arabic FROM ayahs
                             WHERE surah = 1 AND number = 1)) = 1
      '''),
      0,
    );
  });

  test('surah 114 has 6 ayahs', () {
    expect(scalar('SELECT ayah_count FROM surahs WHERE id = 114'), 6);
    expect(scalar('SELECT COUNT(*) FROM ayahs WHERE surah = 114'), 6);
  });

  test('every surah ayah_count matches its stored ayahs', () {
    final mismatches = db.select('''
      SELECT s.id
      FROM surahs s
      LEFT JOIN ayahs a ON a.surah = s.id
      GROUP BY s.id
      HAVING COUNT(a.id) != s.ayah_count
    ''');
    expect(mismatches, isEmpty);
  });

  test('ayah 1:1 has non-empty English and Bangla translations', () {
    final row = db
        .select(
          'SELECT translation_en, translation_bn FROM ayahs '
          'WHERE surah = 1 AND number = 1',
        )
        .first;
    expect((row.values[0]! as String).trim(), isNotEmpty);
    expect((row.values[1]! as String).trim(), isNotEmpty);
  });
}
