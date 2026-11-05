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

  // Transliteration and English name of every surah, as stored in
  // assets/data/quran.db (in id order).
  const names = [
    ("Al-Faatiha", "The Opening"),
    ("Al-Baqara", "The Cow"),
    ("Aal-i-Imraan", "The Family of Imraan"),
    ("An-Nisaa", "The Women"),
    ("Al-Maaida", "The Table"),
    ("Al-An'aam", "The Cattle"),
    ("Al-A'raaf", "The Heights"),
    ("Al-Anfaal", "The Spoils of War"),
    ("At-Tawba", "The Repentance"),
    ("Yunus", "Jonas"),
    ("Hud", "Hud"),
    ("Yusuf", "Joseph"),
    ("Ar-Ra'd", "The Thunder"),
    ("Ibrahim", "Abraham"),
    ("Al-Hijr", "The Rock"),
    ("An-Nahl", "The Bee"),
    ("Al-Israa", "The Night Journey"),
    ("Al-Kahf", "The Cave"),
    ("Maryam", "Mary"),
    ("Taa-Haa", "Taa-Haa"),
    ("Al-Anbiyaa", "The Prophets"),
    ("Al-Hajj", "The Pilgrimage"),
    ("Al-Muminoon", "The Believers"),
    ("An-Noor", "The Light"),
    ("Al-Furqaan", "The Criterion"),
    ("Ash-Shu'araa", "The Poets"),
    ("An-Naml", "The Ant"),
    ("Al-Qasas", "The Stories"),
    ("Al-Ankaboot", "The Spider"),
    ("Ar-Room", "The Romans"),
    ("Luqman", "Luqman"),
    ("As-Sajda", "The Prostration"),
    ("Al-Ahzaab", "The Clans"),
    ("Saba", "Sheba"),
    ("Faatir", "The Originator"),
    ("Yaseen", "Yaseen"),
    ("As-Saaffaat", "Those drawn up in Ranks"),
    ("Saad", "The letter Saad"),
    ("Az-Zumar", "The Groups"),
    ("Ghafir", "The Forgiver"),
    ("Fussilat", "Explained in detail"),
    ("Ash-Shura", "Consultation"),
    ("Az-Zukhruf", "Ornaments of gold"),
    ("Ad-Dukhaan", "The Smoke"),
    ("Al-Jaathiya", "Crouching"),
    ("Al-Ahqaf", "The Dunes"),
    ("Muhammad", "Muhammad"),
    ("Al-Fath", "The Victory"),
    ("Al-Hujuraat", "The Inner Apartments"),
    ("Qaaf", "The letter Qaaf"),
    ("Adh-Dhaariyat", "The Winnowing Winds"),
    ("At-Tur", "The Mount"),
    ("An-Najm", "The Star"),
    ("Al-Qamar", "The Moon"),
    ("Ar-Rahmaan", "The Beneficent"),
    ("Al-Waaqia", "The Inevitable"),
    ("Al-Hadid", "The Iron"),
    ("Al-Mujaadila", "The Pleading Woman"),
    ("Al-Hashr", "The Exile"),
    ("Al-Mumtahana", "She that is to be examined"),
    ("As-Saff", "The Ranks"),
    ("Al-Jumu'a", "Friday"),
    ("Al-Munaafiqoon", "The Hypocrites"),
    ("At-Taghaabun", "Mutual Disillusion"),
    ("At-Talaaq", "Divorce"),
    ("At-Tahrim", "The Prohibition"),
    ("Al-Mulk", "The Sovereignty"),
    ("Al-Qalam", "The Pen"),
    ("Al-Haaqqa", "The Reality"),
    ("Al-Ma'aarij", "The Ascending Stairways"),
    ("Nooh", "Noah"),
    ("Al-Jinn", "The Jinn"),
    ("Al-Muzzammil", "The Enshrouded One"),
    ("Al-Muddaththir", "The Cloaked One"),
    ("Al-Qiyaama", "The Resurrection"),
    ("Al-Insaan", "Man"),
    ("Al-Mursalaat", "The Emissaries"),
    ("An-Naba", "The Announcement"),
    ("An-Naazi'aat", "Those who drag forth"),
    ("Abasa", "He frowned"),
    ("At-Takwir", "The Overthrowing"),
    ("Al-Infitaar", "The Cleaving"),
    ("Al-Mutaffifin", "Defrauding"),
    ("Al-Inshiqaaq", "The Splitting Open"),
    ("Al-Burooj", "The Constellations"),
    ("At-Taariq", "The Morning Star"),
    ("Al-A'laa", "The Most High"),
    ("Al-Ghaashiya", "The Overwhelming"),
    ("Al-Fajr", "The Dawn"),
    ("Al-Balad", "The City"),
    ("Ash-Shams", "The Sun"),
    ("Al-Lail", "The Night"),
    ("Ad-Dhuhaa", "The Morning Hours"),
    ("Ash-Sharh", "The Consolation"),
    ("At-Tin", "The Fig"),
    ("Al-Alaq", "The Clot"),
    ("Al-Qadr", "The Power, Fate"),
    ("Al-Bayyina", "The Evidence"),
    ("Az-Zalzala", "The Earthquake"),
    ("Al-Aadiyaat", "The Chargers"),
    ("Al-Qaari'a", "The Calamity"),
    ("At-Takaathur", "Competition"),
    ("Al-Asr", "The Declining Day, Epoch"),
    ("Al-Humaza", "The Traducer"),
    ("Al-Fil", "The Elephant"),
    ("Quraish", "Quraysh"),
    ("Al-Maa'un", "Almsgiving"),
    ("Al-Kawthar", "Abundance"),
    ("Al-Kaafiroon", "The Disbelievers"),
    ("An-Nasr", "Divine Support"),
    ("Al-Masad", "The Palm Fibre"),
    ("Al-Ikhlaas", "Sincerity"),
    ("Al-Falaq", "The Dawn"),
    ("An-Naas", "Mankind"),
  ];
  final index = [
    for (final (i, (latin, english)) in names.indexed)
      Surah(
        id: i + 1,
        nameArabic: '',
        transliteration: latin,
        translationEn: english,
        ayahCount: 1,
        revelation: 'meccan',
      ),
  ];
  List<int> ids(String q) => filterSurahs(index, q).map((s) => s.id).toList();

  test('common Latin spellings find the surah', () {
    for (final (query, id) in [
      ('Fatihah', 1),
      ('Al-Fatiha', 1),
      ('Al-Baqarah', 2),
      ('baqara', 2),
      ('Yasin', 36),
      ('Ya-Sin', 36),
      ('Ya Seen', 36),
      ('Waqiah', 56),
      ("Al-Waqi'ah", 56),
      ('Duha', 93),
      ('Ad-Duha', 93),
      ('Nuh', 71),
      ('Taha', 20),
      ('Rahman', 55),
      ('Kahf', 18),
      ('Ikhlas', 112),
    ]) {
      expect(ids(query), contains(id), reason: query);
    }
  });

  test('every surah still matches its own stored names', () {
    for (final s in index) {
      expect(ids(s.transliteration), contains(s.id), reason: s.transliteration);
      expect(ids(s.translationEn), contains(s.id), reason: s.translationEn);
    }
  });

  test('common queries stay narrow', () {
    for (final query in [
      'Fatihah',
      'Baqarah',
      'Yasin',
      'Waqiah',
      'Duha',
      'Nuh',
      'Mulk',
      'Kahf',
      'Rahman',
      'Ikhlas',
      'Falaq',
      'Nas',
      'Maryam',
      'Yusuf',
    ]) {
      expect(ids(query).length, lessThanOrEqualTo(3), reason: query);
    }
  });

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
