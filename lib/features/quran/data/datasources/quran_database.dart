import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter/services.dart' show ByteData, rootBundle;
import 'package:sqlite3/sqlite3.dart' as sqlite;

import '../../../../core/storage/bundled_db_file.dart';

/// Raw-SQL drift handle over the bundled Quran database (guide §5).
///
/// No codegen: the read-only tables (`surahs`, `ayahs`) ship inside
/// `assets/data/quran.db`, so this class only needs `customSelect` /
/// `customStatement`. User state lives in two extra tables created on
/// every open: `bookmarks(ayah_id)` and `last_read(id=1, surah, ayah)`.
final class QuranDatabase extends GeneratedDatabase {
  /// Takes a [QueryExecutor] so tests can open a copy of the asset file.
  QuranDatabase(super.executor);

  /// `PRAGMA user_version` of the bundled asset. Bump together with the
  /// asset (tool/quran_db_build.dart) to force a re-copy on upgrade.
  static const bundledVersion = 2;

  static const _assetPath = 'assets/data/quran.db';
  static const _fileName = 'quran.db';

  @override
  Iterable<TableInfo<Table, dynamic>> get allTables => const [];

  @override
  int get schemaVersion => bundledVersion;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        beforeOpen: (_) async {
          await customStatement(
            'CREATE TABLE IF NOT EXISTS '
            'bookmarks(ayah_id INTEGER PRIMARY KEY)',
          );
          await customStatement(
            'CREATE TABLE IF NOT EXISTS '
            'last_read(id INTEGER PRIMARY KEY CHECK(id = 1), '
            'surah INTEGER, ayah INTEGER)',
          );
        },
      );

  /// Copies the bundled asset into Application Support on first run (or on
  /// a version bump, preserving bookmarks/last-read) and opens it. Not in
  /// the backup-excluded `bundled/` dir: it holds the user's bookmarks.
  static Future<QuranDatabase> open() async {
    final file = await bundledDbFile(_fileName);
    await ensureCopied(file, () => rootBundle.load(_assetPath));
    return QuranDatabase(NativeDatabase.createInBackground(file));
  }

  /// Skips the copy when [file] already matches [bundledVersion]; otherwise
  /// atomically replaces it with the asset from [load], with user state
  /// written into the new copy before it takes [file]'s place.
  @visibleForTesting
  static Future<void> ensureCopied(
    File file,
    Future<ByteData> Function() load,
  ) async {
    _UserState? preserved;
    if (file.existsSync()) {
      try {
        final existing = sqlite.sqlite3.open(file.path);
        try {
          if (existing.userVersion == bundledVersion) {
            return;
          }
          preserved = _UserState.read(existing);
        } finally {
          existing.close();
        }
      } on sqlite.SqliteException {
        // Corrupt / not a database: re-copy below. Bookmarks survive only
        // when they were read before the failure.
      }
    }
    final bytes = await load();
    await writeDbAtomically(
      file,
      bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
      prepare: preserved == null
          ? null
          : (tmpPath) {
              final fresh = sqlite.sqlite3.open(tmpPath);
              try {
                preserved!.writeInto(fresh);
              } finally {
                fresh.close();
              }
            },
    );
  }
}

/// Bookmarks + last-read snapshot carried across asset re-copies.
final class _UserState {
  const _UserState(this.bookmarks, this.lastRead);

  factory _UserState.read(sqlite.Database db) {
    final bookmarks = _hasTable(db, 'bookmarks')
        ? [
            for (final row in db.select('SELECT ayah_id FROM bookmarks'))
              row.values.first! as int,
          ]
        : const <int>[];
    (int, int)? lastRead;
    if (_hasTable(db, 'last_read')) {
      final rows =
          db.select('SELECT surah, ayah FROM last_read WHERE id = 1');
      if (rows.isNotEmpty) {
        lastRead = (
          rows.first.values[0]! as int,
          rows.first.values[1]! as int,
        );
      }
    }
    return _UserState(bookmarks, lastRead);
  }

  final List<int> bookmarks;
  final (int, int)? lastRead;

  static bool _hasTable(sqlite.Database db, String name) => db
      .select(
        "SELECT 1 FROM sqlite_master WHERE type = 'table' AND name = ?",
        [name],
      )
      .isNotEmpty;

  void writeInto(sqlite.Database db) {
    db
      ..execute(
        'CREATE TABLE IF NOT EXISTS bookmarks(ayah_id INTEGER PRIMARY KEY)',
      )
      ..execute(
        'CREATE TABLE IF NOT EXISTS '
        'last_read(id INTEGER PRIMARY KEY CHECK(id = 1), '
        'surah INTEGER, ayah INTEGER)',
      );
    for (final id in bookmarks) {
      db.execute('INSERT OR IGNORE INTO bookmarks(ayah_id) VALUES (?)', [id]);
    }
    if (lastRead case (final surah, final ayah)) {
      db.execute(
        'INSERT OR REPLACE INTO last_read(id, surah, ayah) VALUES (1, ?, ?)',
        [surah, ayah],
      );
    }
  }
}
