import 'dart:convert';

import 'package:flutter/services.dart' show AssetBundle;

import '../domain/entities/hadith.dart';

/// Loads the bundled hadith collection from a JSON asset.
/// Malformed entries are skipped silently — a partial list beats a crash.
final class HadithAssetDataSource {
  HadithAssetDataSource(this._bundle);

  static const hadithAssetPath = 'assets/data/hadith.json';

  final AssetBundle _bundle;
  List<Hadith>? _cache;

  Future<List<Hadith>> loadAll() async {
    if (_cache case final cached?) {
      return cached;
    }
    final raw = await _bundle.loadString(hadithAssetPath);
    final decoded = jsonDecode(raw);
    final root = decoded is Map ? decoded.cast<String, Object?>() : null;
    final entries = switch (root?['hadith']) {
      final List<Object?> list => list,
      _ => const <Object?>[],
    };
    return _cache = [
      for (final entry in entries)
        if (_hadith(entry) case final hadith?) hadith,
    ];
  }

  static Hadith? _hadith(Object? entry) {
    if (entry is! Map) {
      return null;
    }
    final map = entry.cast<String, Object?>();
    final id = map['id'];
    final ar = map['ar'];
    final en = map['en'];
    final narrator = map['narrator'];
    final ref = map['ref'];
    if (id is! String || ar is! String || en is! String) {
      return null;
    }
    final bn = map['bn'];
    return Hadith(
      id: id,
      arabic: ar,
      en: en,
      bn: bn is String ? bn : '',
      narrator: narrator is String ? narrator : '',
      reference: ref is String ? ref : '',
    );
  }
}
