// Dev-time script — builds the bundled Quran SQLite asset (guide: offline
// Quran reader; Arabic text + English/Bangla translations + surah metadata).
//
// Source: fawazahmed0/quran-api (https://github.com/fawazahmed0/quran-api,
// API licensed under the Unlicense) served via the jsDelivr CDN. Editions:
//   * Arabic  — ara-quranuthmanihaf (King Fahd Complex (KFGQPC) Uthmani
//     Hafs text, version 13; license UNVERIFIED, see DEPENDENCIES.md). The
//     edition swaps KFGQPC's open-tanween code points for the Unicode
//     U+08F0..U+08F2, appends U+200F and splits off a following silent alif;
//     [_toKfgqpc] undoes all three, so every code point is in the bundled
//     KFGQPC HAFS v22 font's cmap.
//   * English — eng-mohammedmarmadu (Mohammed Marmaduke William Pickthall,
//     via Tanzil; license unverified, see DEPENDENCIES.md).
//   * Bangla  — ben-muhiuddinkhan (Muhiuddin Khan, via Tanzil).
// Bengali surah names + meanings: Bengali Wikipedia "কুরআনের সূরার তালিকা",
// revision ContentSources.bnWikiSurahListOldid (CC BY-SA 4.0), adapted by
// [bengaliSurahNames] — see DEPENDENCIES.md.
// Per-edition attribution lines are printed on success — record them in the
// About/credits screen (see DEPENDENCIES.md).
//
// Usage:  dart run tool/quran_db_build.dart
// Output: assets/data/quran.db — SQLite, PRAGMA user_version = 8, tables
//         `surahs` (114 rows) and `ayahs` (6236 rows, global id 1..6236).
// Requires `curl` on PATH (dev machines only).

import 'dart:convert';
import 'dart:io';

import 'package:productive_muslim/config/content_sources.dart';
import 'package:productive_muslim/core/utils/locale_digits.dart';
import 'package:sqlite3/sqlite3.dart';

const _cdn =
    'https://cdn.jsdelivr.net/gh/fawazahmed0/quran-api@${ContentSources.quranApiSha}';
const _arabicUrl = '$_cdn/editions/ara-quranuthmanihaf.json';
const _englishUrl = '$_cdn/editions/eng-mohammedmarmadu.json';
const _banglaUrl = '$_cdn/editions/ben-muhiuddinkhan.json';
const _infoUrl = '$_cdn/info.json';

/// Typos in the upstream (Tanzil) translation text, fixed at build time as
/// (from, to) replacements. 3:1 and 12:1 below; 31:14 — Arabic بِوَالِدَيْهِ and the same ayah's
/// "thy parents": "partners" is a typo for "parents"; Bangla "পিতা-মতার" →
/// "পিতা-মাতার".
const _corrections =
    <(int, int), ({(String, String)? en, (String, String)? bn})>{
      // 2:255 لَا إِلَٰهَ إِلَّا هُوَ — Pickthall (1930) has "no God save Him";
      // "deity" is Tanzil's lone edit of his wording.
      (2, 255): (
        en: ('There is no deity save Him', 'There is no God save Him'),
        bn: null,
      ),
      // 3:1 الم — the first letter is Alif ("Alim" is a typo; 2:1 has "Alif").
      (3, 1): (en: ('Alim. Lam. Mim', 'Alif. Lam. Mim'), bn: null),
      // 12:1 آيَاتُ is plural.
      (12, 1): (en: ('These are verse of', 'These are verses of'), bn: null),
      (31, 14): (
        en: ('concerning his partners', 'concerning his parents'),
        bn: ('পিতা-মতার', 'পিতা-মাতার'),
      ),
      // Bangla typos: 4:3 যথার্থ / পূরণ, 4:34 কর্তৃত্ব, 5:3 যায়, 11:14 পূরণ.
      (4, 3): (en: null, bn: ('যথাথভাবে পুরণ', 'যথার্থভাবে পূরণ')),
      (4, 34): (en: null, bn: ('কৃর্তত্বশীল', 'কর্তৃত্বশীল')),
      (5, 3): (en: null, bn: ('মারা যা,', 'মারা যা\u09DF,')),
      (11, 14): (en: null, bn: ('কথা পুরণ', 'কথা পূরণ')),
      // 27:30 بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ — "সসীম" (finite) is a typo
      // for Muhiuddin Khan's "অসীম দাতা".
      (27, 30): (en: null, bn: ('সসীম দাতা', 'অসীম দাতা')),
    };

