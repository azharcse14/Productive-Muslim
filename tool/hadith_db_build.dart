// Dev-time script — builds the bundled hadith SQLite asset so the whole
// hadith reader works offline and survives the upstream open-source sources
// being moved or deleted (the app no longer depends on them at runtime).
//
// Sources (snapshotted once, here, at build time):
//   * Arabic + English — fawazahmed0/hadith-api (Unlicense), via the jsDelivr CDN:
//       editions/{edition}/sections/{n}.min.json
//     plus sections/0.min.json (hadith upstream gave no in-book reference)
//     folded into their chapters via info.json — see [placeSectionZero].
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
// Usage:  dart run tool/hadith_db_build.dart [--no-bengali]
// Output: assets/data/hadith.db — SQLite, PRAGMA user_version = [_userVersion].
//
// --no-bengali omits the hadithbangla text (no `hadith_bn_section` table) so
// a release can ship without it. The app must then be built with
// `--dart-define=BENGALI_HADITH=false`: HadithDatabase.ensureCopied compares
// that switch with the installed copy's table, so installed copies holding
// the Bengali text get replaced (and vice versa) with no version bump. The
// app treats a DB without the table as "no Bengali full-book hadith" and
// shows Arabic + English.
//
// Catalog of books/sections is read from assets/data/hadith_books.json so this
// stays in lock-step with the in-app navigation metadata.

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:productive_muslim/config/content_sources.dart';
import 'package:productive_muslim/features/hadith/data/hadith_blob_codec.dart';
import 'package:productive_muslim/features/hadith/data/hadith_section_assembler.dart';
import 'package:sqlite3/sqlite3.dart';

/// Bump together with [HadithDatabase.bundledVersion] to force a re-copy of the
/// asset on the next app launch after the data changes.
const _userVersion = 5;

/// Grades upstream leaves out, by (edition, hadith number). Read in the
/// reader's language: the Arabic edition carries none, so the translation's
/// shows (see assembleSection).
const _gradeOverrides = {
  // Ibn Rajab (Jami' al-'Ulum wal-Hikam) rejects an-Nawawi's "sahih chain".
  ('eng-nawawi', 41):
      "Da'if: chain weak per Ibn Rajab and al-Albani (Mishkat 167); hasan "
      'per Ibn Hajar (Hidayat ar-Ruwat 1/131)',
  ('ben-nawawi', 41):
      'যঈফ: ইবনু রজব ও আলবানির মতে সনদ দুর্বল (মিশকাত ১৬৭); ইবনু হাজারের '
      'মতে হাসান (হিদায়াতুর রুওয়াত ১/১৩১)',
};

const _catalogPath = 'assets/data/hadith_books.json';
const _outPath = 'assets/data/hadith.db';

// Pinned revisions, shared with the app's online fallback.
const _faBase = ContentSources.hadithApiEditionsBase;
final _infoUrl = '${_faBase.substring(0, _faBase.lastIndexOf('/'))}/info.json';
const _bnBase = ContentSources.hadithBanglaBase;

const _attributionLines = [
  'Hadith text (Arabic/English): fawazahmed0/hadith-api (Unlicense) — '
      'snapshotted via the jsDelivr CDN',
  'Hadith translation (Bengali): azharcse14/hadithbangla — '
      'snapshotted via raw.githubusercontent.com',
];

