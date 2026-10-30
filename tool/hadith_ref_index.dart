// Writes each section's standard-reference numbers into
// assets/data/hadith_books.json as `refs`: runs `[[from, to], …]` of the
// whole-number part of the displayed reference ("Sahih Muslim 17a" → 17).
//
// Only books whose Arabic edition carries refs (`r` in the blobs: today Sahih
// Muslim) get them; elsewhere the internal number already is the reference
// and `first` / `last` serve "go to hadith number". Muslim needs this: its
// chapters are listed by internal number (chapter 1 starts at 93), and
// variants of one number sit in several chapters (17a–c in 1, 17d–g in 36).
//
// Run after `tool/hadith_db_build.dart`:
//   dart run tool/hadith_ref_index.dart
// test/tool/hadith_db_integrity_test.dart checks the two stay in step.

import 'dart:convert';
import 'dart:io';

import 'package:productive_muslim/features/hadith/data/hadith_blob_codec.dart';
import 'package:sqlite3/sqlite3.dart';

const _catalogPath = 'assets/data/hadith_books.json';
const _dbPath = 'assets/data/hadith.db';

void main() {
  final catalog =
      jsonDecode(File(_catalogPath).readAsStringSync()) as Map<String, dynamic>;
  final db = sqlite3.open(_dbPath, mode: OpenMode.readOnly);
  try {
    for (final book
        in (catalog['books'] as List).cast<Map<String, dynamic>>()) {
      final edition = book['edition_ar'] as String? ?? 'ara-${book['id']}';
      for (final section
          in (book['sections'] as List? ?? const [])
              .cast<Map<String, dynamic>>()) {
        section.remove('refs');
        final rows = db.select(
          'SELECT data FROM hadith_section WHERE edition = ? AND section = ?',
          [edition, section['n']],
        );
        if (rows.isEmpty) {
          continue;
        }
        final hadiths = decodeEditionBlob(
          rows.first.values.first! as List<int>,
        );
        if (hadiths.every((h) => h.ref.isEmpty)) {
          continue;
        }
        final runs = refRuns([for (final h in hadiths) h.referenceNumber]);
        section['refs'] = [
          for (final (from, to) in runs) [from, to],
        ];
      }
    }
  } finally {
    db.close();
  }
  File(_catalogPath).writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(catalog)}\n',
  );
  stdout.writeln('Wrote refs into $_catalogPath');
}

/// Sorted, merged runs of consecutive numbers.
List<(int, int)> refRuns(Iterable<int> numbers) {
  final sorted = numbers.toSet().toList()..sort();
  final runs = <(int, int)>[];
  for (final n in sorted) {
    if (runs.isNotEmpty && runs.last.$2 + 1 == n) {
      runs.last = (runs.last.$1, n);
    } else {
      runs.add((n, n));
    }
  }
  return runs;
}
