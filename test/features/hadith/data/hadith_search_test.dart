import 'package:flutter_test/flutter_test.dart';
import 'package:productive_muslim/features/hadith/data/hadith_book_bundled_data_source.dart';
import 'package:productive_muslim/features/hadith/data/hadith_database.dart';
import 'package:productive_muslim/features/hadith/data/hadith_search.dart';
import 'package:productive_muslim/features/hadith/data/hadith_section_assembler.dart';
import 'package:productive_muslim/features/hadith/domain/entities/hadith_book.dart';

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
  bn: 'মুওয়াত্তা মালিক',
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

Future<HadithDatabase> _seed({bool withBangla = true}) async {
  final db = await openTestHadithDb(withBangla: withBangla);
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
          bn: 'সকল কাজ নিয়তের উপর নির্ভরশীল। নামাজ',
          narrator: '',
          grade: '',
        ),
      ],
    );
  }
  return db;
}

void main() {
  group('with the full snapshot', _fullSnapshot);

  test('loads without the hadithbangla table', () async {
    final noBn = await _seed(withBangla: false);
    addTearDown(noBn.close);
    final c = await HadithBookBundledDataSource(
      () async => noBn,
    ).loadSearchCorpus([_bukhari.withoutBanglaSource(), _malik]);
    expect(
      [for (final h in searchHadithCorpus(c, 'নামাজ', 'bn').hits) h.book.id],
      ['malik'],
    );
  });
}

void _fullSnapshot() {
  late HadithDatabase db;
  late HadithSearchCorpus corpus;

  setUp(() async {
    db = await _seed();
    corpus = await HadithBookBundledDataSource(
      () async => db,
    ).loadSearchCorpus(_books);
  });

  tearDown(() => db.close());

  test('English match is case-insensitive, with snippet and chapter', () {
    final r = searchHadithCorpus(corpus, 'prayer', 'en');
    expect(r.truncated, isFalse);
    expect(
      [for (final h in r.hits) (h.book.id, h.number, h.languageCode)],
      [
        ('bukhari', 2, 'en'),
        ('malik', 7, 'en'), // the displayed reference number, not 10
      ],
    );
    final first = r.hits.first;
    expect(first.section.name, 'Revelation');
    expect(first.snippet.substring(first.matchStart, first.matchEnd), 'PRAYER');
  });

  test('wildcard characters match literally', () {
    final r = searchHadithCorpus(corpus, '100%', 'en');
    expect([for (final h in r.hits) h.number], [3]);
    expect(searchHadithCorpus(corpus, '.', 'en').hits, isNotEmpty);
    expect(searchHadithCorpus(corpus, 'g.ve', 'en').hits, isEmpty);
  });

  test('Bangla text: each book\'s own Bangla source, Bangla UI first', () {
    final r = searchHadithCorpus(corpus, 'নামাজ', 'bn');
    expect(
      [
        for (final h in r.hits)
          (h.book.id, h.section.number, h.number, h.languageCode),
      ],
      [('bukhari', 5, 1, 'bn'), ('malik', 1, 7, 'bn')],
    );
    expect(r.hits.first.section.name, 'ওহী'); // hadithbangla chapter
  });

  test('a Bangla-digit number looks the hadith up, one language per book', () {
    final r = searchHadithCorpus(corpus, '১', 'bn');
    expect(
      [for (final h in r.hits) (h.book.id, h.languageCode, h.matchEnd)],
      [('bukhari', 'bn', 0), ('qudsi', 'en', 0)],
    );
    expect(
      [for (final h in searchHadithCorpus(corpus, '7', 'en').hits) h.book.id],
      ['malik'],
    );
  });

  test('caps results and reports truncation', () {
    final r = searchHadithCorpus(corpus, 'e', 'en', limit: 2);
    expect(r.hits, hasLength(2));
    expect(r.truncated, isTrue);
  });

  test('blank query finds nothing', () {
    expect(searchHadithCorpus(corpus, '  ', 'en').hits, isEmpty);
  });
}
