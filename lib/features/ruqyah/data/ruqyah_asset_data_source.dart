import 'dart:convert';

import 'package:flutter/services.dart' show AssetBundle;

import '../domain/entities/ruqyah.dart';

/// Loads the bundled ruqyah collection from a JSON asset.
/// Malformed entries are skipped silently — a partial list beats a crash.
final class RuqyahAssetDataSource {
  RuqyahAssetDataSource(this._bundle, {this.assetPath = ruqyahPath});

  static const ruqyahPath = 'assets/data/ruqyah.json';

  /// Prophetic medicine — same schema, its own screen (not a ruqyah).
  static const tibbNabawiPath = 'assets/data/tibb_nabawi.json';

  final AssetBundle _bundle;
  final String assetPath;
  List<RuqyahCategory>? _cache;

  Future<List<RuqyahCategory>> loadCategories() async {
    if (_cache case final cached?) {
      return cached;
    }
    final raw = await _bundle.loadString(assetPath);
    final decoded = jsonDecode(raw);
    final root = decoded is Map ? decoded.cast<String, Object?>() : null;
    final entries = switch (root?['categories']) {
      final List<Object?> list => list,
      _ => const <Object?>[],
    };
    return _cache = [
      for (final entry in entries)
        if (_category(entry) case final category?) category,
    ];
  }

  static RuqyahCategory? _category(Object? entry) {
    if (entry is! Map) {
      return null;
    }
    final map = entry.cast<String, Object?>();
    final id = map['id'];
    final icon = map['icon'];
    final rawItems = map['items'];
    if (id is! String || icon is! String || rawItems is! List) {
      return null;
    }
    return RuqyahCategory(
      id: id,
      icon: icon,
      items: [
        for (final item in rawItems)
          if (_item(item) case final ruqyah?) ruqyah,
      ],
    );
  }

  static RuqyahItem? _item(Object? entry) {
    if (entry is! Map) {
      return null;
    }
    final map = entry.cast<String, Object?>();
    final id = map['id'];
    final ar = map['ar'];
    final tr = map['tr'];
    final en = map['en'];
    if (id is! String || ar is! String || tr is! String || en is! String) {
      return null;
    }
    final titleEn = map['titleEn'];
    final titleBn = map['titleBn'];
    final bn = map['bn'];
    final ref = map['ref'];
    final repeat = map['repeat'];
    final detailsEn = map['detailsEn'];
    final detailsBn = map['detailsBn'];
    return RuqyahItem(
      id: id,
      titleEn: titleEn is String ? titleEn : '',
      titleBn: titleBn is String ? titleBn : '',
      arabic: ar,
      transliteration: tr,
      translationEn: en,
      translationBn: bn is String ? bn : '',
      reference: ref is String ? ref : '',
      repeat: repeat is int && repeat > 0 ? repeat : 1,
      detailsEn: detailsEn is String ? detailsEn : '',
      detailsBn: detailsBn is String ? detailsBn : '',
    );
  }
}
