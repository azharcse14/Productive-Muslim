import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:productive_muslim/core/storage/bundled_db_file.dart';
import 'package:productive_muslim/features/hadith/data/hadith_database.dart';
import 'package:productive_muslim/features/quran/data/datasources/quran_database.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

void main() {
  late Directory root;
  late Directory docs;
  late Directory support;

  setUp(() {
    root = Directory.systemTemp.createTempSync('bundled_db_');
    docs = Directory(p.join(root.path, 'Documents'))..createSync();
    support = Directory(p.join(root.path, 'Support'))..createSync();
  });
  tearDown(() => root.deleteSync(recursive: true));

  Future<ByteData> asset(String name) async =>
      ByteData.sublistView(File('assets/data/$name').readAsBytesSync());

  /// A pre-migration quran.db: older user_version, with user tables.
  File legacyQuranDb() {
    final f = File(p.join(docs.path, 'quran.db'));
    sqlite.sqlite3.open(f.path)
      ..execute('PRAGMA user_version = 0')
      ..execute('CREATE TABLE bookmarks(ayah_id INTEGER PRIMARY KEY)')
      ..execute('INSERT INTO bookmarks VALUES (7), (255)')
      ..execute(
        'CREATE TABLE last_read(id INTEGER PRIMARY KEY CHECK(id = 1), '
        'surah INTEGER, ayah INTEGER)',
      )
      ..execute('INSERT INTO last_read VALUES (1, 18, 10)')
      ..close();
    return f;
  }

  group('migrateLegacyDb', () {
    test('moves the Documents copy and its sidecars, deleting the old', () {
      final legacy = File(p.join(docs.path, 'x.db'))..writeAsStringSync('db');
      File('${legacy.path}-journal').writeAsStringSync('j');
      final target = File(p.join(support.path, 'x.db'));

      migrateLegacyDb(legacy: legacy, target: target);

      expect(target.readAsStringSync(), 'db');
      expect(File('${target.path}-journal').readAsStringSync(), 'j');
      expect(legacy.existsSync(), isFalse);
      expect(File('${legacy.path}-journal').existsSync(), isFalse);
    });

    test('drops a stale legacy copy when the target already exists', () {
      final legacy = File(p.join(docs.path, 'x.db'))..writeAsStringSync('old');
      final target = File(p.join(support.path, 'x.db'))
        ..writeAsStringSync('new');

      migrateLegacyDb(legacy: legacy, target: target);

      expect(target.readAsStringSync(), 'new');
      expect(legacy.existsSync(), isFalse);
    });

    test('is a no-op on a fresh install', () {
      final target = File(p.join(support.path, 'x.db'));
      migrateLegacyDb(legacy: File(p.join(docs.path, 'x.db')), target: target);
      expect(target.existsSync(), isFalse);
    });
  });

  group('writeDbAtomically', () {
    test('a failure before the rename leaves the old file intact', () async {
      final target = File(p.join(support.path, 'x.db'))
        ..writeAsStringSync('old');
      await expectLater(
        writeDbAtomically(
          target,
          'new'.codeUnits,
          prepare: (_) => throw const FileSystemException('killed'),
        ),
        throwsA(isA<FileSystemException>()),
      );
      expect(target.readAsStringSync(), 'old');
    });

    test('replaces the file and leaves no temp behind', () async {
      final target = File(p.join(support.path, 'x.db'))
        ..writeAsStringSync('old');
      await writeDbAtomically(target, 'new'.codeUnits);
      expect(target.readAsStringSync(), 'new');
      expect(File('${target.path}.tmp').existsSync(), isFalse);
    });
  });

  test(
    'legacy quran.db migrates with bookmarks and last read intact',
    () async {
      final legacy = legacyQuranDb();
      final target = File(p.join(support.path, 'quran.db'));

      migrateLegacyDb(legacy: legacy, target: target);
      await QuranDatabase.ensureCopied(target, () => asset('quran.db'));

      expect(legacy.existsSync(), isFalse);
      final db = sqlite.sqlite3.open(target.path);
      addTearDown(db.close);
      expect(db.userVersion, QuranDatabase.bundledVersion);
      expect(
        db.select('SELECT ayah_id FROM bookmarks ORDER BY 1').map((r) => r['ayah_id']),
        [7, 255],
      );
      expect(db.select('SELECT surah, ayah FROM last_read').first.values, [
        18,
        10,
      ]);
      // The asset's own tables came across too.
      expect(db.select('SELECT COUNT(*) FROM ayahs').first.values.first, 6236);
    },
  );

  test('an up-to-date quran.db is left untouched', () async {
    final target = File(p.join(support.path, 'quran.db'));
    await QuranDatabase.ensureCopied(target, () => asset('quran.db'));
    sqlite.sqlite3.open(target.path)
      ..execute(
        'CREATE TABLE IF NOT EXISTS bookmarks(ayah_id INTEGER PRIMARY KEY)',
      )
      ..execute('INSERT INTO bookmarks VALUES (1)')
      ..close();

    await QuranDatabase.ensureCopied(
      target,
      () => fail('must not re-read the asset'),
    );

    final db = sqlite.sqlite3.open(target.path);
    addTearDown(db.close);
    expect(db.select('SELECT ayah_id FROM bookmarks').length, 1);
  });

  test('hadith.db copies on first run and skips when current', () async {
    final target = File(p.join(support.path, 'bundled', 'hadith.db'))
      ..parent.createSync();
    await HadithDatabase.ensureCopied(target, () => asset('hadith.db'));
    final db = sqlite.sqlite3.open(target.path);
    expect(db.userVersion, HadithDatabase.bundledVersion);
    db.close();
    await HadithDatabase.ensureCopied(
      target,
      () => fail('must not re-read the asset'),
    );
  });
}
