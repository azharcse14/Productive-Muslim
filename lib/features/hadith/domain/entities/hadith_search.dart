import 'hadith_book.dart';

/// Results a full-collection search returns at most.
const hadithSearchLimit = 50;

/// One full-collection search match: where it lives (opened with
/// [languageCode]'s chapter list) and a snippet around the match.
final class HadithSearchHit {
  const HadithSearchHit({
    required this.book,
    required this.section,
    required this.languageCode,
    required this.number,
    required this.snippet,
    this.matchStart = 0,
    this.matchEnd = 0,
  });

  final HadithBook book;

  /// Chapter from `book.sectionsFor(languageCode)`.
  final HadithSection section;

  /// Language of the matched text ('en' or 'bn').
  final String languageCode;

  /// The number the hadith card shows ([BookHadith.referenceNumber]).
  final int number;

  final String snippet;

  /// Match range within [snippet]; empty (0, 0) for a number lookup.
  final int matchStart;
  final int matchEnd;
}

/// Up to [hadithSearchLimit] hits; [truncated] when more exist.
typedef HadithSearchResults = ({List<HadithSearchHit> hits, bool truncated});
