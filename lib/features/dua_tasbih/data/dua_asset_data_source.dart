import 'dart:convert';

import 'package:flutter/services.dart' show AssetBundle;

import '../domain/entities/dua.dart';

/// Loads the bundled dua collection and Asmaul Husna names from JSON assets.
/// Malformed entries are skipped silently — a partial list beats a crash.
final class DuaAssetDataSource {
  DuaAssetDataSource(this._bundle);

  static const duasAssetPath = 'assets/data/duas.json';
  static const asmaAssetPath = 'assets/data/asmaul_husna.json';

  final AssetBundle _bundle;
  List<DuaCategory>? _categoriesCache;
  List<AsmaName>? _asmaCache;

  Future<List<DuaCategory>> loadCategories() async {
    if (_categoriesCache case final cached?) {
      return cached;
    }
    final raw = await _bundle.loadString(duasAssetPath);
    final decoded = jsonDecode(raw);
    final root = decoded is Map ? decoded.cast<String, Object?>() : null;
    final entries = switch (root?['categories']) {
      final List<Object?> list => list,
      _ => const <Object?>[],
    };
    return _categoriesCache = [
      for (final entry in entries)
        if (_category(entry) case final category?) category,
    ];
  }

  Future<List<AsmaName>> loadAsmaulHusna() async {
    if (_asmaCache case final cached?) {
      return cached;
    }
    final raw = await _bundle.loadString(asmaAssetPath);
    final decoded = jsonDecode(raw);
    final entries = decoded is List ? decoded : const <Object?>[];
    return _asmaCache = [
      for (final entry in entries)
        if (_asmaName(entry) case final name?) name,
    ];
  }

  static DuaCategory? _category(Object? entry) {
    if (entry is! Map) {
      return null;
    }
    final map = entry.cast<String, Object?>();
    final id = map['id'];
    final icon = map['icon'];
    final rawDuas = map['duas'];
    if (id is! String || icon is! String || rawDuas is! List) {
      return null;
    }
    return DuaCategory(
      id: id,
      icon: icon,
      duas: [
        for (final item in rawDuas)
          if (_dua(item) case final dua?) dua,
      ],
    );
  }

  static Dua? _dua(Object? entry) {
    if (entry is! Map) {
      return null;
    }
    final map = entry.cast<String, Object?>();
    final id = map['id'];
    final ar = map['ar'];
    final tr = map['tr'];
    final en = map['en'];
    final ref = map['ref'];
    if (id is! String || ar is! String || tr is! String || en is! String) {
      return null;
    }
    final bn = map['bn'];
    final trBn = map['trBn'];
    final repeat = map['repeat'];
    return Dua(
      id: id,
      arabic: ar,
      transliteration: tr,
      transliterationBn: trBn is String ? trBn : '',
      translationEn: en,
      translationBn: bn is String ? bn : '',
      reference: ref is String ? ref : '',
      repeat: repeat is int && repeat > 0 ? repeat : 1,
    );
  }

  static AsmaName? _asmaName(Object? entry) {
    if (entry is! Map) {
      return null;
    }
    final map = entry.cast<String, Object?>();
    final number = map['n'];
    final ar = map['ar'];
    final tr = map['tr'];
    final en = map['en'];
    if (number is! int || ar is! String || tr is! String || en is! String) {
      return null;
    }
    final bn = map['bn'];
    return AsmaName(
      number: number,
      arabic: ar,
      transliteration: tr,
      meaningEn: en,
      meaningBn: bn is String ? bn : '',
    );
  }
}
