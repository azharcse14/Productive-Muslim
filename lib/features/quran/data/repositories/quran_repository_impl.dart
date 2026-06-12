import 'package:drift/drift.dart';

import '../../../../core/utils/result.dart';
import '../../domain/entities/ayah.dart';
import '../../domain/entities/surah.dart';
import '../../domain/repositories/quran_repository.dart';
import '../datasources/quran_database.dart';

/// Diacritic-light fold: lowercases, strips everything but ASCII
/// letters/digits and collapses doubled letters, so 'fatiha' matches
/// 'Al-Faatiha'. Applied to both the query and the indexed text.
String _normalize(String input) {
  final buffer = StringBuffer();
  int? previous;
  for (final code in input.toLowerCase().codeUnits) {
    final isAlnum =
        (code >= 0x61 && code <= 0x7a) || (code >= 0x30 && code <= 0x39);
    if (!isAlnum || code == previous) {
      continue;
    }
    buffer.writeCharCode(code);
    previous = code;
  }
  return buffer.toString();
}

/// [QuranRepository] over the bundled drift database (raw `customSelect`,
/// no codegen — see [QuranDatabase]).
final class QuranRepositoryImpl implements QuranRepository {
  const QuranRepositoryImpl(this._db);

  final QuranDatabase _db;

  @override
  Future<Result<List<Surah>>> surahs() async {
    try {
      final rows =
          await _db.customSelect('SELECT * FROM surahs ORDER BY id').get();
      return Result.success(rows.map(_surahOf).toList());
    } on Object catch (e) {
      return Result.failure(UnexpectedFailure('Failed to load surahs', e));
    }
  }

  @override
  Future<Result<List<Ayah>>> ayahsOf(int surah) async {
    try {
      final rows = await _db.customSelect(
        'SELECT * FROM ayahs WHERE surah = ? ORDER BY number',
        variables: [Variable<int>(surah)],
      ).get();
      return Result.success(rows.map(_ayahOf).toList());
    } on Object catch (e) {
      return Result.failure(UnexpectedFailure('Failed to load ayahs', e));
    }
  }

  @override
  Future<Result<List<Surah>>> searchSurahs(String query) async {
    final needle = _normalize(query);
    final all = await surahs();
    if (needle.isEmpty) {
      return all;
    }
    return all.map(
      (list) => [
        for (final surah in list)
          if (_normalize(surah.transliteration).contains(needle) ||
              _normalize(surah.translationEn).contains(needle))
            surah,
      ],
    );
  }

  @override
  Future<Result<QuranPosition?>> lastRead() async {
    try {
      final rows = await _db
          .customSelect('SELECT surah, ayah FROM last_read WHERE id = 1')
          .get();
      if (rows.isEmpty) {
        return const Result.success(null);
      }
      final row = rows.first;
      return Result.success(
        QuranPosition(row.read<int>('surah'), row.read<int>('ayah')),
      );
    } on Object catch (e) {
      return Result.failure(UnexpectedFailure('Failed to load last read', e));
    }
  }

  @override
  Future<Result<void>> setLastRead(QuranPosition position) async {
    try {
      await _db.customStatement(
        'INSERT INTO last_read(id, surah, ayah) VALUES (1, ?, ?) '
        'ON CONFLICT(id) DO UPDATE SET '
        'surah = excluded.surah, ayah = excluded.ayah',
        [position.surah, position.ayah],
      );
      return const Result.success(null);
    } on Object catch (e) {
      return Result.failure(UnexpectedFailure('Failed to set last read', e));
    }
  }

  @override
  Future<Result<Set<int>>> bookmarkedAyahIds() async {
    try {
      final rows =
          await _db.customSelect('SELECT ayah_id FROM bookmarks').get();
      return Result.success({for (final row in rows) row.read<int>('ayah_id')});
    } on Object catch (e) {
      return Result.failure(UnexpectedFailure('Failed to load bookmarks', e));
    }
  }

  @override
  Future<Result<void>> toggleBookmark(int ayahId) async {
    try {
      final removed = await _db.customUpdate(
        'DELETE FROM bookmarks WHERE ayah_id = ?',
        variables: [Variable<int>(ayahId)],
        updateKind: UpdateKind.delete,
      );
      if (removed == 0) {
        await _db.customInsert(
          'INSERT INTO bookmarks(ayah_id) VALUES (?)',
          variables: [Variable<int>(ayahId)],
        );
      }
      return const Result.success(null);
    } on Object catch (e) {
      return Result.failure(UnexpectedFailure('Failed to toggle bookmark', e));
    }
  }

  Surah _surahOf(QueryRow row) => Surah(
        id: row.read<int>('id'),
        nameArabic: row.read<String>('name_arabic'),
        transliteration: row.read<String>('transliteration'),
        translationEn: row.read<String>('translation_en'),
        ayahCount: row.read<int>('ayah_count'),
        revelation: row.read<String>('revelation'),
      );

  Ayah _ayahOf(QueryRow row) => Ayah(
        id: row.read<int>('id'),
        surah: row.read<int>('surah'),
        number: row.read<int>('number'),
        arabic: row.read<String>('arabic'),
        translationEn: row.read<String>('translation_en'),
        translationBn: row.read<String>('translation_bn'),
      );
}