/// Tanzil's Pickthall swapped his "God" for "Allah" where the Arabic is
/// the generic إِلَٰه ("there is no Allah save Allah", "Your Allah is One
/// Allah"); 22:34 ("your god is One God") escaped it. Restored to "God" in
/// these generic-deity phrases only — "Allah" as the proper name stays.
final _pickthallIlah = RegExp(r'\b(no|other|One|[Yy]our|our|any) Allah\b');

/// Hits of [_pickthallIlah] in the pinned edition; a change means the
/// upstream text moved and the phrases need a fresh review.
const _pickthallIlahCount = 74;

/// Applies [_pickthallIlah] to every ayah of [english] in place.
void _restorePickthallGod(_Verses english) {
  var hits = 0;
  english.updateAll(
    (_, text) => text.replaceAllMapped(_pickthallIlah, (m) {
      hits++;
      return '${m[1]} God';
    }),
  );
  if (hits != _pickthallIlahCount) {
    _fail('Pickthall "God" restore: $hits hits, expected $_pickthallIlahCount');
  }
}

/// Arabic surah names that don't match the transliteration/English name
/// the API ships with them (40 is "Ghafir", 76 "Al-Insaan").
const _arabicNameFixes = {40: 'غَافِرٍ', 76: 'الْإِنْسَانِ'};

/// Applies [fix] to [text]; throws when the upstream text no longer has the
/// typo, so a stale correction is noticed on the next build.
String? _corrected(String? text, (String, String)? fix) {
  if (text == null || fix == null) return text;
  final (from, to) = fix;
  if (!text.contains(from)) {
    throw StateError('correction "$from" not found');
  }
  return text.replaceAll(from, to);
}

const _attributionLines = [
  'Quran text: Uthmani Hafs, King Fahd Glorious Quran Printing Complex '
      '(qurancomplex.gov.sa) — via fawazahmed0/quran-api (Unlicense)',
  'English translation: Mohammed Marmaduke William Pickthall, '
      '"The Meaning of the Glorious Koran" (license unverified) — via Tanzil.net',
  'Bangla translation: Muhiuddin Khan — via Tanzil.net',
  'Bengali surah names: Bengali Wikipedia contributors, CC BY-SA 4.0 '
      '(adapted) — bn.wikipedia.org oldid '
      '${ContentSources.bnWikiSurahListOldid}',
];

Future<void> main() async {
  final tmp = Directory.systemTemp.createTempSync('productive_muslim_quran');
  try {
    final arabic = _downloadVerses(
      _arabicUrl,
      '${tmp.path}/ara.json',
    ).map((key, text) => MapEntry(key, _toKfgqpc(text)));
    final english = _downloadVerses(_englishUrl, '${tmp.path}/eng.json');
    _restorePickthallGod(english);
    final bangla = _downloadVerses(_banglaUrl, '${tmp.path}/ben.json');
    final chapters = _downloadChapters('${tmp.path}/info.json');
    stdout.writeln('Downloading ${ContentSources.bnWikiSurahListRaw} …');
    final wikiPath = '${tmp.path}/bn_wiki.txt';
    _run('curl', [
      '-sfL',
      '--retry',
      '3',
      '-o',
      wikiPath,
      ContentSources.bnWikiSurahListRaw,
    ]);
    final namesBn = bengaliSurahNames(File(wikiPath).readAsStringSync());

    _validate(chapters, arabic, english, bangla);

    final dbPath = '${tmp.path}/quran.db';
    _buildDatabase(dbPath, chapters, namesBn, arabic, english, bangla);

    final out = File('assets/data/quran.db')
      ..parent.createSync(recursive: true);
    File(dbPath).copySync(out.path);

    stdout
      ..writeln(
        'Wrote ${chapters.length} surahs / ${arabic.length} ayahs to '
        '${out.path} '
        '(${(out.lengthSync() / 1024 / 1024).toStringAsFixed(1)} MB)',
      )
      ..writeln('Attribution (surface in the credits screen):');
    for (final line in _attributionLines) {
      stdout.writeln('  $line');
    }
  } finally {
    tmp.deleteSync(recursive: true);
  }
}

