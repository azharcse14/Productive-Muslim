import 'dart:async';
import 'dart:isolate';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:sqlite3/sqlite3.dart' as sqlite;

import 'hadith_blob_codec.dart';
import 'hadith_search.dart';

/// A loaded search corpus that answers queries.
abstract interface class HadithSearchIndex {
  Future<HadithRawResults> search(String query, String languageCode, int limit);

  /// False once the index can no longer answer (its isolate died); the
  /// owner then drops it and loads a new one.
  bool get alive;

  void close();
}

/// Long-lived isolate that reads the [sources] straight from the hadith.db
/// file (its own read-only connection, so blobs never cross isolates),
/// decodes them once and keeps the corpus; each query sends back only the
/// small hit records, so matching never runs on the UI thread.
final class HadithSearchWorker implements HadithSearchIndex {
  HadithSearchWorker._(this._isolate, this._requests, this._died);

  final Isolate _isolate;
  final SendPort _requests;

  /// Completes when the isolate exits (crash, kill or [close]).
  final Future<void> _died;
  var _alive = true;

  static Future<HadithSearchWorker> spawn(
    String dbPath,
    List<HadithSearchSource> sources,
  ) async {
    final ready = ReceivePort();
    final died = Completer<void>();
    // Uncaught errors are fatal, so the exit message covers every death.
    final exit = RawReceivePort();
    exit.handler = (Object? _) {
      exit.close();
      died.complete();
    };
    try {
      final isolate = await Isolate.spawn(
        _main,
        (ready.sendPort, dbPath, sources),
        onError: ready.sendPort,
        onExit: exit.sendPort,
      );
      final reply = await Future.any<Object?>([
        ready.first,
        died.future.then((_) => 'exited while loading'),
      ]);
      if (reply is SendPort) {
        final worker = HadithSearchWorker._(isolate, reply, died.future);
        unawaited(died.future.then((_) => worker._alive = false));
        return worker;
      }
      isolate.kill();
      throw StateError('Hadith search load failed: $reply');
    } finally {
      ready.close();
    }
  }

  @override
  bool get alive => _alive;

  /// Lets tests kill the isolate behind [close]'s back, like a crash.
  @visibleForTesting
  Isolate get isolate => _isolate;

  @override
  Future<HadithRawResults> search(
    String query,
    String languageCode,
    int limit,
  ) async {
    if (!_alive) {
      throw StateError('Hadith search worker is gone');
    }
    final reply = ReceivePort();
    try {
      _requests.send((query, languageCode, limit, reply.sendPort));
      // A death mid-query fails it instead of waiting forever.
      final result = await Future.any<Object?>([
        reply.first,
        _died.then((_) => null),
      ]);
      if (result is! HadithRawResults) {
        throw StateError('Hadith search worker died');
      }
      return result;
    } finally {
      reply.close();
    }
  }

  @override
  void close() {
    _alive = false;
    _isolate.kill();
  }

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
                HadithSearchEntry(
                  s.book,
                  section,
                  h.referenceNumber,
                  h.text,
                  lookup: h.hasStandardNumber,
                ),
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
