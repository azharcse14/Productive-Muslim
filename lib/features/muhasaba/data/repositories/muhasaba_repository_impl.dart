import 'package:drift/drift.dart';

import '../../../../core/utils/result.dart';
import '../../domain/entities/daily_entry.dart';
import '../../domain/entities/period_stats.dart';
import '../../domain/entities/tracker_item.dart';
import '../../domain/repositories/muhasaba_repository.dart';
import '../database/muhasaba_database.dart';

/// Encodes a date-only [DateTime] as a yyyymmdd integer (see schema docs).
int _encodeDate(DateTime date) =>
    date.year * 10000 + date.month * 100 + date.day;

/// Decodes a yyyymmdd integer back to a date-only [DateTime].
DateTime _decodeDate(int code) =>
    DateTime(code ~/ 10000, (code % 10000) ~/ 100, code % 100);

/// Inclusive day count between two date-only values (DST-safe via UTC).
int _dayCount(DateTime start, DateTime end) =>
    DateTime.utc(
      end.year,
      end.month,
      end.day,
    ).difference(DateTime.utc(start.year, start.month, start.day)).inDays +
    1;

/// SQL fragment: whether item `i` counts toward day `e.date` — it existed
/// (created on/before) and was not yet archived that day.
const _existedOnEntryDay =
    '(i.created_on IS NULL OR e.date >= i.created_on) '
    'AND (i.archived = 0 OR (i.archived_on IS NOT NULL AND e.date < i.archived_on))';

/// SQL fragment: whether an entry value completes its item for a day
/// (mirrors `TrackerItem.isDone`).
const _doneCase =
    'CASE WHEN i.daily_target IS NULL OR i.daily_target <= 0 '
    'THEN e.value > 0 ELSE e.value >= i.daily_target END';

/// Drift-backed [MuhasabaRepository]. Aggregations run as SQL queries
/// (guide §5) — Dart only fills bounded calendars and walks streaks.
final class MuhasabaRepositoryImpl implements MuhasabaRepository {
  const MuhasabaRepositoryImpl(
    this._db, {
    DateTime Function() clock = DateTime.now,
  }) : _clock = clock;

  final MuhasabaDatabase _db;

  /// Stamps created-on / archived-on days (injectable for tests).
  final DateTime Function() _clock;

  int get _todayCode => _encodeDate(_clock());

  @override
  Future<Result<void>> seedDefaultsIfEmpty() async {
    try {
      final count = await _db.trackerItems.count().getSingle();
      if (count == 0) {
        await _db.batch(
          (batch) => batch.insertAll(_db.trackerItems, [
            for (final item in DefaultTrackers.items())
              _toCompanion(item).copyWith(createdOn: Value(_todayCode)),
          ]),
        );
      }
      return const Result.success(null);
    } on Object catch (e) {
      return Result.failure(UnexpectedFailure('Failed to seed defaults', e));
    }
  }

