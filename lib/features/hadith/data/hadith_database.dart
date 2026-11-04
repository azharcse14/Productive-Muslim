import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter/services.dart' show ByteData, rootBundle;
import 'package:sqlite3/sqlite3.dart' as sqlite;

import '../../../config/app_config.dart';
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
  static const bundledVersion = 3;

  static const _assetPath = 'assets/data/hadith.db';
  static const _fileName = 'hadith.db';

  @override
  Iterable<TableInfo<Table, dynamic>> get allTables => const [];

  @override
  int get schemaVersion => bundledVersion;

  /// Copies the bundled asset into Application Support/bundled (excluded
  /// from device backups — it is re-creatable) on first run or a version
  /// bump, and opens it.
  static Future<HadithDatabase> open() async =>
      HadithDatabase(NativeDatabase.createInBackground(await _bundledFile()));

  /// Path of the copied asset, for the search isolate's own read-only
  /// connection (it copies once, shared with [open]).
  static Future<String> bundledPath() async => (await _bundledFile()).path;

  static Future<File>? _file;

  /// Copies once per process; a failed copy is retried on the next call.
  static Future<File> _bundledFile() => _file ??=
      () async {
        final file = await bundledDbFile(_fileName, subdir: 'bundled');
        await ensureCopied(file, () => rootBundle.load(_assetPath));
        return file;
      }().then(
        (f) => f,
        onError: (Object e, StackTrace s) {
          _file = null;
          Error.throwWithStackTrace(e, s);
        },
      );

  /// Skips the copy when [file] already matches [bundledVersion] *and*
  /// holds the Bengali table exactly when [bengali] (the build's
  /// `BENGALI_HADITH` switch, which goes with a stripped asset); otherwise
  /// atomically replaces it with the asset from [load]. The second check
  /// means a switch between a stripped and a full asset re-copies even when
  /// nobody bumped the version — the stale copy never keeps (or lacks) the
  /// hadithbangla text.
  @visibleForTesting
  static Future<void> ensureCopied(
    File file,
    Future<ByteData> Function() load, {
    bool bengali = AppConfig.bengaliHadith,
  }) async {
    if (file.existsSync()) {
      try {
        final existing = sqlite.sqlite3.open(file.path);
        try {
          final hasBengali = existing
              .select(
                "SELECT 1 FROM sqlite_master WHERE type = 'table' "
                "AND name = 'hadith_bn_section'",
              )
              .isNotEmpty;
          if (existing.userVersion == bundledVersion && hasBengali == bengali) {
            return;
          }
        } finally {
          existing.close();
        }
      } on sqlite.SqliteException {
        // Corrupt / not a database: nothing to keep, re-copy below.
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

  /// False for a snapshot built with `--no-bengali` (no hadithbangla text).
  Future<bool> hasBanglaSections() async {
    final rows = await customSelect(
      "SELECT 1 FROM sqlite_master WHERE type = 'table' "
      "AND name = 'hadith_bn_section'",
    ).get();
    return rows.isNotEmpty;
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
