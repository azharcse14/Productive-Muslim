// Writes the numbers each section actually holds into
// assets/data/hadith_books.json as `refs`: runs `[[from, to], …]` of the
// number a card shows — the whole-number part of the displayed reference
// ("Sahih Muslim 17a" → 17), else the hadith number.
//
// Every section of both catalogs (`sections` from the Arabic edition,
// `sections_bn` from the hadithbangla chapters) gets them, because upstream
// `first` / `last` lie: stray numbers make ranges overlap (Tirmidhi §32 is
// 2133–2298 but §33 starts at 2158), and Muslim lists chapters by internal
// number with variants of one number in several chapters (17a–c in 1, 17d–g
// in 36). "Go to hadith number" matches against `refs`.
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
      final bnFolder = book['bn_folder'] as String? ?? '';
      for (final (key, fromBn) in [
        ('sections', false),
        ('sections_bn', true),
      ]) {
        for (final section
            in (book[key] as List? ?? const []).cast<Map<String, dynamic>>()) {
          section.remove('refs');
          final bn = fromBn && bnFolder.isNotEmpty;
          final rows = bn
              ? db.select(
                  'SELECT data FROM hadith_bn_section '
                  'WHERE book_id = ? AND section = ?',
                  [book['id'], section['n']],
                )
              : db.select(
                  'SELECT data FROM hadith_section '
                  'WHERE edition = ? AND section = ?',
                  [edition, section['n']],
                );
          if (rows.isEmpty) {
            continue;
          }
          final data = rows.first.values.first! as List<int>;
          final runs = refRuns(
            bn
                ? [for (final h in decodeBanglaBlob(data)) h.number]
                : [for (final h in decodeEditionBlob(data)) h.referenceNumber],
          );
          section['refs'] = [
            for (final (from, to) in runs) [from, to],
          ];
        }
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
