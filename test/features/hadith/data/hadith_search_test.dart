import 'dart:io';
import 'dart:isolate';

import 'package:flutter_test/flutter_test.dart';
import 'package:productive_muslim/features/hadith/data/hadith_book_bundled_data_source.dart';
import 'package:productive_muslim/features/hadith/data/hadith_search.dart';
import 'package:productive_muslim/features/hadith/data/hadith_search_worker.dart';
import 'package:productive_muslim/features/hadith/data/hadith_section_assembler.dart';
import 'package:productive_muslim/features/hadith/domain/entities/hadith_book.dart';
import 'package:productive_muslim/features/hadith/domain/entities/hadith_search.dart';

import 'hadith_db_test_util.dart';

/// Bangla from hadithbangla (own chapter numbering).
const _bukhari = HadithBook(
  id: 'bukhari',
  en: 'Sahih al-Bukhari',
  bn: 'সহিহ বুখারি',
  author: '',
  kind: 'sahih',
  total: 2,
  editionAr: 'ara-bukhari',
  editionEn: 'eng-bukhari',
  editionBn: 'ben-bukhari',
  bnFolder: 'Bukhari',
  sections: [HadithSection(number: 1, name: 'Revelation', first: 1, last: 3)],
  bnSections: [HadithSection(number: 5, name: 'ওহী', first: 1, last: 1)],
);

/// Bangla from a fawazahmed0 edition (same numbering as English).
const _malik = HadithBook(
  id: 'malik',
  en: 'Muwatta Malik',
  bn: 'মুওয\u09BCাত্তা মালিক',
  author: '',
  kind: 'graded',
  total: 1,
  editionAr: 'ara-malik',
  editionEn: 'eng-malik',
  editionBn: 'ben-malik',
  sections: [HadithSection(number: 1, name: 'Prayer', first: 10, last: 10)],
);

/// English only.
const _qudsi = HadithBook(
  id: 'qudsi',
  en: '40 Hadith Qudsi',
  bn: '',
  author: '',
  kind: 'graded',
  total: 1,
  editionAr: 'ara-qudsi',
  editionEn: 'eng-qudsi',
  editionBn: 'eng-qudsi',
  bnAvailable: false,
  sections: [HadithSection(number: 1, name: 'Qudsi', first: 1, last: 1)],
);

const _books = [_bukhari, _malik, _qudsi];

RawHadith _raw(int n, String text, [String ref = '']) =>
    RawHadith(number: n, text: text, grade: '', ref: ref);

/// Seeds an on-disk snapshot and returns its path.
Future<String> _seed({bool withBangla = true}) async {
  final dir = Directory.systemTemp.createTempSync('hadith_search');
  addTearDown(() => dir.deleteSync(recursive: true));
  final file = File('${dir.path}/hadith.db');
  final db = await openTestHadithDb(withBangla: withBangla, file: file);
  await putFaSection(
    db,
    edition: 'eng-bukhari',
    section: 1,
    hadiths: [
      _raw(1, 'Actions are judged by intentions.'),
      _raw(2, 'The PRAYER is light.'),
      _raw(3, 'He gave 100% of it.'),
      _raw(4, 'He gave 1000 of it.'),
    ],
  );
  // Never searched: Bukhari's Bangla comes from hadithbangla.
  await putFaSection(
    db,
    edition: 'ben-bukhari',
    section: 1,
    hadiths: [_raw(1, 'নামাজ বেন-বুখারি')],
  );
  await putFaSection(
    db,
    edition: 'eng-malik',
    section: 1,
    hadiths: [_raw(10, 'The prayer of a man alone.', '7')],
  );
  await putFaSection(
    db,
    edition: 'ben-malik',
    section: 1,
    hadiths: [_raw(10, 'একা ব্যক্তির নামাজ', '7')],
  );
  await putFaSection(
    db,
    edition: 'eng-qudsi',
    section: 1,
    hadiths: [_raw(1, 'Allah said: My servant.')],
  );
  if (withBangla) {
    await putBnSection(
      db,
      bookId: 'bukhari',
      section: 5,
      hadiths: const [
        BnHadith(
          number: 1,
          arabic: '',
          bn: 'সকল কাজ নিয\u09BCতের উপর নির্ভরশীল। নামাজ',
          narrator: '',
          grade: '',
        ),
      ],
    );
  }
  await db.close();
  return file.path;
}