/// One verse of one edition, keyed by (chapter, verse).
typedef _Verses = Map<(int, int), String>;

/// Surah metadata from the API's info endpoint.
class _Chapter {
  const _Chapter({
    required this.id,
    required this.nameArabic,
    required this.transliteration,
    required this.translationEn,
    required this.ayahCount,
    required this.revelation,
  });

  final int id;
  final String nameArabic;
  final String transliteration;
  final String translationEn;
  final int ayahCount;

  /// 'meccan' | 'medinan'.
  final String revelation;
}

_Verses _downloadVerses(String url, String path) {
  stdout.writeln('Downloading $url …');
  _run('curl', ['-sfL', '--retry', '3', '-o', path, url]);
  final json =
      jsonDecode(File(path).readAsStringSync()) as Map<String, Object?>;
  final verses = <(int, int), String>{};
  for (final entry in json['quran']! as List<Object?>) {
    final verse = entry! as Map<String, Object?>;
    verses[(verse['chapter']! as int, verse['verse']! as int)] =
        verse['text']! as String;
  }
  return verses;
}

List<_Chapter> _downloadChapters(String path) {
  stdout.writeln('Downloading $_infoUrl …');
  _run('curl', ['-sfL', '--retry', '3', '-o', path, _infoUrl]);
  final json =
      jsonDecode(File(path).readAsStringSync()) as Map<String, Object?>;
  final chapters = <_Chapter>[];
  for (final entry in json['chapters']! as List<Object?>) {
    final chapter = entry! as Map<String, Object?>;
    final revelation = switch (chapter['revelation']! as String) {
      'Mecca' => 'meccan',
      'Madina' => 'medinan',
      final other => _fail('Unknown revelation place "$other"'),
    };
    // Drop the "سُوْرَةُ" ("Surah") prefix — the column holds the bare name.
    const surahPrefix = 'سُوْرَةُ ';
    var nameArabic = chapter['arabicname']! as String;
    if (nameArabic.startsWith(surahPrefix)) {
      nameArabic = nameArabic.substring(surahPrefix.length);
    }
    chapters.add(
      _Chapter(
        id: chapter['chapter']! as int,
        nameArabic: _arabicNameFixes[chapter['chapter']! as int] ?? nameArabic,
        transliteration: chapter['name']! as String,
        translationEn: chapter['englishname']! as String,
        ayahCount: (chapter['verses']! as List<Object?>).length,
        revelation: revelation,
      ),
    );
  }
  return chapters;
}

void _validate(
  List<_Chapter> chapters,
  _Verses arabic,
  _Verses english,
  _Verses bangla,
) {
  if (chapters.length != 114) {
    _fail('Expected 114 surahs, got ${chapters.length}');
  }
  for (final (edition, verses) in [
    ('Arabic', arabic),
    ('English', english),
    ('Bangla', bangla),
  ]) {
    if (verses.length != 6236) {
      _fail('$edition edition: expected 6236 ayahs, got ${verses.length}');
    }
  }
  if (arabic.values.any((text) => text.trim().isEmpty)) {
    _fail('Arabic edition contains empty ayah text');
  }
  // Uthmani-only small high dotless head of khah (sukun): a wrong edition
  // (e.g. Tanzil Simple) has none.
  if (!arabic[(1, 2)]!.contains('\u06E1')) {
    _fail('Arabic edition is not the Uthmani text (no U+06E1 in 1:2)');
  }
  final byId = {for (final c in chapters) c.id: c};
  if (byId[1]?.ayahCount != 7) {
    _fail('Surah 1 should have 7 ayahs, metadata says ${byId[1]?.ayahCount}');
  }
  if (byId[2]?.ayahCount != 286) {
    _fail('Surah 2 should have 286 ayahs, metadata says ${byId[2]?.ayahCount}');
  }
  final perSurah = <int, int>{};
  for (final (surah, _) in arabic.keys) {
    perSurah[surah] = (perSurah[surah] ?? 0) + 1;
  }
  for (final chapter in chapters) {
    final actual = perSurah[chapter.id] ?? 0;
    if (actual != chapter.ayahCount) {
      _fail(
        'Surah ${chapter.id}: metadata says ${chapter.ayahCount} ayahs, '
        'Arabic edition has $actual',
      );
    }
  }
}

