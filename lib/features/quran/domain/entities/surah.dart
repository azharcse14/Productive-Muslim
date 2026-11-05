import '../../../../core/utils/locale_digits.dart';
import 'ayah.dart';

/// One of the 114 surahs (bundled DB metadata).
final class Surah {
  const Surah({
    required this.id,
    required this.nameArabic,
    required this.transliteration,
    required this.translationEn,
    required this.ayahCount,
    required this.revelation,
  });

  /// 1..114.
  final int id;
  final String nameArabic;
  final String transliteration;
  final String translationEn;
  final int ayahCount;

  /// 'meccan' | 'medinan'.
  final String revelation;

  @override
  bool operator ==(Object other) => other is Surah && other.id == id;

  @override
  int get hashCode => id;
}

/// Diacritic-light Latin fold, applied to both the query and the indexed
/// text: lowercases, keeps ASCII letters/digits, unifies common
/// transliteration variants per word (ee→i, oo→u, dh→d, a trailing h after
/// a/i dropped) and collapses doubled letters. So 'Fatihah', 'Yasin',
/// 'Duha' match 'Al-Faatiha', 'Yaseen', 'Ad-Dhuhaa'.
String _foldLatin(String input) {
  final words = input.toLowerCase().split(RegExp('[^a-z0-9]+'));
  final joined = words
      .map(
        (w) => w
            .replaceAll('ee', 'i')
            .replaceAll('oo', 'u')
            .replaceAll('dh', 'd')
            .replaceFirst(RegExp(r'(?<=[ai])h$'), ''),
      )
      .join();
  return joined.replaceAllMapped(RegExp(r'(.)\1+'), (m) => m[1]!);
}

/// Arabic fold: drops harakat/Quranic marks, tatweel and spaces, and
/// unifies alef/ya/ta-marbuta variants so a plain typed name matches.
/// The dagger alef (ٰ) is typed both ways: dropped (الرحمن, طه) or as a
/// full alef (آل عمران, العاديات). [daggerAsAlef] picks the second, with a
/// doubled alef collapsed; names are matched under either.
String _foldArabic(String input, {bool daggerAsAlef = false}) {
  final buffer = StringBuffer();
  int? previous;
  for (final rune in input.runes) {
    if ((rune >= 0x064B && rune <= 0x065F) ||
        (rune >= 0x06D6 && rune <= 0x06ED) ||
        (rune == 0x0670 && !daggerAsAlef) ||
        rune == 0x0640 ||
        String.fromCharCode(rune).trim().isEmpty) {
      continue;
    }
    final folded = switch (rune) {
      0x0622 || 0x0623 || 0x0625 || 0x0671 || 0x0670 => 0x0627, // alef → ا
      0x0649 || 0x06CC => 0x064A, // alef maksura, Persian yeh → ya
      0x0629 => 0x0647, // ta marbuta → ha
      0x06A9 => 0x0643, // Persian keheh → kaf
      _ => rune,
    };
    if (folded == 0x0627 && previous == 0x0627) {
      continue;
    }
    buffer.writeCharCode(folded);
    previous = folded;
  }
  return buffer.toString();
}

/// Surah index search: an exact surah number (any digit script), the
/// Arabic name, or the Latin transliteration / English name. An empty
/// query returns [all]; a query that folds to nothing matchable (e.g. a
/// Bengali word — the index has no Bengali names) returns no results
/// rather than everything.
List<Surah> filterSurahs(List<Surah> all, String query) {
  final raw = query.trim();
  if (raw.isEmpty) {
    return all;
  }
  final number = int.tryParse(LocaleDigits.toAscii(raw));
  if (number != null) {
    return [
      for (final s in all)
        if (s.id == number) s,
    ];
  }
  final latin = _foldLatin(raw);
  final arabic = _foldArabic(raw);
  return [
    for (final s in all)
      if ((latin.isNotEmpty &&
              (_foldLatin(s.transliteration).contains(latin) ||
                  _foldLatin(s.translationEn).contains(latin))) ||
          (arabic.isNotEmpty &&
              (_foldArabic(s.nameArabic).contains(arabic) ||
                  _foldArabic(
                    s.nameArabic,
                    daggerAsAlef: true,
                  ).contains(arabic))))
        s,
  ];
}

/// A "2:255"-style ayah reference (any digit script, `:` `.` or `/`
/// between, spaces ignored) checked against [all]'s ayah counts; null when
/// [query] isn't one or points past the surah.
QuranPosition? parseAyahReference(List<Surah> all, String query) {
  final match = RegExp(
    r'^(\d{1,3})[:./](\d{1,3})$',
  ).firstMatch(LocaleDigits.toAscii(query));
  if (match == null) {
    return null;
  }
  final surah = int.parse(match[1]!);
  final ayah = int.parse(match[2]!);
  final s = all.where((s) => s.id == surah).firstOrNull;
  return s == null || ayah < 1 || ayah > s.ayahCount
      ? null
      : QuranPosition(surah, ayah);
}
