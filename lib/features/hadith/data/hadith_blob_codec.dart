import 'dart:convert';
import 'dart:io';

import 'hadith_section_assembler.dart';

/// Compact, gzip-compressed encoding of one hadith *section* (all its hadith in
/// one row). Raw per-hadith SQLite rows weighed ~158 MB for the full corpus;
/// the text is highly repetitive, so storing one gzipped JSON blob per section
/// shrinks the bundled asset to ~40 MB while keeping reads a single-row lookup
/// (we always read a whole section at once). The build script
/// (tool/hadith_db_build.dart) and the runtime data source share this codec so
/// the on-disk shape can never drift.

/// fawazahmed0 edition section → blob. Keys kept short (`n`/`t`/`g`) to trim
/// the pre-compression JSON.
List<int> encodeEditionBlob(List<RawHadith> hadiths) => gzip.encode(
      utf8.encode(
        jsonEncode([
          for (final h in hadiths) {'n': h.number, 't': h.text, 'g': h.grade},
        ]),
      ),
    );

List<RawHadith> decodeEditionBlob(List<int> blob) {
  final decoded = jsonDecode(utf8.decode(gzip.decode(blob)));
  if (decoded is! List) {
    return const [];
  }
  return [
    for (final e in decoded)
      if (e is Map)
        RawHadith(
          number: (e['n'] as num).toInt(),
          text: e['t'] as String? ?? '',
          grade: e['g'] as String? ?? '',
        ),
  ];
}

/// hadithbangla chapter → blob (`n`/`a`/`b`/`r`/`g`).
List<int> encodeBanglaBlob(List<BnHadith> hadiths) => gzip.encode(
      utf8.encode(
        jsonEncode([
          for (final h in hadiths)
            {
              'n': h.number,
              'a': h.arabic,
              'b': h.bn,
              'r': h.narrator,
              'g': h.grade,
            },
        ]),
      ),
    );

List<BnHadith> decodeBanglaBlob(List<int> blob) {
  final decoded = jsonDecode(utf8.decode(gzip.decode(blob)));
  if (decoded is! List) {
    return const [];
  }
  return [
    for (final e in decoded)
      if (e is Map)
        BnHadith(
          number: (e['n'] as num).toInt(),
          arabic: e['a'] as String? ?? '',
          bn: e['b'] as String? ?? '',
          narrator: e['r'] as String? ?? '',
          grade: e['g'] as String? ?? '',
        ),
  ];
}
