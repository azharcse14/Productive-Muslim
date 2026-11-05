// Integrity checks for the bundled Quran asset produced by
// `dart run tool/quran_db_build.dart`. Opens assets/data/quran.db directly
// (tests run with the project root as working directory).

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:productive_muslim/features/quran/data/datasources/quran_database.dart';
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

  int scalar(String sql) => db.select(sql).first.values.first! as int;

  test('schema version matches QuranDatabase.bundledVersion (6)', () {
    expect(scalar('PRAGMA user_version'), 6);
    expect(QuranDatabase.bundledVersion, 6);
  });

  String arabic(int surah, int ayah) =>
      db
              .select(
                'SELECT arabic FROM ayahs WHERE surah = ? AND number = ?',
                [surah, ayah],
              )
              .first
              .values
              .first!
          as String;

  test('Arabic is the KFGQPC Uthmani Hafs edition', () {
    // Uthmani-only marks: small high dotless head of khah (sukun) and
    // alef wasla; Tanzil Simple has neither.
    expect(arabic(1, 2), contains('\u06E1'));
    expect(arabic(1, 2), startsWith('\u0671'));
    // KFGQPC open tanween (U+0657/U+065E/U+0656), not the Unicode U+08F0..2
    // the font lacks, and no RLM or split tanween-alif words left over.
    expect(arabic(2, 255), contains('\u065E')); // سِنَةٞ
    expect(
      arabic(2, 22),
      contains('\u0641\u0650\u0631\u064E\u0670\u0634\u0657\u0627 '),
    ); // فِرَٰشٗا
    expect(
      scalar(
        "SELECT COUNT(*) FROM ayahs WHERE arabic GLOB '*[\u08F0-\u08F2\u200F]*'",
      ),
      0,
    );
  });

  test('2:255 is Ayat al-Kursi', () {
    final text = arabic(2, 255);
    expect(text, startsWith('ٱللَّهُ'));
    expect(text, endsWith('ٱلۡعَظِيمُ'));
  });

  test('3:1 and 12:1 carry the Alif / verses corrections', () {
    String en(int surah, int ayah) =>
        db
                .select(
                  'SELECT translation_en FROM ayahs WHERE surah = ? AND number = ?',
                  [surah, ayah],
                )
                .first
                .values
                .first!
            as String;
    expect(en(3, 1), startsWith('Alif. Lam. Mim'));
    expect(en(12, 1), contains('These are verses of'));
  });

  test('31:14 carries the parents/পিতা-মাতার corrections', () {
    final row = db
        .select(
          'SELECT translation_en, translation_bn FROM ayahs '
          'WHERE surah = 31 AND number = 14',
        )
        .first;
    expect(row['translation_en'], contains('concerning his parents'));
    expect(row['translation_bn'], isNot(contains('পিতা-মতার')));
  });

  test('contains exactly 114 surahs and 6236 ayahs', () {
    expect(scalar('SELECT COUNT(*) FROM surahs'), 114);
    expect(scalar('SELECT COUNT(*) FROM ayahs'), 6236);
  });

  test('all 114 surahs have a Bengali name and meaning, no ASCII digits', () {
    expect(
      scalar(
        "SELECT COUNT(*) FROM surahs WHERE trim(name_bn) != '' "
        "AND trim(meaning_bn) != '' "
        "AND name_bn NOT GLOB '*[0-9A-Za-z]*' "
        "AND meaning_bn NOT GLOB '*[0-9A-Za-z]*'",
      ),
      114,
    );
    String nameBn(int id) =>
        db.select('SELECT name_bn FROM surahs WHERE id = ?', [
              id,
            ]).first['name_bn']!
            as String;
    expect(nameBn(1), 'ফাতিহা');
    expect(nameBn(3), 'আলে-ইমরান');
    expect(nameBn(111), 'মাসাদ');
    expect(nameBn(114), 'নাস');
  });

  test('surah 1 has 7 ayahs and opens with the bismillah', () {
    expect(scalar('SELECT ayah_count FROM surahs WHERE id = 1'), 7);
    expect(scalar('SELECT COUNT(*) FROM ayahs WHERE surah = 1'), 7);

    final bismillah = arabic(1, 1);
    expect(
      bismillah,
      startsWith('بِسۡمِ'),
      reason: 'Ayah 1:1 should start with the bismillah, got "$bismillah"',
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

  test('no ayah has empty Arabic text', () {
    expect(scalar("SELECT COUNT(*) FROM ayahs WHERE trim(arabic) = ''"), 0);
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
