import 'dart:isolate';

import 'package:sqlite3/sqlite3.dart' as sqlite;

import 'hadith_blob_codec.dart';
import 'hadith_search.dart';

/// A loaded search corpus that answers queries.
abstract interface class HadithSearchIndex {
  Future<HadithRawResults> search(String query, String languageCode, int limit);

  void close();
}

/// Long-lived isolate that reads the [sources] straight from the hadith.db
/// file (its own read-only connection, so blobs never cross isolates),
/// decodes them once and keeps the corpus; each query sends back only the
/// small hit records, so matching never runs on the UI thread.
final class HadithSearchWorker implements HadithSearchIndex {
  HadithSearchWorker._(this._isolate, this._requests);

  final Isolate _isolate;
  final SendPort _requests;

  static Future<HadithSearchWorker> spawn(
    String dbPath,
    List<HadithSearchSource> sources,
  ) async {
    final ready = ReceivePort();
    try {
      final isolate = await Isolate.spawn(_main, (
        ready.sendPort,
        dbPath,
        sources,
      ), onError: ready.sendPort);
      final reply = await ready.first;
      if (reply is SendPort) {
        return HadithSearchWorker._(isolate, reply);
      }
      isolate.kill();
      throw StateError('Hadith search load failed: $reply');
    } finally {
      ready.close();
    }
  }

  @override
  Future<HadithRawResults> search(
    String query,
    String languageCode,
    int limit,
  ) async {
    final reply = ReceivePort();
    try {
      _requests.send((query, languageCode, limit, reply.sendPort));
      return await reply.first as HadithRawResults;
    } finally {
      reply.close();
    }
  }

  @override
  void close() => _isolate.kill();

  static void _main((SendPort, String, List<HadithSearchSource>) args) {
    final (out, path, sources) = args;
    final HadithSearchCorpus corpus;
    try {
      corpus = loadHadithSearchCorpus(path, sources);
    } on Object catch (e) {
      out.send('$e');
      return;
    }
    final requests = ReceivePort();
    out.send(requests.sendPort);
    requests.listen((message) {
      final (query, lang, limit, reply) =
          message as (String, String, int, SendPort);
      reply.send(searchHadithCorpus(corpus, query, lang, limit: limit));
    });
  }
}

/// Reads and decodes [sources] from the hadith.db at [path] (synchronous —
/// call it off the UI thread).
HadithSearchCorpus loadHadithSearchCorpus(
  String path,
  List<HadithSearchSource> sources,
) {
  final db = sqlite.sqlite3.open(path, mode: sqlite.OpenMode.readOnly);
  try {
    final hasHb = db
        .select(
          "SELECT 1 FROM sqlite_master WHERE type = 'table' "
          "AND name = 'hadith_bn_section'",
        )
        .isNotEmpty;
    final en = <HadithSearchEntry>[];
    final bn = <HadithSearchEntry>[];
    for (final s in sources) {
      if (s.hb && !hasHb) {
        continue;
      }
      final rows = db.select(
        s.hb
            ? 'SELECT section, data FROM hadith_bn_section '
                  'WHERE book_id = ? ORDER BY section'
            : 'SELECT section, data FROM hadith_section '
                  'WHERE edition = ? ORDER BY section',
        [s.key],
      );
      final out = s.bn ? bn : en;
      for (final row in rows) {
        final section = row['section'] as int;
        final data = row['data'] as List<int>;
        if (s.hb) {
          for (final h in decodeBanglaBlob(data)) {
            if (h.bn.isNotEmpty) {
              out.add(HadithSearchEntry(s.book, section, h.number, h.bn));
            }
          }
        } else {
          for (final h in decodeEditionBlob(data)) {
            if (h.text.isNotEmpty) {
              out.add(
                HadithSearchEntry(s.book, section, h.referenceNumber, h.text),
              );
            }
          }
        }
      }
    }
    return HadithSearchCorpus(en, bn);
  } finally {
    db.close();
  }
}