/// Spawns the real search worker over [path] for [books].
Future<HadithSearchIndex> _open(String path, List<HadithBook> books) async {
  final index = await HadithBookBundledDataSource(
    () => throw UnimplementedError(),
    dbPath: () async => path,
  ).openSearch(books);
  addTearDown(index.close);
  return index;
}

Future<List<HadithSearchHit>> _search(
  HadithSearchIndex index,
  List<HadithBook> books,
  String query,
  String lang,
) async => toSearchHits(
  books,
  (await index.search(query, lang, hadithSearchLimit)).hits,
);

/// Pure search over Bangla [bn] (and English [en]) texts, Bangla UI.
HadithRawResults _find(
  List<String> bn,
  String q, {
  List<String> en = const [],
}) => searchHadithCorpus(
  HadithSearchCorpus(
    [for (final (i, t) in en.indexed) HadithSearchEntry(0, 1, i, t)],
    [for (final (i, t) in bn.indexed) HadithSearchEntry(0, 1, i, t)],
  ),
  q,
  'bn',
);

void main() {
  group('worker over a seeded snapshot', () {
    late HadithSearchIndex index;

    setUp(() async => index = await _open(await _seed(), _books));

    test(
      'English match is case-insensitive, with snippet and chapter',
      () async {
        final hits = await _search(index, _books, 'prayer', 'en');
        expect(
          [for (final h in hits) (h.book.id, h.number, h.languageCode)],
          [
            ('bukhari', 2, 'en'),
            ('malik', 7, 'en'), // the displayed reference number, not 10
          ],
        );
        final first = hits.first;
        expect(first.section.name, 'Revelation');
        expect(
          first.snippet.substring(first.matchStart, first.matchEnd),
          'PRAYER',
        );
      },
    );

    test('wildcard characters match literally', () async {
      final hits = await _search(index, _books, '100%', 'en');
      expect([for (final h in hits) h.number], [3]);
      expect(await _search(index, _books, 'g.ve', 'en'), isEmpty);
    });

    test("each book's own Bangla source, Bangla UI first", () async {
      final hits = await _search(index, _books, 'নামাজ', 'bn');
      expect(
        [
          for (final h in hits)
            (h.book.id, h.section.number, h.number, h.languageCode),
        ],
        [('bukhari', 5, 1, 'bn'), ('malik', 1, 7, 'bn')],
      );
      expect(hits.first.section.name, 'ওহী'); // hadithbangla chapter
    });

    test('a Bangla-digit number is a lookup, one language per book', () async {
      final bn = await _search(index, _books, '১', 'bn');
      expect(
        [for (final h in bn) (h.book.id, h.languageCode, h.matchEnd)],
        [('bukhari', 'bn', 0), ('qudsi', 'en', 0)],
      );
      final en = await _search(index, _books, '7', 'en');
      expect([for (final h in en) h.book.id], ['malik']);
    });

    test('caps results and reports truncation', () async {
      final r = await index.search('e', 'en', 2);
      expect(r.hits, hasLength(2));
      expect(r.truncated, isTrue);
    });

    test('blank query finds nothing', () async {
      expect(await _search(index, _books, '  ', 'en'), isEmpty);
    });
  });

  test('loads without the hadithbangla table', () async {
    final books = [_bukhari.withoutBanglaSource(), _malik];
    final index = await _open(await _seed(withBangla: false), books);
    final hits = await _search(index, books, 'নামাজ', 'bn');
    expect([for (final h in hits) h.book.id], ['malik']);
  });

  test('a worker that dies fails searches instead of hanging', () async {
    final worker = await HadithSearchWorker.spawn(
      await _seed(),
      hadithSearchSources(_books),
    );
    addTearDown(worker.close);
    expect((await worker.search('prayer', 'en', 50)).hits, isNotEmpty);

    worker.isolate.kill(priority: Isolate.immediate); // simulated crash
    await expectLater(worker.search('prayer', 'en', 50), throwsStateError);
    expect(worker.alive, isFalse);
    await expectLater(worker.search('prayer', 'en', 50), throwsStateError);
  });

  test('a missing database fails the spawn', () async {
    await expectLater(
      HadithSearchWorker.spawn('/no/such/dir/hadith.db', const []),
      throwsStateError,
    );
  });

  group('matching', () {
    test('Bangla letters match across Unicode spellings', () {
      // Query precomposed য় vs corpus য+়, and the reverse.
      expect(_find(['সে নিয\u09BCত করল'], 'নি\u09DFত').hits, hasLength(1));
      expect(_find(['সে নি\u09DFত করল'], 'নিয\u09BCত').hits, hasLength(1));
      // ো split as ে + া; ড় as ড + ়.
      expect(_find(['বোঝা'], 'বোঝা').hits, hasLength(1));
      expect(_find(['পড\u09BCা'], 'প\u09DCা').hits, hasLength(1));
    });

    test('a joiner after a virama is optional; query joiners ignored', () {
      final h = _find(['নবী চাশ্\u200Cতের নামাজ'], 'চাশ্তের').hits.single;
      expect(h.snippet.substring(h.start, h.end), 'চাশ্\u200Cতের');
      expect(_find(['নামাজ'], 'না\u200Dমাজ').hits, hasLength(1));
    });

    test('apostrophes match any quote style', () {
      final r = _find(const [], "prophet's", en: ['The Prophet’s mosque']);
      expect(r.hits, hasLength(1));
    });

    test('long text: word-aligned snippet, highlight keeps a conjunct', () {
      final lead = List.filled(30, 'শব্দ').join(' ');
      final tail = List.filled(40, 'আর').join(' ');
      final h = _find(['$lead\r\nতারপর সত্যকথা বলো $tail'], 'সত').hits.single;
      expect(h.snippet, startsWith('…'));
      expect(h.snippet[1], isNot(' '));
      expect(h.snippet, isNot(contains('\r')));
      expect(h.snippet, isNot(contains('\n')));
      // সত + ্য: the highlight runs through the virama conjunct.
      expect(h.snippet.substring(h.start, h.end), 'সত্য');
      expect(h.snippet, endsWith('আর…'));
    });

    test('a long run without spaces is not cut mid-cluster', () {
      final h = _find(['${'ক্ষ' * 40}নামাজ'], 'নামাজ').hits.single;
      // After the ellipsis comes a whole cluster: ক, not ্ or ষ.
      expect(h.snippet[1], 'ক');
      expect(h.snippet.substring(h.start, h.end), 'নামাজ');
    });

    test('number hits are one per chapter', () {
      const corpus = HadithSearchCorpus([
        HadithSearchEntry(0, 1, 8, '8a'),
        HadithSearchEntry(0, 1, 8, '8b'),
        HadithSearchEntry(0, 2, 8, '8c'),
      ], []);
      expect(searchHadithCorpus(corpus, '8', 'en').hits, hasLength(2));
    });

    test('internal numbers match text but not a number lookup', () {
      const corpus = HadithSearchCorpus([
        HadithSearchEntry(0, 1, 1220, 'standard'),
        HadithSearchEntry(0, 9, 1220, 'internal', lookup: false),
      ], []);
      final byNumber = searchHadithCorpus(corpus, '1220', 'en').hits;
      expect(byNumber.map((h) => h.section), [1]);
      expect(searchHadithCorpus(corpus, 'internal', 'en').hits, hasLength(1));
    });
  });
}
