import 'dart:convert';

import 'package:flutter/services.dart' show AssetBundle;

import '../../../core/utils/result.dart';
import '../domain/entities/prophet.dart';
import '../domain/repositories/prophet_repository.dart';

/// Loads the bundled prophets from `assets/data/prophets.json`.
/// Malformed entries are skipped — a partial list beats a crash; the
/// data-integrity test catches them before release.
final class ProphetRepositoryImpl implements ProphetRepository {
  ProphetRepositoryImpl(this._bundle);

  static const path = 'assets/data/prophets.json';

  final AssetBundle _bundle;
  List<Prophet>? _cache;

  @override
  Future<Result<List<Prophet>>> prophets() async {
    try {
      return Result.success(_cache ??= parse(await _bundle.loadString(path)));
    } on Object catch (e) {
      return Result.failure(UnexpectedFailure('Prophets load failed', e));
    }
  }

  /// Parses the JSON array; entries missing id/order/names are dropped.
  static List<Prophet> parse(String raw) => [
    if (jsonDecode(raw) case final List<Object?> list)
      for (final entry in list)
        if (entry case {
          'id': final String id,
          'order': final int order,
          'nameAr': final String nameAr,
          'nameEn': final String nameEn,
          'nameBn': final String nameBn,
        })
          Prophet(
            id: id,
            order: order,
            nameAr: nameAr,
            nameEn: nameEn,
            nameBn: nameBn,
            titleEn: _string(entry['titleEn']),
            titleBn: _string(entry['titleBn']),
            parent: entry['parent'] is String
                ? entry['parent'] as String
                : null,
            parentDistant: entry['parentDistant'] == true,
            summaryEn: _strings(entry['summaryEn']),
            summaryBn: _strings(entry['summaryBn']),
            quranMentions: _strings(entry['quranMentions']),
            hadithRefs: _strings(entry['hadithRefs']),
            storyIds: _strings(entry['storyIds']),
          ),
  ];

  static String _string(Object? value) => value is String ? value : '';

  static List<String> _strings(Object? value) => [
    if (value is List) ...value.whereType<String>(),
  ];
}
