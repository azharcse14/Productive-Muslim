import 'package:flutter_test/flutter_test.dart';
import 'package:productive_muslim/features/hadith/data/hadith_section_assembler.dart';
import 'package:productive_muslim/features/hadith/domain/entities/hadith_book.dart';

HadithBook _book({String kind = 'sahih'}) => HadithBook(
      id: 'bukhari',
      en: 'Sahih al-Bukhari',
      bn: 'সহিহ বুখারি',
      author: 'al-Bukhari',
      kind: kind,
      total: 7563,
      editionAr: 'ara-bukhari',
      editionEn: 'eng-bukhari',
      editionBn: 'ben-bukhari',
      sections: const [],
    );

void main() {
  group('RawHadith.parse', () {
    test('reads number + trimmed text + first grade', () {
      final h = RawHadith.parse({
        'hadithnumber': 5,
        'text': '  hello  ',
        'grades': [
          {'name': 'Other', 'grade': 'Hasan'},
          {'name': 'Al-Albani', 'grade': 'Sahih'},
        ],
      });
      expect(h, isNotNull);
      expect(h!.number, 5);
      expect(h.text, 'hello');
      expect(h.grade, 'Sahih'); // Al-Albani preferred over the earlier entry
    });

    test('returns null on malformed entries', () {
      expect(RawHadith.parse('nope'), isNull);
      expect(RawHadith.parse({'hadithnumber': 1}), isNull);
      expect(RawHadith.parse({'text': 'x'}), isNull);
    });

    test('firstGrade falls back to the first available grade', () {
      expect(
        RawHadith.firstGrade([
          {'name': 'A', 'grade': ''},
          {'name': 'B', 'grade': 'Daif'},
        ]),
        'Daif',
      );
      expect(RawHadith.firstGrade(const []), '');
      expect(RawHadith.firstGrade(null), '');
    });
  });

  group('BnHadith.parse', () {
    test('reads a flat entry', () {
      final h = BnHadith.parse({
        'hadith_id': 3,
        'ar': ' عربي ',
        'bn': ' বাংলা ',
        'narrator': 'আনাস',
        'grade': 'সহিহ',
      });
      expect(h!.number, 3);
      expect(h.arabic, 'عربي');
      expect(h.bn, 'বাংলা');
      expect(h.narrator, 'আনাস');
    });

    test('unwraps a {hadith: {...}} envelope', () {
      final h = BnHadith.parse({
        'hadith': {'hadith_id': 9, 'bn': 'x'},
      });
      expect(h!.number, 9);
      expect(h.bn, 'x');
    });

    test('returns null without a bn body', () {
      expect(BnHadith.parse({'hadith_id': 1}), isNull);
    });
  });

  group('assembleSection', () {
    RawHadith r(int n, String t, [String g = '']) =>
        RawHadith(number: n, text: t, grade: g);

    test('English path: zips by number, labels sahih when ungraded', () {
      final items = assembleSection(
        book: _book(),
        arabic: [r(1, 'ar1'), r(2, 'ar2')],
        translation: [r(1, 'en1'), r(2, 'en2')],
        englishFallback: const [],
        translationIsEnglish: true,
      );
      expect(items.map((h) => h.translation), ['en1', 'en2']);
      expect(items.first.grade, 'Sahih');
      expect(items.first.fallbackTranslation, isFalse);
      expect(items.first.reference, 'Sahih al-Bukhari 1');
    });

    test('non-English path falls back to English for gaps', () {
      final items = assembleSection(
        book: _book(kind: 'graded'),
        arabic: [r(1, 'ar1'), r(2, 'ar2')],
        translation: [r(2, 'bn2')], // only #2 translated
        englishFallback: [r(1, 'en1'), r(2, 'en2')],
        translationIsEnglish: false,
      );
      expect(items.first.translation, 'en1');
      expect(items.first.fallbackTranslation, isTrue);
      expect(items[1].translation, 'bn2');
      expect(items[1].fallbackTranslation, isFalse);
      // graded + no stored grade -> empty, not "Sahih".
      expect(items.first.grade, '');
    });
  });

  group('assembleBangla', () {
    test('maps fields and defaults the grade for sahih books', () {
      final items = assembleBangla(_book(), const [
        BnHadith(
            number: 1, arabic: 'a', bn: 'b', narrator: 'n', grade: ''),
      ]);
      expect(items.first.translation, 'b');
      expect(items.first.narrator, 'n');
      expect(items.first.grade, 'সহিহ'); // sahih default
      expect(items.first.reference, 'সহিহ বুখারি 1');
    });
  });
}
