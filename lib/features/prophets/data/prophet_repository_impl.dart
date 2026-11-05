import 'dart:convert';

import 'package:flutter/services.dart' show AssetBundle;

import '../../../core/utils/result.dart';
import '../domain/entities/prophet.dart';
import '../domain/repositories/prophet_repository.dart';

/// Loads the bundled prophets from `assets/data/prophets.json` and the full
/// lineage from `assets/data/prophet_lineage.json`.
/// Malformed entries are skipped — a partial list beats a crash; the
/// data-integrity test catches them before release.
final class ProphetRepositoryImpl implements ProphetRepository {
  ProphetRepositoryImpl(this._bundle);

  static const path = 'assets/data/prophets.json';
  static const lineagePath = 'assets/data/prophet_lineage.json';

  final AssetBundle _bundle;
  List<Prophet>? _cache;
  List<Prophet>? _lineageCache;

  @override
  Future<Result<List<Prophet>>> prophets() async {
    try {
      return Result.success(_cache ??= parse(await _bundle.loadString(path)));
    } on Object catch (e) {
      return Result.failure(UnexpectedFailure('Prophets load failed', e));
    }
  }

  @override
  Future<Result<List<Prophet>>> lineage() async {
    if (_lineageCache case final cached?) return Result.success(cached);
    final prophets = await this.prophets();
    if (prophets case FailureResult(:final failure)) {
      return Result.failure(failure);
    }
    try {
      return Result.success(
        _lineageCache = parseLineage(
          await _bundle.loadString(lineagePath),
          prophets.valueOrNull!,
        ),
      );
    } on Object catch (e) {
      return Result.failure(UnexpectedFailure('Lineage load failed', e));
    }
  }

  /// Parses the lineage array; `order` is the position in the file. An
  /// entry takes its names from the prophet with its id, else from its own
  /// `nameEn`/`nameBn`; entries with neither are dropped.
  static List<Prophet> parseLineage(String raw, List<Prophet> prophets) {
    final byId = {for (final p in prophets) p.id: p};
    final people = <Prophet>[];
    if (jsonDecode(raw) case final List<Object?> list) {
      for (final entry in list) {
        if (entry case {'id': final String id}) {
          final parent = entry['parent'] is String
              ? entry['parent'] as String
              : null;
          final distant = entry['parentDistant'] == true;
          final order = people.length + 1;
          if (byId[id] case final p?) {
            people.add(
              Prophet(
                id: id,
                order: order,
                nameAr: p.nameAr,
                nameEn: p.nameEn,
                nameBn: p.nameBn,
                parent: parent,
                parentDistant: distant,
              ),
            );
          } else if (entry case {
            'nameEn': final String nameEn,
            'nameBn': final String nameBn,
          }) {
            people.add(
              Prophet(
                id: id,
                order: order,
                nameAr: '',
                nameEn: nameEn,
                nameBn: nameBn,
                parent: parent,
                parentDistant: distant,
              ),
            );
          }
        }
      }
    }
    return people;
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
