// Removes the hadithbangla Bengali text from the bundled hadith assets, for a
// release built before written permission from its translator/publisher
// (owner decision 4, docs/RELEASE_CHECKLIST.md). Offline, in place:
//   * assets/data/hadith.db — drops `hadith_bn_section`, then VACUUM;
//   * assets/data/hadith_books.json — drops `sections_bn` and `bn_folder`.
// Build the app with `--dart-define=BENGALI_HADITH=false` too: besides the
// credits and the online fallback, HadithDatabase.ensureCopied compares that
// switch with the installed copy's `hadith_bn_section`, so any switch between
// a stripped and a full asset re-copies on device without a user_version
// bump (and a mismatched build re-copies on every launch). user_version is
// left as is on purpose. Undo with
// `git checkout -- assets/data/hadith.db assets/data/hadith_books.json`
// (just these two, so other uncommitted asset work survives).
//
// Usage:  dart run tool/strip_bengali_hadith.dart

import 'dart:convert';
import 'dart:io';

import 'package:sqlite3/sqlite3.dart';

const _dbPath = 'assets/data/hadith.db';
const _catalogPath = 'assets/data/hadith_books.json';

/// [catalog] (hadith_books.json) without any hadithbangla data. Returns how
/// many books lost their Bengali chapters.
int stripCatalog(Map<String, dynamic> catalog) {
  var stripped = 0;
  for (final book in (catalog['books'] as List).cast<Map<String, dynamic>>()) {
    final sections = book.remove('sections_bn');
    final folder = book.remove('bn_folder');
    if ((sections is List && sections.isNotEmpty) ||
        (folder is String && folder.isNotEmpty)) {
      stripped++;
    }
  }
  return stripped;
}

void main() {
  final db = sqlite3.open(_dbPath);
  try {
    db
      ..execute('DROP TABLE IF EXISTS hadith_bn_section')
      ..execute('VACUUM');
  } finally {
    db.close();
  }
  final file = File(_catalogPath);
  final catalog = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  final books = stripCatalog(catalog);
  file.writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(catalog)}\n',
  );
  stdout.writeln(
    'Stripped hadithbangla: hadith_bn_section dropped, $books books lost '
    'their Bengali chapters. Build with --dart-define=BENGALI_HADITH=false, '
    'then: git checkout -- assets/data/hadith.db assets/data/hadith_books.json',
  );
}
