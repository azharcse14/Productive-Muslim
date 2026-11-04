import 'dart:convert';

import 'package:flutter/services.dart' show AssetBundle;

import '../domain/entities/story.dart';

/// Loads the bundled stories of one [StoryKind] from its JSON asset.
/// Malformed entries are skipped — a partial list beats a crash; the
/// asset integrity test keeps the shipped files clean.
final class StoryAssetDataSource {
  StoryAssetDataSource(this._bundle);

  static String pathFor(StoryKind kind) =>
      'assets/data/${kind.name}_stories.json';

  final AssetBundle _bundle;
  final Map<StoryKind, List<Story>> _cache = {};

  Future<List<Story>> load(StoryKind kind) async {
    if (_cache[kind] case final cached?) {
      return cached;
    }
    return _cache[kind] = parse(await _bundle.loadString(pathFor(kind)));
  }

  /// Parses a JSON array of stories.
  static List<Story> parse(String raw) => switch (jsonDecode(raw)) {
    final List<Object?> list => [
      for (final entry in list)
        if (_story(entry) case final story?) story,
    ],
    _ => const [],
  };

  static Story? _story(Object? entry) {
    if (entry is! Map) {
      return null;
    }
    final map = entry.cast<String, Object?>();
    final id = map['id'];
    final titleEn = map['titleEn'];
    final bodyEn = _strings(map['bodyEn']);
    if (id is! String || titleEn is! String || bodyEn.isEmpty) {
      return null;
    }
    final titleBn = map['titleBn'];
    return Story(
      id: id,
      titleEn: titleEn,
      titleBn: titleBn is String ? titleBn : '',
      bodyEn: bodyEn,
      bodyBn: _strings(map['bodyBn']),
      refs: _strings(map['refs']),
    );
  }

  static List<String> _strings(Object? value) => switch (value) {
    final List<Object?> list => [...list.whereType<String>()],
    _ => const [],
  };
}