  @override
  Future<Result<List<TrackerItem>>> items({
    bool includeArchived = false,
  }) async {
    try {
      final query = _db.select(_db.trackerItems)
        ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]);
      if (!includeArchived) {
        query.where((t) => t.archived.equals(false));
      }
      final rows = await query.get();
      return Result.success(rows.map(_toDomain).toList());
    } on Object catch (e) {
      return Result.failure(UnexpectedFailure('Failed to load items', e));
    }
  }

  @override
  Future<Result<void>> upsertItem(TrackerItem item) async {
    try {
      // created_on is stamped on first insert only; edits keep it.
      await _db.trackerItems.insertOne(
        _toCompanion(item).copyWith(createdOn: Value(_todayCode)),
        onConflict: DoUpdate((_) => _toCompanion(item)),
      );
      return const Result.success(null);
    } on Object catch (e) {
      return Result.failure(UnexpectedFailure('Failed to upsert item', e));
    }
  }

  @override
  Future<Result<void>> reorder(List<String> ids) async {
    try {
      await _db.batch((batch) {
        for (final (i, id) in ids.indexed) {
          batch.update(
            _db.trackerItems,
            TrackerItemsCompanion(sortOrder: Value(i)),
            where: (t) => t.id.equals(id),
          );
        }
      });
      return const Result.success(null);
    } on Object catch (e) {
      return Result.failure(UnexpectedFailure('Failed to reorder', e));
    }
  }

  @override
  Future<Result<void>> setArchived(String id, {required bool archived}) async {
    try {
      // Flag update only — entries are never deleted (hard product rule).
      await (_db.update(_db.trackerItems)..where((t) => t.id.equals(id))).write(
        TrackerItemsCompanion(
          archived: Value(archived),
          // ponytail: one archived-on day; archive→restore→archive keeps
          // only the latest span. Store spans if that history matters.
          archivedOn: Value(archived ? _todayCode : null),
        ),
      );
      return const Result.success(null);
    } on Object catch (e) {
      return Result.failure(UnexpectedFailure('Failed to set archived', e));
    }
  }

  @override
  Future<Result<List<DailyEntry>>> entriesOn(DateTime date) async {
    try {
      final code = _encodeDate(date);
      final rows = await (_db.select(
        _db.dailyEntries,
      )..where((t) => t.date.equals(code))).get();
      return Result.success(
        rows
            .map(
              (r) => DailyEntry(
                itemId: r.itemId,
                date: _decodeDate(r.date),
                value: r.value,
              ),
            )
            .toList(),
      );
    } on Object catch (e) {
      return Result.failure(UnexpectedFailure('Failed to load entries', e));
    }
  }

  @override
  Future<Result<void>> setEntry(DailyEntry entry) async {
    try {
      final code = _encodeDate(entry.date);
      if (entry.value <= 0) {
        await (_db.delete(_db.dailyEntries)
              ..where((t) => t.itemId.equals(entry.itemId))
              ..where((t) => t.date.equals(code)))
            .go();
      } else {
        // Back-filling before the item's creation day means it existed
        // then: move created_on back so that day counts it.
        await _db.customStatement(
          'UPDATE tracker_items SET created_on = ? '
          'WHERE id = ? AND created_on > ?',
          [code, entry.itemId, code],
        );
        await _db.dailyEntries.insertOnConflictUpdate(
          DailyEntriesCompanion.insert(
            itemId: entry.itemId,
            date: code,
            value: entry.value,
          ),
        );
      }
      return const Result.success(null);
    } on Object catch (e) {
      return Result.failure(UnexpectedFailure('Failed to set entry', e));
    }
  }

  @override
  Future<Result<PeriodStats>> periodStats({
    required DateTime start,
    required DateTime end,
    required DateTime today,
  }) async {
    try {
      final startCode = _encodeDate(start);
      final endCode = _encodeDate(end);
      final periodDays = _dayCount(start, end);

      // Items that count on a given day (existed, not yet archived).
      final spans = await _db.select(_db.trackerItems).get();
      int countOn(DateTime day) {
        final code = _encodeDate(day);
        return spans
            .where(
              (r) =>
                  (r.createdOn == null || r.createdOn! <= code) &&
                  (!r.archived ||
                      (r.archivedOn != null && code < r.archivedOn!)),
            )
            .length;
      }

      // a) Day completions: SQL fraction sums, calendar filled in Dart.
      final fractionSums = await _dayFractionSums(startCode, endCode);
      final days = <DayCompletion>[];
      var completionTotal = 0.0;
      for (var i = 0; i < periodDays; i++) {
        final day = DateTime(start.year, start.month, start.day + i);
        final sum = fractionSums[_encodeDate(day)] ?? 0;
        final count = countOn(day);
        final completion = count == 0
            ? 0.0
            : (sum / count).clamp(0, 1).toDouble();
        completionTotal += completion;
        days.add(DayCompletion(day, completion));
      }
      final completion = periodDays == 0 ? 0.0 : completionTotal / periodDays;

      // b) Per-item aggregates over the range.
      final itemStats = await _itemStats(start, end, periodDays);

      // c) Streaks: SQL day-has-done-item flags, walked in Dart. The scan
      // covers the whole history (one row per active day), so the best
      // streak matches the all-time streak badges and always includes
      // (so is >=) the current one.
      final today0 = DateTime(today.year, today.month, today.day);
      final scanTo = end.isAfter(today0) ? end : today0;
      final recentDone = await _doneDates(0, _encodeDate(scanTo));
      var anchor = today0;
      if (!recentDone.contains(_encodeDate(anchor))) {
        // Today has nothing done yet — the streak survives until the day
        // fully passes empty, so anchor at yesterday.
        anchor = DateTime(anchor.year, anchor.month, anchor.day - 1);
      }
      var currentStreak = 0;
      var cursor = anchor;
      while (recentDone.contains(_encodeDate(cursor))) {
        currentStreak++;
        cursor = DateTime(cursor.year, cursor.month, cursor.day - 1);
      }

      var bestStreak = 0;
      var run = 0;
      DateTime? prev;
      for (final code in recentDone.toList()..sort()) {
        final day = _decodeDate(code);
        final follows =
            prev != null &&
            DateTime(prev.year, prev.month, prev.day + 1) == day;
        run = follows ? run + 1 : 1;
        if (run > bestStreak) bestStreak = run;
        prev = day;
      }

      // d) Equal-length window immediately before [start].
      final prevStart = DateTime(
        start.year,
        start.month,
        start.day - periodDays,
      );
      final prevEnd = DateTime(start.year, start.month, start.day - 1);
      final prevSums = await _dayFractionSums(
        _encodeDate(prevStart),
        _encodeDate(prevEnd),
      );
      double? previousCompletion;
      if (prevSums.isNotEmpty && periodDays > 0) {
        var total = 0.0;
        for (final MapEntry(key: code, value: sum) in prevSums.entries) {
          final count = countOn(_decodeDate(code));
          if (count > 0) total += (sum / count).clamp(0, 1);
        }
        previousCompletion = total / periodDays;
      }

      return Result.success(
        PeriodStats(
          completion: completion,
          days: days,
          items: itemStats,
          currentStreak: currentStreak,
          bestStreak: bestStreak,
          previousCompletion: previousCompletion,
        ),
      );
    } on Object catch (e) {
      return Result.failure(
        UnexpectedFailure('Failed to compute period stats', e),
      );
    }
  }

  @override
  Future<Result<Set<DateTime>>> doneDates(Set<String> itemIds) async {
    if (itemIds.isEmpty) {
      return const Result.success(<DateTime>{});
    }
    try {
      // Archived items included on purpose: history is never lost.
      final rows = await _db
          .customSelect(
            'SELECT DISTINCT e.date AS day '
            'FROM daily_entries e '
            'INNER JOIN tracker_items i ON i.id = e.item_id '
            'WHERE e.item_id IN (${List.filled(itemIds.length, '?').join(', ')}) '
            'AND ($_doneCase)',
            variables: [for (final id in itemIds) Variable<String>(id)],
            readsFrom: {_db.dailyEntries, _db.trackerItems},
          )
          .get();
      return Result.success({
        for (final row in rows) _decodeDate(row.read<int>('day')),
      });
    } on Object catch (e) {
      return Result.failure(UnexpectedFailure('Failed to load done dates', e));
    }
  }

  /// Per-day sum of per-item completion fractions over the items that
  /// counted on that day, keyed by yyyymmdd. Days without entries are absent.
  Future<Map<int, double>> _dayFractionSums(int from, int to) async {
    final rows = await _db
        .customSelect(
          'SELECT e.date AS day, '
          'CAST(SUM(CASE '
          'WHEN i.daily_target IS NULL OR i.daily_target <= 0 '
          'THEN (CASE WHEN e.value > 0 THEN 1.0 ELSE 0.0 END) '
          'ELSE MIN(CAST(e.value AS REAL) / i.daily_target, 1.0) '
          'END) AS REAL) AS fraction_sum '
          'FROM daily_entries e '
          'INNER JOIN tracker_items i ON i.id = e.item_id '
          'WHERE ($_existedOnEntryDay) AND e.date BETWEEN ? AND ? '
          'GROUP BY e.date',
          variables: [Variable<int>(from), Variable<int>(to)],
          readsFrom: {_db.dailyEntries, _db.trackerItems},
        )
        .get();
    return {
      for (final row in rows)
        row.read<int>('day'): row.read<double>('fraction_sum'),
    };
  }

  /// yyyymmdd codes of days in [from]..[to] with at least one completed
  /// item. Archived items count (history is never lost), matching the
  /// achievements' streaks.
  Future<Set<int>> _doneDates(int from, int to) async {
    final rows = await _db
        .customSelect(
          'SELECT DISTINCT e.date AS day '
          'FROM daily_entries e '
          'INNER JOIN tracker_items i ON i.id = e.item_id '
          'WHERE e.date BETWEEN ? AND ? AND ($_doneCase)',
          variables: [Variable<int>(from), Variable<int>(to)],
          readsFrom: {_db.dailyEntries, _db.trackerItems},
        )
        .get();
    return {for (final row in rows) row.read<int>('day')};
  }

  /// Per non-archived item: done-day count and value sum over the range;
  /// the bar's denominator is the days the item existed within it.
  Future<List<ItemPeriodStats>> _itemStats(
    DateTime start,
    DateTime end,
    int periodDays,
  ) async {
    final from = _encodeDate(start);
    final to = _encodeDate(end);
    final rows = await _db
        .customSelect(
          'SELECT i.id AS item_id, i.kind AS kind, i.created_on AS created_on, '
          'COALESCE(SUM(CASE WHEN e.value IS NULL THEN 0 '
          'WHEN ($_doneCase) THEN 1 ELSE 0 END), 0) AS days_done, '
          'COALESCE(SUM(e.value), 0) AS total_value '
          'FROM tracker_items i '
          'LEFT JOIN daily_entries e '
          'ON e.item_id = i.id AND e.date BETWEEN ? AND ? '
          'WHERE i.archived = 0 '
          'GROUP BY i.id ORDER BY i.sort_order',
          variables: [Variable<int>(from), Variable<int>(to)],
          readsFrom: {_db.dailyEntries, _db.trackerItems},
        )
        .get();
    final stats = <ItemPeriodStats>[];
    for (final row in rows) {
      final daysDone = row.read<int>('days_done');
      final isYesNo = row.read<int>('kind') == TrackerKind.yesNo.index;
      final createdOn = row.readNullable<int>('created_on');
      final existedDays = createdOn == null || createdOn <= from
          ? periodDays
          : createdOn > to
          ? 0
          : _dayCount(_decodeDate(createdOn), end);
      stats.add(
        ItemPeriodStats(
          itemId: row.read<String>('item_id'),
          daysDone: daysDone,
          periodDays: existedDays,
          // yesNo totals are done-day counts, not raw value sums.
          totalValue: isYesNo ? daysDone : row.read<int>('total_value'),
        ),
      );
    }
    return stats;
  }

  TrackerItem _toDomain(TrackerItemRow row) => TrackerItem(
    id: row.id,
    name: row.name,
    kind: TrackerKind.values[row.kind],
    dailyTarget: row.dailyTarget,
    icon: row.icon,
    colorIndex: row.colorIndex,
    isDefault: row.isDefault,
    archived: row.archived,
    sortOrder: row.sortOrder,
  );

  TrackerItemsCompanion _toCompanion(TrackerItem item) =>
      TrackerItemsCompanion.insert(
        id: item.id,
        name: item.name,
        kind: item.kind.index,
        dailyTarget: Value(item.dailyTarget),
        icon: item.icon,
        colorIndex: item.colorIndex,
        isDefault: item.isDefault,
        archived: Value(item.archived),
        sortOrder: item.sortOrder,
      );
}
