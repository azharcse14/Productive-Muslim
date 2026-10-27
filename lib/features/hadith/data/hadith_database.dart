import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter/services.dart' show ByteData, rootBundle;
import 'package:sqlite3/sqlite3.dart' as sqlite;

import '../../../core/storage/bundled_db_file.dart';

/// Raw-SQL drift handle over the bundled, read-only hadith database
/// (`assets/data/hadith.db`, built by tool/hadith_db_build.dart).
///
/// No codegen and no user tables — it only ever runs `customSelect` against
/// `hadith_section` (fawazahmed0 ara/eng/ben editions) and `hadith_bn_section`
/// (hadithbangla per-chapter Bangla). Each row is one gzip-compressed section
/// blob (see hadith_blob_codec.dart). Snapshotting the full text here is what
/// makes the hadith reader work fully offline and outlive the upstream
/// open-source sources being moved or deleted.
final class HadithDatabase extends GeneratedDatabase {
  /// Takes a [QueryExecutor] so tests can open a copy of the asset file.
  HadithDatabase(super.executor);

  /// `PRAGMA user_version` of the bundled asset. Bump together with the asset
  /// (tool/hadith_db_build.dart) to force a re-copy on upgrade.
  static const bundledVersion = 1;

  static const _assetPath = 'assets/data/hadith.db';
  static const _fileName = 'hadith.db';

  @override
  Iterable<TableInfo<Table, dynamic>> get allTables => const [];

  @override
  int get schemaVersion => bundledVersion;

  /// Copies the bundled asset into Application Support/bundled (excluded
  /// from device backups — it is re-creatable) on first run or a version
  /// bump, and opens it.
  static Future<HadithDatabase> open() async {
    final file = await bundledDbFile(_fileName, subdir: 'bundled');
    await ensureCopied(file, () => rootBundle.load(_assetPath));
    return HadithDatabase(NativeDatabase.createInBackground(file));
  }

  /// Skips the copy when [file] already matches [bundledVersion]; otherwise
  /// atomically replaces it with the asset from [load].
  @visibleForTesting
  static Future<void> ensureCopied(
    File file,
    Future<ByteData> Function() load,
  ) async {
    if (file.existsSync()) {
      final existing = sqlite.sqlite3.open(file.path);
      try {
        if (existing.userVersion == bundledVersion) {
          return;
        }
      } finally {
        existing.close();
      }
    }
    final bytes = await load();
    await writeDbAtomically(
      file,
      bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
    );
  }

  /// The gzip blob of one fawazahmed0 [edition]'s [section], or null when the
  /// snapshot has no such section (the caller then falls back to the network).
  Future<Uint8List?> editionBlob(String edition, int section) async {
    final rows = await customSelect(
      'SELECT data FROM hadith_section WHERE edition = ?1 AND section = ?2',
      variables: [Variable<String>(edition), Variable<int>(section)],
    ).get();
    return rows.isEmpty ? null : rows.first.read<Uint8List>('data');
  }

  /// The gzip blob of one hadithbangla [section] of [bookId], or null.
  Future<Uint8List?> banglaBlob(String bookId, int section) async {
    final rows = await customSelect(
      'SELECT data FROM hadith_bn_section WHERE book_id = ?1 AND section = ?2',
      variables: [Variable<String>(bookId), Variable<int>(section)],
    ).get();
    return rows.isEmpty ? null : rows.first.read<Uint8List>('data');
  }
}
