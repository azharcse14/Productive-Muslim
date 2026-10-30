import 'dart:convert';

import 'package:flutter/services.dart' show AssetBundle;

import '../domain/entities/hadith_book.dart';

/// Loads the bundled hadith-book catalog (navigation metadata only — section
/// names, edition keys, counts). Hadith text itself is fetched on demand.
final class HadithBookCatalogDataSource {
  HadithBookCatalogDataSource(this._bundle);

  static const catalogAssetPath = 'assets/data/hadith_books.json';

  final AssetBundle _bundle;
  List<HadithBook>? _cache;

  Future<List<HadithBook>> loadBooks() async {
    if (_cache case final cached?) {
      return cached;
    }
    final raw = await _bundle.loadString(catalogAssetPath);
    final decoded = jsonDecode(raw);
    final root = decoded is Map ? decoded.cast<String, Object?>() : null;
    final entries = switch (root?['books']) {
      final List<Object?> list => list,
      _ => const <Object?>[],
    };
    return _cache = [
      for (final entry in entries)
        if (_book(entry) case final book?) book,
    ];
  }

  static HadithBook? _book(Object? entry) {
    if (entry is! Map) {
      return null;
    }
    final map = entry.cast<String, Object?>();
    final id = map['id'];
    final en = map['en'];
    if (id is! String || en is! String) {
      return null;
    }
    final bn = map['bn'];
    final author = map['author'];
    final authorBn = map['author_bn'];
    final kind = map['kind'];
    final total = map['total'];
    final rawSections = map['sections'];
    final rawBnSections = map['sections_bn'];
    final bnAvailable = map['bn_available'];
    final bnFolder = map['bn_folder'];
    return HadithBook(
      id: id,
      en: en,
      bn: bn is String ? bn : '',
      author: author is String ? author : '',
      authorBn: authorBn is String ? authorBn : '',
      kind: kind is String ? kind : 'graded',
      bnAvailable: bnAvailable is bool ? bnAvailable : true,
      bnFolder: bnFolder is String ? bnFolder : '',
      total: total is int ? total : 0,
      editionAr: map['edition_ar'] is String
          ? map['edition_ar']! as String
          : 'ara-$id',
      editionEn: map['edition_en'] is String
          ? map['edition_en']! as String
          : 'eng-$id',
      editionBn: map['edition_bn'] is String
          ? map['edition_bn']! as String
          : 'ben-$id',
      sections: [
        if (rawSections is List)
          for (final s in rawSections)
            if (_section(s) case final section?) section,
      ],
      bnSections: [
        if (rawBnSections is List)
          for (final s in rawBnSections)
            if (_section(s) case final section?) section,
      ],
    );
  }

  static HadithSection? _section(Object? entry) {
    if (entry is! Map) {
      return null;
    }
    final map = entry.cast<String, Object?>();
    final number = map['n'];
    final name = map['name'];
    if (number is! int || name is! String) {
      return null;
    }
    final first = map['first'];
    final last = map['last'];
    final count = map['count'];
    final refs = map['refs'];
    return HadithSection(
      number: number,
      name: name,
      first: first is int ? first : null,
      last: last is int ? last : null,
      count: count is int ? count : null,
      refs: [
        if (refs is List)
          for (final run in refs)
            if (run case [final int from, final int to]) (from, to),
      ],
    );
  }
}
