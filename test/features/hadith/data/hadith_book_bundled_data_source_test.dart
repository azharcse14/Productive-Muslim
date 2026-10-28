import 'package:flutter_test/flutter_test.dart';
import 'package:productive_muslim/features/hadith/data/hadith_book_bundled_data_source.dart';
import 'package:productive_muslim/features/hadith/data/hadith_database.dart';
import 'package:productive_muslim/features/hadith/data/hadith_section_assembler.dart';
import 'package:productive_muslim/features/hadith/domain/entities/hadith_book.dart';

import 'hadith_db_test_util.dart';

HadithBook _book({
  required String id,
  String kind = 'sahih',
  String bnFolder = '',
  List<HadithSection> bnSections = const [],
}) =>
    HadithBook(
      id: id,
      en: 'Sahih al-$id',
      bn: 'বুক-$id',
      author: 'Author',
      kind: kind,
      total: 10,
      editionAr: 'ara-$id',
      editionEn: 'eng-$id',
      editionBn: 'ben-$id',
      sections: const [
        HadithSection(number: 1, name: 'Revelation', first: 1, last: 2),
      ],
      bnFolder: bnFolder,
      bnSections: bnSections,
    );

const _section = HadithSection(number: 1, name: 'Revelation', first: 1, last: 2);

RawHadith _r(int n, String t, [String g = '']) =>
    RawHadith(number: n, text: t, grade: g);

void main() {
  late HadithDatabase db;
  late HadithBookBundledDataSource source;

  setUp(() async {
    db = await openTestHadithDb();
    source = HadithBookBundledDataSource(() => Future.value(db));
  });

  tearDown(() async => db.close());

  test('zips Arabic with English translation, in source order', () async {
    await putFaSection(db,
        edition: 'ara-bukhari',
        section: 1,
        hadiths: [_r(1, 'ar-1'), _r(2, 'ar-2')]);
    await putFaSection(db,
        edition: 'eng-bukhari',
        section: 1,
        hadiths: [_r(1, 'en-1'), _r(2, 'en-2')]);

    final items =
        await source.fetchSection(_book(id: 'bukhari'), _section, 'en');

    expect(items, hasLength(2));
    expect(items.first.number, 1);
    expect(items.first.arabic, 'ar-1');
    expect(items.first.translation, 'en-1');
    expect(items.first.reference, 'Sahih al-bukhari 1');
    // A sahih book with no per-hadith grade is labelled "Sahih".
    expect(items.first.grade, 'Sahih');
  });

  test('stored grade is surfaced for graded books', () async {
    await putFaSection(db,
        edition: 'ara-tirmidhi',
        section: 1,
        hadiths: [_r(1, 'ar-1', 'Hasan')]);
    await putFaSection(db,
        edition: 'eng-tirmidhi', section: 1, hadiths: [_r(1, 'en-1')]);

    final items = await source.fetchSection(
        _book(id: 'tirmidhi', kind: 'graded'), _section, 'en');
    expect(items.first.grade, 'Hasan');
  });

  test('falls back to English when the Bengali edition lacks a hadith',
      () async {
    await putFaSection(db,
        edition: 'ara-bukhari',
        section: 1,
        hadiths: [_r(1, 'ar-1'), _r(2, 'ar-2')]);
    await putFaSection(db,
        edition: 'eng-bukhari',
        section: 1,
        hadiths: [_r(1, 'en-1'), _r(2, 'en-2')]);
    // ben edition only has #2.
    await putFaSection(db,
        edition: 'ben-bukhari', section: 1, hadiths: [_r(2, 'bn-2')]);

    // A bn locale on a book with no hadithbangla folder uses the ben-* edition.
    final items =
        await source.fetchSection(_book(id: 'bukhari'), _section, 'bn');

    expect(items.first.translation, 'en-1'); // #1 missing in bn -> English
    expect(items.first.fallbackTranslation, isTrue);
    expect(items[1].translation, 'bn-2');
    expect(items[1].fallbackTranslation, isFalse);
  });

  test('bn on a hadithbangla book reads the Bengali chapter table', () async {
    await putBnSection(db, bookId: 'nasai', section: 1, hadiths: const [
      BnHadith(
          number: 1,
          arabic: 'عربي',
          bn: 'বাংলা ১',
          narrator: 'আনাস',
          grade: 'সহিহ হাদিস'),
      BnHadith(number: 2, arabic: '', bn: 'বাংলা ২', narrator: '', grade: ''),
    ]);

    final nasai = _book(
      id: 'nasai',
      kind: 'graded',
      bnFolder: 'Al-Nasai',
      bnSections: const [_section],
    );
    final items = await source.fetchSection(nasai, _section, 'bn');

    expect(items, hasLength(2));
    expect(items.first.translation, 'বাংলা ১');
    expect(items.first.narrator, 'আনাস');
    expect(items.first.grade, 'সহিহ হাদিস');
    expect(items.first.reference, 'বুক-nasai 1');
    // Empty stored grade on a graded book stays empty.
    expect(items[1].grade, '');
  });

  test('a missing section returns empty (so the repo can fall back)', () async {
    final items =
        await source.fetchSection(_book(id: 'bukhari'), _section, 'en');
    expect(items, isEmpty);
  });
}