void _buildDatabase(
  String path,
  List<_Chapter> chapters,
  List<BengaliSurahName> namesBn,
  _Verses arabic,
  _Verses english,
  _Verses bangla,
) {
  final db = sqlite3.open(path);
  try {
    db.execute('''
      CREATE TABLE surahs(
        id INTEGER PRIMARY KEY,
        name_arabic TEXT,
        transliteration TEXT,
        translation_en TEXT,
        ayah_count INTEGER,
        revelation TEXT,
        name_bn TEXT,
        meaning_bn TEXT
      );
      CREATE TABLE ayahs(
        id INTEGER PRIMARY KEY,
        surah INTEGER,
        number INTEGER,
        arabic TEXT,
        translation_en TEXT,
        translation_bn TEXT
      );
      CREATE INDEX idx_ayahs_surah_number ON ayahs(surah, number);
      PRAGMA user_version = 8;
    ''');
    db.execute('BEGIN');
    final insertSurah = db.prepare(
      'INSERT INTO surahs VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
    );
    final insertAyah = db.prepare(
      'INSERT INTO ayahs VALUES (?, ?, ?, ?, ?, ?)',
    );
    try {
      var globalId = 0;
      for (final chapter in chapters) {
        insertSurah.execute([
          chapter.id,
          chapter.nameArabic,
          chapter.transliteration,
          chapter.translationEn,
          chapter.ayahCount,
          chapter.revelation,
          namesBn[chapter.id - 1].name,
          namesBn[chapter.id - 1].meaning,
        ]);
        for (var number = 1; number <= chapter.ayahCount; number++) {
          final key = (chapter.id, number);
          insertAyah.execute([
            ++globalId,
            chapter.id,
            number,
            _stripBasmala(chapter.id, number, arabic[key]!, arabic[(1, 1)]!),
            _corrected(english[key], _corrections[key]?.en),
            _corrected(bangla[key], _corrections[key]?.bn),
          ]);
        }
      }
    } finally {
      insertSurah.close();
      insertAyah.close();
    }
    db
      ..execute('COMMIT')
      ..execute('VACUUM');
  } finally {
    db.close();
  }
}

Never _fail(String message) {
  stderr.writeln('ERROR: $message');
  exit(1);
}

void _run(String cmd, List<String> args) {
  final result = Process.runSync(cmd, args);
  if (result.exitCode != 0) {
    stderr.writeln(result.stderr);
    throw ProcessException(cmd, args, 'exit ${result.exitCode}');
  }
}

/// A space the edition puts between an open tanween and the silent alif /
/// alif maqsura closing the same word (فِرَٰشࣰ ا for فِرَٰشٗا, 2,417 times).
final _splitTanweenAlif = RegExp(
  '([\u08F0-\u08F2]) (?=[\u0627\u0649][\u0610-\u061A\u064B-\u065F\u06D6-\u06ED]*(?: |\$))',
);

/// Undoes fawazahmed0's Unicode substitutions so the text is in KFGQPC's own
/// encoding, which the bundled KFGQPC HAFS font expects: the word split at
/// [_splitTanweenAlif] rejoined, open fathatan / dammatan / kasratan back to
/// U+0657 / U+065E / U+0656, and the U+200F marks it appended after them
/// dropped. Letters and marks are untouched. Checked 2026-11-05 to equal
/// KFGQPC's text as served by quran.com (`text_qpc_hafs`) for all 6,236 ayat.
String _toKfgqpc(String text) => text
    .replaceAllMapped(_splitTanweenAlif, (m) => m[1]!)
    .replaceAll('\u08F0', '\u0657')
    .replaceAll('\u08F1', '\u065E')
    .replaceAll('\u08F2', '\u0656')
    .replaceAll('\u200F', '');

