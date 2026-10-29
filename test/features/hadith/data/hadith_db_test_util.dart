import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:productive_muslim/features/hadith/data/hadith_blob_codec.dart';
import 'package:productive_muslim/features/hadith/data/hadith_database.dart';
import 'package:productive_muslim/features/hadith/data/hadith_section_assembler.dart';

/// An in-memory [HadithDatabase] with the bundled schema created but no rows.
/// Mirrors tool/hadith_db_build.dart so tests exercise the real queries +
/// blob codec without touching the committed asset. [withBangla] false mirrors
/// a `--no-bengali` build (no `hadith_bn_section` table).
Future<HadithDatabase> openTestHadithDb({bool withBangla = true}) async {
  final db = HadithDatabase(NativeDatabase.memory());
  await db.customStatement(
    'CREATE TABLE hadith_section '
    '(edition TEXT NOT NULL, section INTEGER NOT NULL, data BLOB NOT NULL, '
    'PRIMARY KEY(edition, section))',
  );
  if (!withBangla) {
    return db;
  }
  await db.customStatement(
    'CREATE TABLE hadith_bn_section '
    '(book_id TEXT NOT NULL, section INTEGER NOT NULL, data BLOB NOT NULL, '
    'PRIMARY KEY(book_id, section))',
  );
  return db;
}

/// Writes one fawazahmed0 edition section as a gzip blob, exactly as the build
/// script does.
Future<void> putFaSection(
  HadithDatabase db, {
  required String edition,
  required int section,
  required List<RawHadith> hadiths,
}) =>
    db.customStatement(
      'INSERT INTO hadith_section(edition, section, data) VALUES (?, ?, ?)',
      [edition, section, Uint8List.fromList(encodeEditionBlob(hadiths))],
    );

/// Writes one hadithbangla chapter as a gzip blob.
Future<void> putBnSection(
  HadithDatabase db, {
  required String bookId,
  required int section,
  required List<BnHadith> hadiths,
}) =>
    db.customStatement(
      'INSERT INTO hadith_bn_section(book_id, section, data) VALUES (?, ?, ?)',
      [bookId, section, Uint8List.fromList(encodeBanglaBlob(hadiths))],
    );
