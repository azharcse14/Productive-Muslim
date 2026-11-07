import 'package:flutter_test/flutter_test.dart';
import 'package:productive_muslim/features/hadith/data/hadith_blob_codec.dart';
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

    test(
      'standardRef maps upstream arabicnumber to a sunnah.com-style ref',
      () {
        expect(RawHadith.standardRef('8.01', 93), '8a');
        expect(RawHadith.standardRef('8.02', 94), '8b');
        expect(RawHadith.standardRef('9', 98), '9');
        expect(RawHadith.standardRef('5', 5), ''); // already standard
        expect(RawHadith.standardRef(7, 7), '');
        // A sub-narration keeps its sub-number, so it reads apart from 402.
        expect(RawHadith.standardRef(402.2, 402.2), '402.2');
        expect(RawHadith.standardRef(3604.02, 3604.02), '3604.02');
        expect(RawHadith.standardRef(null, 3), '');
        final h = RawHadith.parse({
          'hadithnumber': 93,
          'arabicnumber': '8.01',
          'text': 'x',
        });
        expect(h!.ref, '8a');
      },
    );

    test('a decimal hadithnumber keeps its sub-number in the reference', () {
      final h = RawHadith.parse({
        'hadithnumber': 402.2,
        'arabicnumber': 402.2,
        'text': 'as above',
      })!;
      expect(h.number, 402);
      expect(h.ref, '402.2');
      expect(h.referenceNumber, 402); // "go to 402" still finds it
    });

    test('a "#n" reference (no standard number) looks up n', () {
      const h = RawHadith(number: 1220, text: 'x', grade: '', ref: '#1220');
      expect(h.referenceNumber, 1220);
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

    test('repeated hadith numbers pair by occurrence, not the last one', () {
      // Upstream shape of e.g. Tirmidhi 815: two narrations share number 815.
      final items = assembleSection(
        book: _book(kind: 'graded'),
        arabic: [r(814, 'ar0'), r(815, 'arA'), r(815, 'arB'), r(816, 'ar2')],
        translation: [
          r(814, 'en0'),
          r(815, 'enA'),
          r(815, 'enB'),
          r(816, 'en2'),
        ],
        englishFallback: const [],
        translationIsEnglish: true,
      );
      expect(items.map((h) => h.translation), ['en0', 'enA', 'enB', 'en2']);
    });

    test(
      'repeated numbers also pair by occurrence in the English fallback',
      () {
        final items = assembleSection(
          book: _book(kind: 'graded'),
          arabic: [r(7, 'arA'), r(7, 'arB')],
          translation: const [],
          englishFallback: [r(7, 'enA'), r(7, 'enB')],
          translationIsEnglish: false,
        );
        expect(items.map((h) => h.translation), ['enA', 'enB']);
      },
    );

    test('reference prefers the standard ref over the sequential number', () {
      final items = assembleSection(
        book: _book(),
        arabic: const [
          RawHadith(number: 93, text: 'ar', grade: '', ref: '8a'),
          RawHadith(number: 98, text: 'ar', grade: ''),
        ],
        translation: [r(93, 'en'), r(98, 'en')],
        englishFallback: const [],
        translationIsEnglish: true,
      );
      expect(items.map((h) => h.reference), [
        'Sahih al-Bukhari 8a',
        'Sahih al-Bukhari 98',
      ]);
      expect(items.first.number, 93); // navigation number unchanged
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

    test('skips entries blank everywhere; keeps one-language ones', () {
      final items = assembleSection(
        book: _book(kind: 'graded'),
        arabic: [r(1, ''), r(2, 'ar2'), r(3, ''), r(4, 'ar4')],
        translation: [r(1, ''), r(2, ''), r(3, 'bn3'), r(4, 'bn4')],
        englishFallback: [r(1, ''), r(2, ''), r(3, ''), r(4, '')],
        translationIsEnglish: false,
      );
      // #1 has no text at all; #2 is Arabic-only, #3 translation-only.
      expect(items.map((h) => h.number), [2, 3, 4]);
      // Occurrence pairing is not thrown off by the skipped entry.
      expect(items.map((h) => h.translation), ['', 'bn3', 'bn4']);
    });
  });

  test(
    'edition blob round-trips the standard ref (and omits it when empty)',
    () {
      final out = decodeEditionBlob(
        encodeEditionBlob(const [
          RawHadith(number: 93, text: 't', grade: 'g', ref: '8a'),
          RawHadith(number: 98, text: 't', grade: ''),
        ]),
      );
      expect(out.map((h) => h.ref), ['8a', '']);
      expect(out.map((h) => h.number), [93, 98]);
    },
  );

  group('assembleBangla', () {
    test('maps fields and defaults the grade for sahih books', () {
      final items = assembleBangla(_book(), const [
        BnHadith(number: 1, arabic: 'a', bn: 'b', narrator: 'n', grade: ''),
      ]);
      expect(items.first.translation, 'b');
      expect(items.first.narrator, 'n');
      expect(items.first.grade, 'সহিহ'); // sahih default
      expect(items.first.reference, 'সহিহ বুখারি 1');
    });

    test('skips an entry with neither Arabic nor Bangla text', () {
      final items = assembleBangla(_book(), const [
        BnHadith(number: 1, arabic: '', bn: '', narrator: 'n', grade: ''),
        BnHadith(number: 2, arabic: 'a', bn: '', narrator: '', grade: ''),
      ]);
      expect(items.map((h) => h.number), [2]);
    });
  });
}