/// Some editions (e.g. `ara-quransimple`) glue the basmala onto ayah 1 of every
/// surah but 1 and 9, while the translations don't carry it. Strip it so the
/// Arabic matches its translation; the reader shows the basmala as a surah
/// header instead. `ara-quranuthmanihaf` doesn't glue it, so this is a guard.
String _stripBasmala(int surah, int number, String text, String basmala) {
  // The source's own 1:1 is the prefix, so its diacritic order always matches.
  final prefix = '$basmala ';
  if (surah == 1 || number != 1 || !text.startsWith(prefix)) return text;
  return text.substring(prefix.length);
}

/// One surah's Bengali name and meaning.
typedef BengaliSurahName = ({String name, String meaning});

/// Raw (pronunciation, meaning) cells of the 114-row table on the Bengali
/// Wikipedia surah list, wiki links reduced to their label, in surah order.
/// Rows split on `|-`, cells on `||` and line-leading `|`; the first cell
/// must be the row's surah number.
List<BengaliSurahName> parseBnWikiSurahTable(String wikitext) {
  final start = wikitext.indexOf('{|');
  final end = start < 0 ? -1 : wikitext.indexOf('\n|}', start);
  if (end < 0) {
    throw const FormatException('no wikitable');
  }
  final link = RegExp(r'\[\[(?:[^|\]]*\|)?([^\]]*)\]\]');
  String text(String cell) => cell.replaceAllMapped(link, (m) => m[1]!);
  final rows = <BengaliSurahName>[];
  for (final row in wikitext.substring(start, end).split('\n|-').skip(1)) {
    final cells = [
      for (final line in row.split('\n').skip(1))
        if (line.trim().startsWith('|'))
          ...line.trim().substring(1).split('||').map((c) => c.trim()),
    ];
    if (cells.length < 4) {
      continue; // the header row has `!` cells only
    }
    final number = int.tryParse(LocaleDigits.toAscii(cells[0]));
    if (number != rows.length + 1) {
      throw FormatException('row ${rows.length + 1} is numbered ${cells[0]}');
    }
    rows.add((name: text(cells[1]), meaning: text(cells[3])));
  }
  if (rows.length != 114) {
    throw FormatException('expected 114 rows, got ${rows.length}');
  }
  return rows;
}

/// Per-surah fixes to the Wikipedia cells, as (from, to) replacements
/// applied before the generic clean-up; a stale one throws.
const bnSurahNameFixes =
    <int, ({(String, String)? name, (String, String)? meaning})>{
      // البقرة is the cow.
      2: (name: null, meaning: ('বকনা-বাছুর-গরু', 'গাভী')),
      // آل عمران: "Aal" (family), not the article.
      3: (name: ('আল- ইমরান', 'আলে-ইমরান'), meaning: null),
      6: (name: null, meaning: ('গৃৃহপালিত', 'গৃহপালিত')),
      7: (name: null, meaning: ('উচু', 'উঁচু')),
      8: (name: null, meaning: ('যুদ্ধে-লব্ধ', 'যুদ্ধলব্ধ')),
      // The page's own meaning cell spells it হাজ্জ.
      22: (name: ('হাজ্জ্ব', 'হাজ্জ'), meaning: null),
      37: (name: null, meaning: ('দাড়ানো', 'দাঁড়ানো')),
      // Like 50's "আরবি বর্ণ ক্বাফ".
      38: (name: null, meaning: ('আরবি বর্ণ', 'আরবি বর্ণ ছোয়াদ')),
      // الزمر is zumar (the page's own link: "সূরা আয যুমার"); জুমার
      // reads as Friday.
      39: (name: ('জুমার', 'যুমার'), meaning: ('দল-বদ্ধ', 'দলবদ্ধ')),
      // 32's spelling, সিজদাহ.
      41: (name: ('সেজদাহ্\u200c', 'সিজদাহ'), meaning: null),
      // Named غافر / "Ghafir" (see _arabicNameFixes), not المؤمن.
      40: (name: ("মু'মিন", 'গাফির'), meaning: ('বিশ্বাসী', 'ক্ষমাশীল')),
      49: (name: null, meaning: ('সমূূহ', 'সমূহ')),
      75: (name: null, meaning: ('পুনরুথান', 'পুনরুত্থান')),
      // Named الإنسان / "Al-Insaan" (see _arabicNameFixes), not الدهر.
      76: (name: ('দাহর', 'ইনসান'), meaning: null),
      // المرسلات: those (winds) sent forth, not messengers.
      77: (name: null, meaning: ('প্রেরিত পুরুষবৃন্দ', 'প্রেরিত বায়ুসমূহ')),
      // النازعات: those who pull out (souls) forcefully.
      79: (name: null, meaning: ('প্রচেষ্টাকারী', 'প্রবলভাবে টেনে আনয়নকারী')),
      84: (name: null, meaning: ('খন্ড-বিখন্ড করণ', 'খণ্ড-বিখণ্ডকরণ')),
      91: (name: null, meaning: ('সূর্য্য', 'সূর্য')),
      96: (name: null, meaning: ('রক্তপিন্ড', 'রক্তপিণ্ড')),
      // ليلة القدر: the night of majesty, not "amount".
      97: (name: null, meaning: ('পরিমাণ', 'মহিমান্বিত রজনী')),
      // The page names 111 লাহাব; the Arabic name the app shows is المسد.
      111: (
        name: ('লাহাব', 'মাসাদ'),
        meaning: (
          'জ্বলন্ত অঙ্গার',
          'খেজুর আঁশের রশি (অপর নাম লাহাব: জ্বলন্ত অঙ্গার)',
        ),
      ),
    };

