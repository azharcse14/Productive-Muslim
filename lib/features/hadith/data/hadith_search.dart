import '../domain/entities/hadith_book.dart';
import '../domain/entities/hadith_search.dart';

/// Full-collection hadith search over the bundled snapshot — the pure part
/// (sources, matching, snippets); hadith_search_worker.dart runs it.
///
/// hadith.db stores each section as one gzip blob (hadith_blob_codec.dart),
/// so there is no text column SQL `LIKE`/FTS could scan. Instead a worker
/// isolate decodes the English + Bangla text once (~30 M chars) and answers
/// each query with a [RegExp] scan of it.
// ponytail: in-memory linear scan; add an FTS5 table to hadith.db if
// queries ever get too slow on low-end phones (costs a DB rebuild + MBs).

/// One text source to load: fawazahmed0 edition [key] (`hb` false) or the
/// hadithbangla book id [key] (`hb` true), for book index [book], in Bangla
/// ([bn]) or English.
typedef HadithSearchSource = ({int book, String key, bool hb, bool bn});

/// What each book's reader shows per language: its English edition; for
/// Bangla, hadithbangla when the book uses it, else a distinct fawazahmed0
/// Bengali edition (none for English-only books).
List<HadithSearchSource> hadithSearchSources(List<HadithBook> books) => [
  for (final (i, b) in books.indexed) ...[
    (book: i, key: b.editionEn, hb: false, bn: false),
    if (b.usesBanglaSource('bn'))
      (book: i, key: b.id, hb: true, bn: true)
    else if (b.editionBn.isNotEmpty && b.editionBn != b.editionEn)
      (book: i, key: b.editionBn, hb: false, bn: true),
  ],
];

/// One searchable hadith text.
final class HadithSearchEntry {
  const HadithSearchEntry(
    this.book,
    this.section,
    this.number,
    this.text, {
    this.lookup = true,
  });

  /// Whether a number query may match [number] (false for internal numbers,
  /// see `RawHadith.hasStandardNumber`).
  final bool lookup;

  /// Book index (see [HadithSearchSource.book]).
  final int book;
  final int section;

  /// The number the hadith card shows (and the reader focuses on).
  final int number;
  final String text;
}

/// The decoded search text: English and Bangla entries, in catalog order.
final class HadithSearchCorpus {
  const HadithSearchCorpus(this.en, this.bn);

  final List<HadithSearchEntry> en;
  final List<HadithSearchEntry> bn;
}

/// A match as it crosses the isolate boundary; [toSearchHits] resolves it.
typedef HadithRawHit = ({
  int book,
  int section,
  bool bn,
  int number,
  String snippet,
  int start,
  int end,
});

typedef HadithRawResults = ({List<HadithRawHit> hits, bool truncated});

