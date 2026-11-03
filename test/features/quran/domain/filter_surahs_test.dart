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