/// A leading "সূরা" and Arabic article (আল / আন / আত্ব / আশ্‌ …) followed
/// by a space or hyphen — dropped: the common Bangla form is "সূরা বাকারা".
final _bnArticle = RegExp(
  '^(?:সূরা\\s+)?আ(?:ল|ন|ত্ব|ত|র|স|শ|য|দ)\u09CD?\u200C?[\\s-]+',
);

/// What a cleaned name/meaning may hold: Bengali letters and signs (no
/// digits), space, hyphen, apostrophe, comma, colon, parentheses, ZWNJ.
final _bnAllowed = RegExp("^[\u0980-\u09E5\u09F0-\u09FF \\-',:()\u200C]+\$");

/// The 114 Bengali surah names and meanings from the Wikipedia
/// [wikitext], adapted: [bnSurahNameFixes]; "সূরা" and the article
/// dropped from names; ZWNJ kept only after a hasanta inside a word (a
/// word-final hasanta + ZWNJ goes); "," and "/" written ", ". Throws on
/// anything outside [_bnAllowed].
List<BengaliSurahName> bengaliSurahNames(String wikitext) {
  String clean(String text) => text
      .replaceAll(RegExp('\u09CD\u200C(?=\\s|\$)'), '')
      .replaceAll(RegExp('(?<!\u09CD)\u200C'), '')
      .replaceAll(RegExp(r'\s*[,/]\s*'), ', ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  final raw = parseBnWikiSurahTable(wikitext);
  return [
    for (final (i, row) in raw.indexed)
      _checkedBn(i + 1, (
        name: clean(
          _fixed(
            row.name,
            bnSurahNameFixes[i + 1]?.name,
          ).replaceFirst(_bnArticle, ''),
        ),
        meaning: clean(_fixed(row.meaning, bnSurahNameFixes[i + 1]?.meaning)),
      )),
  ];
}

BengaliSurahName _checkedBn(int surah, BengaliSurahName entry) {
  for (final text in [entry.name, entry.meaning]) {
    if (!_bnAllowed.hasMatch(text)) {
      throw FormatException('surah $surah: unexpected text "$text"');
    }
  }
  return entry;
}

String _fixed(String text, (String, String)? fix) {
  if (fix == null) {
    return text;
  }
  final (from, to) = fix;
  if (!text.contains(from)) {
    throw StateError('fix "$from" not found in "$text"');
  }
  return text.replaceFirst(from, to);
}
