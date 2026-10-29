// Dev-time script — builds the bundled hadith SQLite asset so the whole
// hadith reader works offline and survives the upstream open-source sources
// being moved or deleted (the app no longer depends on them at runtime).
//
// Sources (snapshotted once, here, at build time):
//   * Arabic + English — fawazahmed0/hadith-api (Unlicense), via the jsDelivr CDN:
//       editions/{edition}/sections/{n}.min.json
//     Editions: ara-{id}, eng-{id}; plus ben-{id} for books that no
//     hadithbangla folder covers (40 Hadith Nawawi/Qudsi, Muwatta Malik).
//   * Bengali — azharcse14/hadithbangla repo (per-chapter Bangla translation
//       + narrator + grade), via raw.githubusercontent.com:
//       {folder}/Chapter/{n}.json
//
// Storage: one gzip-compressed JSON blob per *section* (see
// hadith_blob_codec.dart) — raw per-hadith rows weighed ~158 MB; this brings
// the asset to ~40 MB while matching the read pattern (a whole section at a
// time). Parsing + encoding are reused from the app (RawHadith/BnHadith.parse,
// encodeEditionBlob/encodeBanglaBlob) so the on-disk shape can't drift from
// what HadithBookBundledDataSource reads. Numbering stays per-source:
// fawazahmed0 sections in `hadith_section`, hadithbangla chapters in
// `hadith_bn_section`.
//
// Usage:  dart run tool/hadith_db_build.dart
// Output: assets/data/hadith.db — SQLite, PRAGMA user_version = 1.
//
// Catalog of books/sections is read from assets/data/hadith_books.json so this
// stays in lock-step with the in-app navigation metadata.

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:productive_muslim/features/hadith/data/hadith_blob_codec.dart';
import 'package:productive_muslim/features/hadith/data/hadith_section_assembler.dart';
import 'package:sqlite3/sqlite3.dart';

/// Bump together with [HadithDatabase.bundledVersion] to force a re-copy of the
/// asset on the next app launch after the data changes.
const _userVersion = 2;

const _catalogPath = 'assets/data/hadith_books.json';
const _outPath = 'assets/data/hadith.db';

const _faBase =
    'https://cdn.jsdelivr.net/gh/fawazahmed0/hadith-api@1/editions';
const _bnBase = 'https://raw.githubusercontent.com/azharcse14/hadithbangla/main';

const _attributionLines = [
  'Hadith text (Arabic/English): fawazahmed0/hadith-api (Unlicense) — '
      'snapshotted via the jsDelivr CDN',
  'Hadith translation (Bengali): azharcse14/hadithbangla — '
      'snapshotted via raw.githubusercontent.com',
];