Future<void> main(List<String> args) async {
  final bengali = !args.contains('--no-bengali');
  final catalog = jsonDecode(await File(_catalogPath).readAsString());
  final books = (catalog as Map)['books'] as List;

  final tmp = Directory.systemTemp.createTempSync('productive_muslim_hadith');
  final dbPath = '${tmp.path}/hadith.db';
  final db = sqlite3.open(dbPath);
  final http = HttpClient()..connectionTimeout = const Duration(seconds: 30);
  var faHadith = 0;
  var bnHadith = 0;
  try {
    // Per-book section metadata + every hadith's in-book reference.
    final info = jsonDecode((await _get(http, _infoUrl))!) as Map;
    _createSchema(db, bengali: bengali);
    final faStmt = db.prepare(
      'INSERT OR REPLACE INTO hadith_section(edition, section, data) '
      'VALUES (?, ?, ?)',
    );
    final bnStmt = bengali
        ? db.prepare(
            'INSERT OR REPLACE INTO hadith_bn_section(book_id, section, data) '
            'VALUES (?, ?, ?)',
          )
        : null;
    try {
      for (final raw in books) {
        final book = raw as Map;
        final id = book['id'] as String;
        final sections = book['sections'] as List? ?? const [];
        final bnSections = book['sections_bn'] as List? ?? const [];
        final bnFolder = book['bn_folder'] as String? ?? '';
        stdout.writeln(
          '• $id — ${sections.length} sections'
          '${bnFolder.isNotEmpty ? ', ${bnSections.length} bn chapters' : ''}',
        );

        // fawazahmed0: Arabic + English (always); Bengali edition only for
        // books no hadithbangla folder covers (so bn still has *something*).
        final editions = <String>['ara-$id', 'eng-$id'];
        if (bnFolder.isEmpty) {
          editions.add('ben-$id');
        }
        // Upstream files hadith lacking an in-book reference under section
        // 0; fold them into the catalog section they belong to.
        final zero = {
          for (final edition in editions)
            edition: await _rawSection(
              http,
              edition,
              0,
              tolerant: edition.startsWith('ben-'),
            ),
        };
        final target = placeSectionZero(
          (info[id] as Map).cast<String, Object?>(),
          [...?zero['ara-$id'], ...?zero['eng-$id']],
          {for (final s in sections) (s as Map)['n'] as int},
        );
        for (final s in sections) {
          final n = (s as Map)['n'] as int;
          final byEdition = <String, List<RawHadith>>{};
          for (final edition in editions) {
            // ben-* may not exist for a book (e.g. ben-qudsi) — tolerate that.
            final tolerant = edition.startsWith('ben-');
            final base = n == 0
                ? const <Map<String, Object?>>[]
                : await _rawSection(http, edition, n, tolerant: tolerant);
            if (base == null) {
              continue;
            }
            byEdition[edition] = [
              for (final entry in mergeByNumber(base, [
                for (final h in zero[edition] ?? const <Map<String, Object?>>[])
                  if (target[h['hadithnumber']] == n) h,
              ]))
                if (RawHadith.parse(entry) case final h?)
                  RawHadith(
                    number: h.number,
                    text: h.text,
                    grade: _gradeOverrides[(edition, h.number)] ?? h.grade,
                    // Only Sahih Muslim's section-0 hadith lack
                    // `arabicnumber`: they have no Abd al-Baqi number, so
                    // mark upstream's internal one rather than pass it off
                    // as standard.
                    ref: entry.containsKey('arabicnumber')
                        ? h.ref
                        : '#${h.number}',
                  ),
            ];
          }
          // Upstream entries blank in both Arabic and English have nothing
          // to show — drop them from every edition (matched by number and
          // occurrence, as assembleSection pairs them).
          final english = _byOccurrence(byEdition['eng-$id'] ?? const []);
          final blank = {
            for (final MapEntry(:key, value: h) in _byOccurrence(
              byEdition['ara-$id'] ?? const [],
            ).entries)
              if (h.text.isEmpty && (english[key]?.text ?? '').isEmpty) key,
          };
          for (final MapEntry(key: edition, value: all) in byEdition.entries) {
            final hadiths = [
              for (final MapEntry(:key, :value) in _byOccurrence(all).entries)
                if (!blank.contains(key)) value,
            ];
            if (hadiths.isEmpty) {
              continue;
            }
            faStmt.execute([
              edition,
              n,
              Uint8List.fromList(encodeEditionBlob(hadiths)),
            ]);
            faHadith += hadiths.length;
          }
        }

        // hadithbangla: one Bangla chapter file per bn section.
        if (bnStmt != null && bnFolder.isNotEmpty) {
          for (final s in bnSections) {
            final n = (s as Map)['n'] as int;
            final body = await _get(
              http,
              '$_bnBase/$bnFolder/Chapter/$n.json',
              tolerant: true,
            );
            if (body == null) {
              continue;
            }
            final hadiths = _parseBn(body);
            if (hadiths.isEmpty) {
              continue;
            }
            bnStmt.execute([
              id,
              n,
              Uint8List.fromList(encodeBanglaBlob(hadiths)),
            ]);
            bnHadith += hadiths.length;
          }
        }
      }
    } finally {
      faStmt.close();
      bnStmt?.close();
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
    ..writeln(
      'Wrote $faHadith ara/eng + $bnHadith bn hadith to ${out.path} '
      '(${(out.lengthSync() / 1024 / 1024).toStringAsFixed(1)} MB)',
    )
    ..writeln('Attribution (surface in the credits screen):');
  for (final line in _attributionLines) {
    if (!bengali && line.contains('hadithbangla')) {
      continue;
    }
    stdout.writeln('  - $line');
  }
}

void _createSchema(Database db, {required bool bengali}) {
  db.execute('''
      CREATE TABLE hadith_section(
        edition TEXT NOT NULL,
        section INTEGER NOT NULL,
        data    BLOB NOT NULL,
        PRIMARY KEY(edition, section)
      )''');
  if (!bengali) {
    return;
  }
  db.execute('''
      CREATE TABLE hadith_bn_section(
        book_id TEXT NOT NULL,
        section INTEGER NOT NULL,
        data    BLOB NOT NULL,
        PRIMARY KEY(book_id, section)
      )''');
}

/// The raw `hadiths[]` of one fawazahmed0 [edition] section; null on a
/// tolerated miss.
Future<List<Map<String, Object?>>?> _rawSection(
  HttpClient http,
  String edition,
  int section, {
  required bool tolerant,
}) async {
  final body = await _get(
    http,
    '$_faBase/$edition/sections/$section.min.json',
    tolerant: tolerant,
  );
  if (body == null) {
    return null;
  }
  final decoded = jsonDecode(body);
  final entries = decoded is Map ? decoded['hadiths'] : null;
  return entries is List
      ? [
          for (final e in entries)
            if (e is Map) e.cast<String, Object?>(),
        ]
      : const [];
}

/// Where each section-0 hadith of a book goes: hadithnumber → catalog
/// section, from that book's [info] (upstream info.json entry).
///
/// fawazahmed0 files a hadith under section 0 when its source gave it no
/// in-book reference (`reference.book == 0`). Two kinds:
///  * section 0 is a real, named chapter (Muslim "Introduction", Ibn Majah
///    "The Book of the Sunnah") and its `section_details` range holds the
///    number → that chapter, section 0;
///  * otherwise it is a stray from the main sequence → the section of the
///    nearest preceding referenced hadith in upstream order (the following
///    one when nothing precedes). A stray between two chapters stays with
///    the one it follows: "the above tradition through another chain"
///    always points back.
/// Hadith empty in all of [entries] (the book's Arabic + English section 0)
/// are left out — nothing to show. Throws when a target is not one of
/// [catalogSections] rather than dropping the hadith.
Map<num, int> placeSectionZero(
  Map<String, Object?> info,
  List<Map<String, Object?>> entries,
  Set<int> catalogSections,
) {
  final metadata = (info['metadata']! as Map).cast<String, Object?>();
  final names = (metadata['sections']! as Map).cast<String, Object?>();
  final range = ((metadata['section_details']! as Map)['0'] as Map?)
      ?.cast<String, Object?>();
  final first = range?['hadithnumber_first'] as num? ?? 0;
  final last = range?['hadithnumber_last'] as num? ?? 0;
  final named = (names['0'] as String? ?? '').isNotEmpty && last > 0;

  final upstream = (info['hadiths']! as List).cast<Map<String, Object?>>();
  final index = {
    for (final (i, h) in upstream.indexed) h['hadithnumber']! as num: i,
  };
  int bookOf(int i) =>
      ((upstream[i]['reference']! as Map)['book']! as num).toInt();

  final wanted = {
    for (final h in entries)
      if ((h['text'] as String? ?? '').trim().isNotEmpty)
        h['hadithnumber']! as num,
  };
  final placed = <num, int>{};
  for (final number in wanted) {
    int? section;
    if (named && first <= number && number <= last) {
      section = 0;
    } else {
      final at =
          index[number] ??
          (throw StateError('section-0 hadith $number not in info.json'));
      for (var i = at - 1; i >= 0 && section == null; i--) {
        section = bookOf(i) == 0 ? null : bookOf(i);
      }
      for (var i = at + 1; i < upstream.length && section == null; i++) {
        section = bookOf(i) == 0 ? null : bookOf(i);
      }
    }
    if (section == null || !catalogSections.contains(section)) {
      throw StateError(
        'section-0 hadith $number → section $section, '
        'which the catalog does not list',
      );
    }
    placed[number] = section;
  }
  return placed;
}

/// [base] with each of [extra] inserted before the first entry with a
/// larger hadithnumber (upstream order otherwise kept, so every edition of
/// a section lines up the same way).
List<Map<String, Object?>> mergeByNumber(
  List<Map<String, Object?>> base,
  List<Map<String, Object?>> extra,
) {
  final out = [...base];
  for (final h in extra) {
    final n = h['hadithnumber']! as num;
    final at = out.indexWhere((e) => (e['hadithnumber']! as num) > n);
    out.insert(at == -1 ? out.length : at, h);
  }
  return out;
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

/// jsDelivr answers 403 when throttling a ~1500-file run; back off
/// 1, 4, 9 … 49 s (~2.5 min) before giving up.
const _attempts = 8;

/// GETs [url] with a few retries. Returns null only on a 404 when
/// [tolerant] (a missing chapter); any other failure, after the retries,
/// fails the build rather than silently dropping a section.
Future<String?> _get(
  HttpClient http,
  String url, {
  bool tolerant = false,
}) async {
  for (var attempt = 1; attempt <= _attempts; attempt++) {
    try {
      final req = await http.getUrl(Uri.parse(url));
      req.headers.set(HttpHeaders.acceptEncodingHeader, 'gzip');
      final res = await req.close();
      // A 404 for an optional ben-*/bn file means "doesn't exist". Anything
      // else (incl. a 403 from CDN throttling, or a 404 for ara/eng) retries
      // and then fails the build instead of silently dropping a section.
      if (tolerant && res.statusCode == 404) {
        await res.drain<void>();
        return null;
      }
      if (res.statusCode != 200) {
        await res.drain<void>();
        throw HttpException('HTTP ${res.statusCode}', uri: Uri.parse(url));
      }
      return await res.transform(utf8.decoder).join();
    } on Object {
      if (attempt == _attempts) {
        rethrow;
      }
      await Future<void>.delayed(Duration(seconds: attempt * attempt));
    }
  }
  return null;
}

/// [hadiths] keyed by (number, nth occurrence) in order — upstream repeats a
/// number for distinct narrations (Tirmidhi 3604 ×10).
Map<(int, int), RawHadith> _byOccurrence(List<RawHadith> hadiths) {
  final seen = <int, int>{};
  return {
    for (final h in hadiths)
      (h.number, seen[h.number] = (seen[h.number] ?? -1) + 1): h,
  };
}