/// Searches [corpus] for [query]: an all-digit query (Bangla digits map to
/// ASCII) is a hadith-number lookup in each book's [languageCode] text (its
/// English when the book has no Bangla); anything else a substring match
/// (see [hadithQueryPattern]), [languageCode]'s text first. At most [limit].
HadithRawResults searchHadithCorpus(
  HadithSearchCorpus corpus,
  String query,
  String languageCode, {
  int limit = hadithSearchLimit,
}) {
  final q = normalizeHadithQuery(query);
  final hits = <HadithRawHit>[];
  if (q.isEmpty) {
    return (hits: hits, truncated: false);
  }
  final bnFirst = languageCode == 'bn';
  final ordered = bnFirst
      ? [(corpus.bn, true), (corpus.en, false)]
      : [(corpus.en, false), (corpus.bn, true)];
  final digits = _asciiDigits(q);
  final number = RegExp(r'^\d+$').hasMatch(digits)
      ? int.tryParse(digits)
      : null;
  final bnBooks = number == null
      ? const <int>{}
      : {for (final e in corpus.bn) e.book};
  final seen = <(int, int)>{};
  final pattern = hadithQueryPattern(q);
  for (final (entries, bn) in ordered) {
    for (final e in entries) {
      final HadithRawHit? hit;
      if (number != null) {
        // One language per book, so a number doesn't list every book twice;
        // one card per chapter (8a/8b share a number and open together).
        final wanted = bnFirst && bnBooks.contains(e.book);
        hit =
            e.lookup &&
                e.number == number &&
                bn == wanted &&
                seen.add((e.book, e.section))
            ? _hit(e, bn, 0, 0)
            : null;
      } else {
        final m = pattern.firstMatch(e.text);
        hit = m == null ? null : _hit(e, bn, m.start, m.end);
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

/// Resolves raw hits against [books]; a hit whose chapter the catalog
/// doesn't list (snapshot/catalog mismatch) is dropped — nothing to open.
List<HadithSearchHit> toSearchHits(
  List<HadithBook> books,
  List<HadithRawHit> raw,
) => [
  for (final r in raw)
    if (books[r.book]
            .sectionsFor(r.bn ? 'bn' : 'en')
            .where((s) => s.number == r.section)
            .firstOrNull
        case final section?)
      HadithSearchHit(
        book: books[r.book],
        section: section,
        languageCode: r.bn ? 'bn' : 'en',
        number: r.number,
        snippet: r.snippet,
        matchStart: r.start,
        matchEnd: r.end,
      ),
];

/// Bangla letters with two Unicode spellings in the source text
/// (precomposed vs. base + nukta / split vowel sign): each matches both.
const _bnForms = <String, String>{
  '\u09DF': '\u09AF\u09BC', // য়
  '\u09DC': '\u09A1\u09BC', // ড়
  '\u09DD': '\u09A2\u09BC', // ঢ়
  '\u09CB': '\u09C7\u09BE', // ো
  '\u09CC': '\u09C7\u09D7', // ৌ
};

const _virama = '\u09CD';

/// [query] as a literal pattern that tolerates the corpus's Unicode
/// variants: either spelling of each [_bnForms] letter, an optional ZWNJ/ZWJ
/// after a virama (where >99% of the source's mid-word joiners sit; allowing
/// one between every letter made Bangla scans ~10x slower), any apostrophe
/// for `'‘’`. Case-insensitive only when the query has cased letters.
RegExp hadithQueryPattern(String query) {
  final q = query.replaceAll(RegExp('[\u200C\u200D]'), '');
  final buf = StringBuffer();
  for (var i = 0; i < q.length; i++) {
    final c = q[i];
    String? token;
    for (final MapEntry(key: one, value: two) in _bnForms.entries) {
      if (c == one || q.startsWith(two, i)) {
        token = '(?:$one|$two)';
        if (c != one) {
          i++; // consumed the two-char spelling
        }
        break;
      }
    }
    buf.write(
      token ??
          switch (c) {
            "'" || '‘' || '’' => "['‘’]",
            _virama => '$_virama[\u200C\u200D]?',
            _ => RegExp.escape(c),
          },
    );
  }
  return RegExp(
    buf.toString(),
    caseSensitive: q.toLowerCase() == q.toUpperCase(),
  );
}

const _before = 60;
const _after = 120;

HadithRawHit _hit(HadithSearchEntry e, bool bn, int start, int end) {
  final text = e.text;
  // Keep a conjunct / trailing vowel signs inside the highlight.
  while (end > start && end < text.length && _continuesCluster(text, end)) {
    end++;
  }
  var from = start - _before;
  if (from <= 0) {
    from = 0;
  } else {
    final space = text.indexOf(' ', from);
    if (space != -1 && space < start) {
      from = space + 1;
    } else {
      while (from < start && _continuesCluster(text, from)) {
        from++;
      }
    }
  }
  var to = end + _after;
  if (to >= text.length) {
    to = text.length;
  } else {
    final space = text.lastIndexOf(' ', to);
    if (space > end) {
      to = space;
    } else {
      while (to < text.length && _continuesCluster(text, to)) {
        to++;
      }
    }
  }
  final prefix = from > 0 ? '…' : '';
  final snippet =
      prefix +
      text.substring(from, to).replaceAll(RegExp('[\r\n]'), ' ') +
      (to < text.length ? '…' : '');
  final empty = start == end;
  return (
    book: e.book,
    section: e.section,
    bn: bn,
    number: e.number,
    snippet: snippet,
    start: empty ? 0 : start - from + prefix.length,
    end: empty ? 0 : end - from + prefix.length,
  );
}

/// Whether [i] continues the cluster before it: a Bangla sign/vowel mark or
/// joiner, or any character after a virama (্).
bool _continuesCluster(String s, int i) {
  final c = s.codeUnitAt(i);
  return (c >= 0x0981 && c <= 0x0983) ||
      c == 0x09BC ||
      (c >= 0x09BE && c <= 0x09D7) ||
      c == 0x200C ||
      c == 0x200D ||
      (i > 0 && s.codeUnitAt(i - 1) == 0x09CD);
}

/// Bengali digits (০-৯) → ASCII, everything else unchanged.
String _asciiDigits(String s) => String.fromCharCodes([
  for (final c in s.runes) c >= 0x09E6 && c <= 0x09EF ? c - 0x09E6 + 0x30 : c,
]);