Future<void> main() async {
  final catalog = jsonDecode(await File(_catalogPath).readAsString());
  final books = (catalog as Map)['books'] as List;

  final tmp = Directory.systemTemp.createTempSync('productive_muslim_hadith');
  final dbPath = '${tmp.path}/hadith.db';
  final db = sqlite3.open(dbPath);
  final http = HttpClient()..connectionTimeout = const Duration(seconds: 30);
  var faHadith = 0;
  var bnHadith = 0;
  try {
    _createSchema(db);
    final faStmt = db.prepare(
      'INSERT OR REPLACE INTO hadith_section(edition, section, data) '
      'VALUES (?, ?, ?)',
    );
    final bnStmt = db.prepare(
      'INSERT OR REPLACE INTO hadith_bn_section(book_id, section, data) '
      'VALUES (?, ?, ?)',
    );
    try {
      for (final raw in books) {
        final book = raw as Map;
        final id = book['id'] as String;
        final sections = book['sections'] as List? ?? const [];
        final bnSections = book['sections_bn'] as List? ?? const [];
        final bnFolder = book['bn_folder'] as String? ?? '';
        stdout.writeln('• $id — ${sections.length} sections'
            '${bnFolder.isNotEmpty ? ', ${bnSections.length} bn chapters' : ''}');

        // fawazahmed0: Arabic + English (always); Bengali edition only for
        // books no hadithbangla folder covers (so bn still has *something*).
        final editions = <String>['ara-$id', 'eng-$id'];
        if (bnFolder.isEmpty) {
          editions.add('ben-$id');
        }
        for (final edition in editions) {
          // ben-* may not exist for a book (e.g. ben-qudsi) — tolerate that.
          final tolerant = edition.startsWith('ben-');
          for (final s in sections) {
            final n = (s as Map)['n'] as int;
            final body = await _get(http,
                '$_faBase/$edition/sections/$n.min.json',
                tolerant: tolerant);
            if (body == null) {
              continue;
            }
            final hadiths = _parseFa(body);
            if (hadiths.isEmpty) {
              continue;
            }
            faStmt.execute(
                [edition, n, Uint8List.fromList(encodeEditionBlob(hadiths))]);
            faHadith += hadiths.length;
          }
        }

        // hadithbangla: one Bangla chapter file per bn section.
        if (bnFolder.isNotEmpty) {
          for (final s in bnSections) {
            final n = (s as Map)['n'] as int;
            final body = await _get(http, '$_bnBase/$bnFolder/Chapter/$n.json',
                tolerant: true);
            if (body == null) {
              continue;
            }
            final hadiths = _parseBn(body);
            if (hadiths.isEmpty) {
              continue;
            }
            bnStmt.execute(
                [id, n, Uint8List.fromList(encodeBanglaBlob(hadiths))]);
            bnHadith += hadiths.length;
          }
        }
      }
    } finally {
      faStmt.close();
      bnStmt.close();
    }

    db.execute('PRAGMA user_version = $_userVersion');
    db.execute('VACUUM');
  } finally {
    db.close();
    http.close(force: true);
  }

  final out = File(_outPath)..parent.createSync(recursive: true);
  File(dbPath).copySync(out.path);
  tmp.deleteSync(recursive: true);

  stdout
    ..writeln('Wrote $faHadith ara/eng + $bnHadith bn hadith to ${out.path} '
        '(${(out.lengthSync() / 1024 / 1024).toStringAsFixed(1)} MB)')
    ..writeln('Attribution (surface in the credits screen):');
  for (final line in _attributionLines) {
    stdout.writeln('  - $line');
  }
}

void _createSchema(Database db) {
  db
    ..execute('''
      CREATE TABLE hadith_section(
        edition TEXT NOT NULL,
        section INTEGER NOT NULL,
        data    BLOB NOT NULL,
        PRIMARY KEY(edition, section)
      )''')
    ..execute('''
      CREATE TABLE hadith_bn_section(
        book_id TEXT NOT NULL,
        section INTEGER NOT NULL,
        data    BLOB NOT NULL,
        PRIMARY KEY(book_id, section)
      )''');
}

List<RawHadith> _parseFa(String body) {
  final decoded = jsonDecode(body);
  final entries = (decoded is Map ? decoded['hadiths'] : null);
  if (entries is! List) {
    return const [];
  }
  return [
    for (final entry in entries)
      if (RawHadith.parse(entry) case final h?) h,
  ];
}

List<BnHadith> _parseBn(String body) {
  final decoded = jsonDecode(body);
  if (decoded is! List) {
    return const [];
  }
  return [
    for (final entry in decoded)
      if (BnHadith.parse(entry) case final h?) h,
  ];
}

/// GETs [url] with a few retries. Returns null on a tolerated 404 (a
/// missing edition/chapter) or after exhausting retries when [tolerant].
Future<String?> _get(HttpClient http, String url, {bool tolerant = false}) async {
  for (var attempt = 1; attempt <= 4; attempt++) {
    try {
      final req = await http.getUrl(Uri.parse(url));
      req.headers.set(HttpHeaders.acceptEncodingHeader, 'gzip');
      final res = await req.close();
      // A 404 for an optional ben-*/bn file means "doesn't exist". Anything
      // else (incl. a 403 from CDN throttling, or a 404 for ara/eng) retries
      // and then fails/skips loudly instead of silently dropping a section.
      if (tolerant && res.statusCode == 404) {
        await res.drain<void>();
        return null;
      }
      if (res.statusCode != 200) {
        await res.drain<void>();
        throw HttpException('HTTP ${res.statusCode}', uri: Uri.parse(url));
      }
      return await res.transform(utf8.decoder).join();
    } on Object catch (e) {
      if (attempt == 4) {
        if (tolerant) {
          stderr.writeln('  ! skipped $url ($e)');
          return null;
        }
        rethrow;
      }
      await Future<void>.delayed(Duration(milliseconds: 400 * attempt));
    }
  }
  return null;
}
