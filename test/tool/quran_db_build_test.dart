import 'package:flutter_test/flutter_test.dart';
import 'package:productive_muslim/core/utils/locale_digits.dart';

import '../../tool/quran_db_build.dart';

/// A 114-row table in the page's layout (cells split over `||` and new
/// lines). Rows without an entry in [names] / [meanings] carry the "from"
/// side of their [bnSurahNameFixes], or a placeholder.
String _wikitext({
  Map<int, String> names = const {},
  Map<int, String> meanings = const {},
}) {
  final out = StringBuffer(
    'intro [[link|text]]\n'
    '{| class="wikitable sortable"\n'
    '|- bgcolor=#99CCFF\n'
    '! width="8%" | কোরআনে অবস্থান\n'
    '! width="15%" | বাংলা উচ্চারণ\n',
  );
  for (var id = 1; id <= 114; id++) {
    final fix = bnSurahNameFixes[id];
    final name = names[id] ?? fix?.name?.$1 ?? 'নাম';
    final meaning = meanings[id] ?? fix?.meaning?.$1 ?? 'অর্থ';
    final n = LocaleDigits.localize('$id', 'bn');
    out
      ..writeln('|- bgcolor=#F4F9FF')
      ..writeln('|$n||[[সূরা $name|$name]]||<big>x</big>||$meaning')
      ..writeln('|৭')
      ..writeln('|১||মক্কা||০০৫');
  }
  return (out..writeln('|}\n\n== তথ্যসূত্র ==')).toString();
}

void main() {
  group('parseBnWikiSurahTable', () {
    test('reads the pronunciation and meaning cells of all 114 rows', () {
      final rows = parseBnWikiSurahTable(
        _wikitext(names: {1: 'আল ফাতিহা'}, meanings: {1: 'সূচনা'}),
      );
      expect(rows, hasLength(114));
      expect(rows.first, (name: 'আল ফাতিহা', meaning: 'সূচনা'));
    });

    test('rejects a table that is short or out of order', () {
      final short = _wikitext().replaceFirst('|১১৪||', '|১১৫||');
      expect(() => parseBnWikiSurahTable(short), throwsFormatException);
      expect(() => parseBnWikiSurahTable('no table'), throwsFormatException);
    });
  });

  group('bengaliSurahNames', () {
    test('drops "সূরা" and every article style, keeps আলে-ইমরান', () {
      final names = bengaliSurahNames(
        _wikitext(
          names: {
            1: 'আল ফাতিহা',
            9: 'আত-তাওবাহ্‌',
            15: 'সূরা আল হিজর',
            42: 'আশ্‌-শূরা',
            52: 'আত্ব তূর',
            55: 'আর- রাহমান',
            95: 'ত্বীন',
          },
        ),
      ).map((n) => n.name).toList();
      expect(names[0], 'ফাতিহা');
      expect(names[2], 'আলে-ইমরান');
      // Word-final hasanta + ZWNJ goes.
      expect(names[8], 'তাওবাহ');
      expect(names[14], 'হিজর');
      expect(names[41], 'শূরা');
      expect(names[51], 'তূর');
      expect(names[54], 'রাহমান');
      expect(names[94], 'ত্বীন');
    });

    test('keeps a ZWNJ after an inner hasanta, drops a stray one', () {
      final names = bengaliSurahNames(
        _wikitext(names: {27: 'আন নম্‌ল', 84: 'আল ইন‌শিকাক'}),
      );
      expect(names[26].name, 'নম্‌ল');
      expect(names[83].name, 'ইনশিকাক');
    });

    test('applies the per-surah fixes', () {
      final names = bengaliSurahNames(
        _wikitext(names: {39: 'আয-জুমার', 41: 'হা-মীম সেজদাহ্‌'}),
      );
      expect(names[5].meaning, 'গৃহপালিত');
      expect(names[38].name, 'যুমার');
      expect(names[40].name, 'হা-মীম সিজদাহ');
      expect(names[110].name, 'মাসাদ');
      expect(names[110].meaning, contains('লাহাব'));
    });

    test('writes "," and "/" as ", "', () {
      final names = bengaliSurahNames(
        _wikitext(meanings: {24: 'আলো,জ্যোতি', 62: 'সম্মেলন/শুক্রবার'}),
      );
      expect(names[23].meaning, 'আলো, জ্যোতি');
      expect(names[61].meaning, 'সম্মেলন, শুক্রবার');
    });

    test('a fix whose text is gone throws', () {
      expect(
        () => bengaliSurahNames(_wikitext(meanings: {6: 'গৃহপালিত পশু'})),
        throwsStateError,
      );
    });

    test('non-Bengali text (e.g. ASCII digits, markup) throws', () {
      expect(
        () => bengaliSurahNames(_wikitext(names: {1: 'ফাতিহা 1'})),
        throwsFormatException,
      );
      expect(
        () => bengaliSurahNames(_wikitext(meanings: {1: 'সূচনা<ref>x</ref>'})),
        throwsFormatException,
      );
    });
  });
}
