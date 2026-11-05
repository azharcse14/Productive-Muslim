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
// Per-edition attribution lines are printed on success — record them in the
// About/credits screen (see DEPENDENCIES.md).
//
// Usage:  dart run tool/quran_db_build.dart
// Output: assets/data/quran.db — SQLite, PRAGMA user_version = 5, tables
//         `surahs` (114 rows) and `ayahs` (6236 rows, global id 1..6236).
// Requires `curl` on PATH (dev machines only).

import 'dart:convert';
import 'dart:io';

import 'package:productive_muslim/config/content_sources.dart';
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
      // 3:1 الم — the first letter is Alif ("Alim" is a typo; 2:1 has "Alif").
      (3, 1): (en: ('Alim. Lam. Mim', 'Alif. Lam. Mim'), bn: null),
      // 12:1 آيَاتُ is plural.
      (12, 1): (en: ('These are verse of', 'These are verses of'), bn: null),
      (31, 14): (
        en: ('concerning his partners', 'concerning his parents'),
        bn: ('পিতা-মতার', 'পিতা-মাতার'),
      ),
    };

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
];

Future<void> main() async {
  final tmp = Directory.systemTemp.createTempSync('productive_muslim_quran');
  try {
    final arabic = _downloadVerses(
      _arabicUrl,
      '${tmp.path}/ara.json',
    ).map((key, text) => MapEntry(key, _toKfgqpc(text)));
    final english = _downloadVerses(_englishUrl, '${tmp.path}/eng.json');
    final bangla = _downloadVerses(_banglaUrl, '${tmp.path}/ben.json');
    final chapters = _downloadChapters('${tmp.path}/info.json');

    _validate(chapters, arabic, english, bangla);

    final dbPath = '${tmp.path}/quran.db';
    _buildDatabase(dbPath, chapters, arabic, english, bangla);

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
        nameArabic: nameArabic,
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
        revelation TEXT
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
      PRAGMA user_version = 5;
    ''');
    db.execute('BEGIN');
    final insertSurah = db.prepare(
      'INSERT INTO surahs VALUES (?, ?, ?, ?, ?, ?)',
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
