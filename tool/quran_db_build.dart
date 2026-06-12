// Dev-time script — builds the bundled Quran SQLite asset (guide: offline
// Quran reader; Arabic text + English/Bangla translations + surah metadata).
//
// Source: fawazahmed0/quran-api (https://github.com/fawazahmed0/quran-api,
// API licensed under the Unlicense) served via the jsDelivr CDN. Editions:
//   * Arabic  — ara-quransimple (Tanzil Simple, fully diacritized; the
//     requested ara-quranuthmanihaf1 edition ships undotted text on the CDN,
//     so the closest fully-vowelled equivalent is used instead).
//   * English — eng-mohammedmarmadu (Mohammed Marmaduke William Pickthall,
//     public domain, via Tanzil).
//   * Bangla  — ben-muhiuddinkhan (Muhiuddin Khan, via Tanzil).
// Per-edition attribution lines are printed on success — record them in the
// About/credits screen (see DEPENDENCIES.md).
//
// Usage:  dart run tool/quran_db_build.dart
// Output: assets/data/quran.db — SQLite, PRAGMA user_version = 1, tables
//         `surahs` (114 rows) and `ayahs` (6236 rows, global id 1..6236).
// Requires `curl` on PATH (dev machines only).

import 'dart:convert';
import 'dart:io';

import 'package:sqlite3/sqlite3.dart';

const _cdn = 'https://cdn.jsdelivr.net/gh/fawazahmed0/quran-api@1';
const _arabicUrl = '$_cdn/editions/ara-quransimple.json';
const _englishUrl = '$_cdn/editions/eng-mohammedmarmadu.json';
const _banglaUrl = '$_cdn/editions/ben-muhiuddinkhan.json';
const _infoUrl = '$_cdn/info.json';

const _attributionLines = [
  'Quran text: Tanzil Quran Text (Simple), Tanzil.net — '
      'via fawazahmed0/quran-api (Unlicense)',
  'English translation: Mohammed Marmaduke William Pickthall, '
      '"The Meaning of the Glorious Koran" (public domain) — via Tanzil.net',
  'Bangla translation: Muhiuddin Khan — via Tanzil.net',
];

Future<void> main() async {
  final tmp = Directory.systemTemp.createTempSync('qalbee_quran');
  try {
    final arabic = _downloadVerses(_arabicUrl, '${tmp.path}/ara.json');
    final english = _downloadVerses(_englishUrl, '${tmp.path}/eng.json');
    final bangla = _downloadVerses(_banglaUrl, '${tmp.path}/ben.json');
    final chapters = _downloadChapters('${tmp.path}/info.json');

    _validate(chapters, arabic, english, bangla);

    final dbPath = '${tmp.path}/quran.db';
    _buildDatabase(dbPath, chapters, arabic, english, bangla);

    final out = File('assets/data/quran.db')..parent.createSync(recursive: true);
    File(dbPath).copySync(out.path);

    stdout
      ..writeln('Wrote ${chapters.length} surahs / ${arabic.length} ayahs to '
          '${out.path} '
          '(${(out.lengthSync() / 1024 / 1024).toStringAsFixed(1)} MB)')
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
  final json = jsonDecode(File(path).readAsStringSync()) as Map<String, Object?>;
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
  final json = jsonDecode(File(path).readAsStringSync()) as Map<String, Object?>;
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
      _fail('Surah ${chapter.id}: metadata says ${chapter.ayahCount} ayahs, '
          'Arabic edition has $actual');
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
      PRAGMA user_version = 1;
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
            arabic[key],
            english[key],
            bangla[key],
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
