import 'package:flutter_test/flutter_test.dart';
import 'package:productive_muslim/features/quran/domain/entities/ayah.dart';
import 'package:productive_muslim/features/quran/domain/entities/surah.dart';

Surah _surah(int id, String arabic) => Surah(
  id: id,
  nameArabic: arabic,
  transliteration: '',
  translationEn: '',
  ayahCount: 1,
  revelation: 'meccan',
);

void main() {
  // Names as stored in assets/data/quran.db (with the dagger alef).
  final all = [
    _surah(2, 'البَقَرَةِ'),
    _surah(3, 'اٰلِ عِمْرٰنَ'),
    _surah(100, 'العٰدِيٰتِ'),
    _surah(55, 'الرَّحْمٰنِ'),
    _surah(20, 'طٰهٰ'),
  ];

  test('dagger-alef names match their usual typed spelling', () {
    expect(filterSurahs(all, 'آل عمران').map((s) => s.id), [3]);
    expect(filterSurahs(all, 'العاديات').map((s) => s.id), [100]);
    expect(filterSurahs(all, 'البقرة').map((s) => s.id), [2]);
    // ...and still match when typed without it.
    expect(filterSurahs(all, 'الرحمن').map((s) => s.id), [55]);
    expect(filterSurahs(all, 'طه').map((s) => s.id), [20]);
  });

  group('Bengali', () {
    const yasin = Surah(
      id: 36,
      nameArabic: 'يٰسٓ',
      transliteration: 'Yaseen',
      translationEn: 'Yaseen',
      ayahCount: 83,
      revelation: 'meccan',
      nameBn: 'ইয়াসীন',
      meaningBn: 'ইয়াসীন',
    );
    const naml = Surah(
      id: 27,
      nameArabic: 'النمل',
      transliteration: 'An-Naml',
      translationEn: 'The Ant',
      ayahCount: 93,
      revelation: 'meccan',
      nameBn: 'নম্‌ল',
      meaningBn: 'পিপীলিকা',
    );
    const index = [yasin, naml];

    test('search matches the Bengali name and meaning, loosely spelled', () {
      expect(filterSurahs(index, 'ইয়াসিন'), [yasin]); // ি for ী
      expect(filterSurahs(index, 'নমল'), [naml]); // no hasanta / ZWNJ
      expect(filterSurahs(index, 'পিপীলিকা'), [naml]);
      expect(filterSurahs(index, 'হাতি'), isEmpty);
      // Bengali digits are still a surah number.
      expect(filterSurahs(index, '২৭'), [naml]);
    });

    test('nameFor / meaningFor pick the UI language, with fallback', () {
      expect(naml.nameFor('bn'), 'নম্‌ল');
      expect(naml.nameFor('en'), 'An-Naml');
      expect(naml.meaningFor('bn'), 'পিপীলিকা');
      expect(naml.meaningFor('en'), 'The Ant');
      expect(_surah(1, '').nameFor('bn'), ''); // no Bengali: transliteration
      expect(_surah(1, '').meaningFor('bn'), isNull);
    });
  });

  test('parseAyahReference reads surah:ayah within the surah', () {
    const baqara = Surah(
      id: 2,
      nameArabic: '',
      transliteration: '',
      translationEn: '',
      ayahCount: 286,
      revelation: 'medinan',
    );
    const index = [baqara];
    expect(parseAyahReference(index, '2:255'), const QuranPosition(2, 255));
    expect(parseAyahReference(index, ' ২ : ২৫৫ '), const QuranPosition(2, 255));
    expect(parseAyahReference(index, '2.286'), const QuranPosition(2, 286));
    expect(parseAyahReference(index, '2/1'), const QuranPosition(2, 1));
    expect(parseAyahReference(index, '2:287'), isNull); // past the surah
    expect(parseAyahReference(index, '2:0'), isNull);
    expect(parseAyahReference(index, '3:1'), isNull); // unknown surah
    expect(parseAyahReference(index, '2'), isNull);
    expect(parseAyahReference(index, 'baqara'), isNull);
  });
}
