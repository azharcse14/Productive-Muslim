import 'dart:typed_data';

import '../domain/entities/hadith_book.dart';
import '../domain/entities/hadith_search.dart';
import 'hadith_blob_codec.dart';

/// Full-collection hadith search over the bundled snapshot.
///
/// hadith.db stores each section as one gzip blob (hadith_blob_codec.dart),
/// so there is no text column SQL `LIKE`/FTS could scan. Instead the
/// English + Bangla text is decoded once into memory (~30 M chars, ~1 s on
/// a desktop, run in an isolate) and each query is a case-insensitive
/// [RegExp] scan of it (~10–30 ms for the whole corpus on a desktop).
// ponytail: in-memory linear scan; add an FTS5 table to hadith.db if
// queries ever get too slow on low-end phones (costs a DB rebuild + MBs).

/// One searchable hadith text.
final class HadithSearchEntry {
  const HadithSearchEntry(this.book, this.section, this.number, this.text);

  /// Index into [HadithSearchCorpus.books].
  final int book;
  final int section;

  /// The number the hadith card shows (and the reader focuses on).
  final int number;
  final String text;
}

/// The decoded search text: English and Bangla entries, in catalog order.
final class HadithSearchCorpus {
  const HadithSearchCorpus(this.books, this.en, this.bn);

  final List<HadithBook> books;
  final List<HadithSearchEntry> en;
  final List<HadithSearchEntry> bn;
}

/// One section blob to decode: [book] index, [bangla] = hadithbangla codec
/// (else fawazahmed0), and whether it is Bangla text ([bn]).
typedef HadithSearchBlob = ({
  int book,
  int section,
  bool bn,
  bool bangla,
  Uint8List data,
});

/// Decodes [blobs] into search entries. Pure — run it in an isolate.
({List<HadithSearchEntry> en, List<HadithSearchEntry> bn}) decodeSearchBlobs(
  List<HadithSearchBlob> blobs,
) {
  final en = <HadithSearchEntry>[];
  final bn = <HadithSearchEntry>[];
  for (final b in blobs) {
    final out = b.bn ? bn : en;
    if (b.bangla) {
      for (final h in decodeBanglaBlob(b.data)) {
        if (h.bn.isNotEmpty) {
          out.add(HadithSearchEntry(b.book, b.section, h.number, h.bn));
        }
      }
    } else {
      for (final h in decodeEditionBlob(b.data)) {
        if (h.text.isNotEmpty) {
          out.add(
            HadithSearchEntry(b.book, b.section, h.referenceNumber, h.text),
          );
        }
      }
    }
  }
  return (en: en, bn: bn);
}

/// Searches [corpus] for [query]: an all-digit query (Bangla digits map to
/// ASCII) is a hadith-number lookup in each book's [languageCode] text (its
/// English when the book has no Bangla); anything else a case-insensitive
/// substring match, [languageCode]'s text first. At most [limit] hits.
HadithSearchResults searchHadithCorpus(
  HadithSearchCorpus corpus,
  String query,
  String languageCode, {
  int limit = hadithSearchLimit,
}) {
  final q = query.trim();
  if (q.isEmpty) {
    return (hits: const [], truncated: false);
  }
  final bnFirst = languageCode == 'bn';
  final ordered = bnFirst
      ? [(corpus.bn, 'bn'), (corpus.en, 'en')]
      : [(corpus.en, 'en'), (corpus.bn, 'bn')];
  final hits = <HadithSearchHit>[];
  final digits = _asciiDigits(q);
  final number = RegExp(r'^\d+$').hasMatch(digits)
      ? int.tryParse(digits)
      : null;
  final bnBooks = number == null
      ? const <int>{}
      : {for (final e in corpus.bn) e.book};
  final pattern = RegExp(RegExp.escape(q), caseSensitive: false);
  for (final (entries, lang) in ordered) {
    for (final e in entries) {
      final HadithSearchHit? hit;
      if (number != null) {
        // One language per book, so a number doesn't list every book twice.
        final wanted = bnFirst && bnBooks.contains(e.book) ? 'bn' : 'en';
        hit = e.number == number && lang == wanted
            ? _hit(corpus, e, lang, 0, 0)
            : null;
      } else {
        final m = pattern.firstMatch(e.text);
        hit = m == null ? null : _hit(corpus, e, lang, m.start, m.end);
      }
      if (hit == null) {
        continue;
      }
      if (hits.length == limit) {
        return (hits: hits, truncated: true);
      }
      hits.add(hit);
    }
  }
  return (hits: hits, truncated: false);
}

const _before = 60;
const _after = 120;

HadithSearchHit? _hit(
  HadithSearchCorpus corpus,
  HadithSearchEntry e,
  String lang,
  int start,
  int end,
) {
  final book = corpus.books[e.book];
  final section = book
      .sectionsFor(lang)
      .where((s) => s.number == e.section)
      .firstOrNull;
  if (section == null) {
    return null; // snapshot and catalog disagree: nothing to open
  }
  final text = e.text;
  var from = start - _before;
  if (from <= 0) {
    from = 0;
  } else {
    // Start on a word boundary.
    final space = text.indexOf(' ', from);
    from = space == -1 || space >= start ? from : space + 1;
  }
  final to = (end + _after).clamp(end, text.length);
  final prefix = from > 0 ? '…' : '';
  final snippet =
      prefix +
      text.substring(from, to).replaceAll('\n', ' ') +
      (to < text.length ? '…' : '');
  return HadithSearchHit(
    book: book,
    section: section,
    languageCode: lang,
    number: e.number,
    snippet: snippet,
    matchStart: start == end ? 0 : start - from + prefix.length,
    matchEnd: start == end ? 0 : end - from + prefix.length,
  );
}

/// Bengali digits (০-৯) → ASCII, everything else unchanged.
String _asciiDigits(String s) => String.fromCharCodes([
  for (final c in s.runes) c >= 0x09E6 && c <= 0x09EF ? c - 0x09E6 + 0x30 : c,
]);
