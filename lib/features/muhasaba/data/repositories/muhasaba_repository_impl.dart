import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart' show debugPrint;

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

/// SQL fragment: day `e.date` falls in a finished archive span of item
/// `i` (archived, later restored) after its archive day.
const _inArchiveSpan =
    'EXISTS (SELECT 1 FROM tracker_archive_spans s WHERE s.item_id = i.id '
    'AND e.date > s.start_on AND e.date < s.end_on)';

/// SQL fragment: `e.date` is a past archive day of item `i`. It never
/// counts — the same as while the item is still archived — so restoring
/// doesn't change that day.
const _onPastArchiveDay =
    'EXISTS (SELECT 1 FROM tracker_archive_spans s WHERE s.item_id = i.id '
    'AND e.date = s.start_on)';

/// SQL fragment: whether item `i`'s entry `e` counts toward its day — the
/// item existed (created on/before) and was not yet archived that day. A
/// past archive span doesn't drop it: an entry back-filled into a span
/// after restore means "I did it that day", so it counts like the streak
/// and badges count it — except on the archive day itself. Mirrored in
/// Dart by [_countsOn].
const _existedOnEntryDay =
    '(i.created_on IS NULL OR e.date >= i.created_on) '
    'AND (i.archived = 0 OR (i.archived_on IS NOT NULL AND e.date < i.archived_on)) '
    'AND NOT $_onPastArchiveDay';

/// Dart twin of [_existedOnEntryDay] (plus the known-kind check) for any
/// day: a day in a past archive span (after its archive day) counts only
/// if it has an entry ([revived], `(itemId, yyyymmdd)`).
bool _countsOn(
  TrackerItemRow r,
  List<ArchiveSpanRow> spans,
  Set<(String, int)> revived,
  int code,
) =>
    TrackerKind.fromCode(r.kind) != null &&
    (r.createdOn == null || r.createdOn! <= code) &&
    (!r.archived || (r.archivedOn != null && code < r.archivedOn!)) &&
    (revived.contains((r.id, code)) ||
        !spans.any(
          (s) => s.itemId == r.id && code >= s.startOn && code < s.endOn,
        ));

/// SQL fragment: item `i` has a kind this build knows — unknown kinds are
/// hidden from the UI, so they count toward no completion either.
final _knownKind =
    'i.kind IN (${TrackerKind.values.map((k) => k.code).join(', ')})';

/// SQL: the target entry `e` is judged against — the one stamped when it
/// was written, so editing the item's target leaves past days alone.
const _target = 'COALESCE(e.target, i.daily_target)';

/// SQL fragment: whether an entry value completes its item for a day
/// (mirrors `TrackerItem.isDone`).
const _doneCase =
    'CASE WHEN $_target IS NULL OR $_target <= 0 '
    'THEN e.value > 0 ELSE e.value >= $_target END';

/// Drift-backed [MuhasabaRepository]. Aggregations run as SQL queries
/// (guide §5) — Dart only fills bounded calendars.
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
  Future<Result<void>> seedDefaults() async {
    try {
      // Insert-or-ignore: existing rows (edited or archived) stay as they
      // are. Defaults added in a later release reach existing installs
      // archived — opt-in, so past days' completion isn't diluted.
      final upgrade = await _db.trackerItems.count().getSingle() > 0;
      await _db.batch(
        (batch) => batch.insertAll(_db.trackerItems, [
          for (final item in DefaultTrackers.items())
            _toCompanion(
              upgrade ? item.copyWith(archived: true) : item,
            ).copyWith(
              createdOn: Value(_todayCode),
              addedOn: Value(_todayCode),
            ),
        ], mode: InsertMode.insertOrIgnore),
      );
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
      return Result.success(rows.map(_toDomain).nonNulls.toList());
    } on Object catch (e) {
      return Result.failure(UnexpectedFailure('Failed to load items', e));
    }
  }

  @override
  Future<Result<void>> upsertItem(TrackerItem item) async {
    try {
      await _db.transaction(() async {
        // created/added days are stamped on first insert only; edits keep
        // them. The archived flag changes only through [setArchived], which
        // keeps the archive-day bookkeeping.
        await _db.trackerItems.insertOne(
          _toCompanion(
            item,
          ).copyWith(createdOn: Value(_todayCode), addedOn: Value(_todayCode)),
          onConflict: DoUpdate(
            (_) => _toCompanion(item).copyWith(archived: const Value.absent()),
          ),
        );
        // A new target applies from today on; past days keep theirs.
        await (_db.update(_db.dailyEntries)..where(
              (t) =>
                  t.itemId.equals(item.id) &
                  t.date.isBiggerOrEqualValue(_todayCode),
            ))
            .write(DailyEntriesCompanion(target: Value(item.dailyTarget ?? 0)));
      });
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
      final today = _todayCode;
      // Flag/span updates only — entries are never deleted (hard product
      // rule). A no-op when the item is already in the requested state.
      await _db.transaction(() async {
        final row =
            await (_db.select(
                  _db.trackerItems,
                )..where((t) => t.id.equals(id) & t.archived.equals(!archived)))
                .getSingleOrNull();
        if (row == null) {
          return;
        }
        if (!archived) {
          final start = row.archivedOn;
          if (start == null) {
            // Seeded dormant (a default added by an update, never
            // counted): it starts counting today, not from the seed day.
            await (_db.update(
              _db.trackerItems,
            )..where((t) => t.id.equals(id))).write(
              TrackerItemsCompanion(
                createdOn: Value(today),
                addedOn: Value(today),
              ),
            );
          } else if (start < today) {
            // The archived days stay out of history; the days before keep
            // counting. A same-day undo leaves no span.
            await _db.trackerArchiveSpans.insertOnConflictUpdate(
              TrackerArchiveSpansCompanion.insert(
                itemId: id,
                startOn: start,
                endOn: today,
              ),
            );
          }
        }
        await (_db.update(
          _db.trackerItems,
        )..where((t) => t.id.equals(id))).write(
          TrackerItemsCompanion(
            archived: Value(archived),
            archivedOn: Value(archived ? today : null),
          ),
        );
      });
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
                target: r.target,
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
      // One transaction: drift runs transactions one at a time in call
      // order, so a quick on→off can't land its delete before the upsert.
      final archived = await _db.transaction(() async {
        final item = await (_db.select(
          _db.trackerItems,
        )..where((t) => t.id.equals(entry.itemId))).getSingleOrNull();
        // Clearing is refused too: an archived item's history is frozen.
        if (item != null && item.archived) {
          return true;
        }
        if (entry.value <= 0) {
          await (_db.delete(_db.dailyEntries)
                ..where((t) => t.itemId.equals(entry.itemId))
                ..where((t) => t.date.equals(code)))
              .go();
        } else {
          // A new row is stamped with the item's current target — also on
          // a back-filled past day (its old target isn't recorded anywhere).
          // 0 = no target, so adding one later can't reach this day. An
          // edit only changes the value: the day keeps the target it was
          // first logged against.
          await _db.dailyEntries.insertOne(
            DailyEntriesCompanion.insert(
              itemId: entry.itemId,
              date: code,
              value: entry.value,
              target: Value(item?.dailyTarget ?? 0),
            ),
            onConflict: DoUpdate(
              (_) => DailyEntriesCompanion(value: Value(entry.value)),
            ),
          );
        }
        // An entry before the creation day means the item existed then:
        // created_on follows the earliest entry, never past the real
        // creation day — so clearing a back-fill raises it back.
        await _db.customStatement(
          'UPDATE tracker_items SET created_on = MIN(added_on, COALESCE( '
          '(SELECT MIN(date) FROM daily_entries WHERE item_id = ?), added_on)) '
          'WHERE id = ? AND added_on IS NOT NULL',
          [entry.itemId, entry.itemId],
        );
        return false;
      });
      if (archived) {
        return const Result.failure(ArchivedTrackerFailure());
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

      // One transaction: every read sees the same snapshot (a write
      // landing mid-way can't mix old and new rows).
      final stats = await _db.transaction(() async {
        // Items that count on a given day (existed, not archived that day).
        final rows = await _db.select(_db.trackerItems).get();
        final spans = await _db.select(_db.trackerArchiveSpans).get();
        final revived = await _revivedDays();
        int countOn(DateTime day) {
          final code = _encodeDate(day);
          return rows.where((r) => _countsOn(r, spans, revived, code)).length;
        }

        // a) Day completions: SQL fraction sums, calendar filled in Dart.
        final fractionSums = await _dayFractionSums(startCode, endCode);
        final days = <DayCompletion>[];
        // The overall average counts only days that had items and have
        // come (as the per-item bars do): a new tracker's first perfect day
        // reads 100%, not 1/7.
        final todayCode = _encodeDate(today);
        var completionTotal = 0.0;
        var countedDays = 0;
        var todayUntouched = false;
        for (var i = 0; i < periodDays; i++) {
          final day = DateTime(start.year, start.month, start.day + i);
          final sum = fractionSums[_encodeDate(day)] ?? 0;
          final count = countOn(day);
          final completion = count == 0
              ? 0.0
              : (sum / count).clamp(0, 1).toDouble();
          if (count > 0 && _encodeDate(day) <= todayCode) {
            completionTotal += completion;
            countedDays++;
            todayUntouched |= _encodeDate(day) == todayCode && sum == 0;
          }
          days.add(DayCompletion(day, completion));
        }
        final completion = countedDays == 0
            ? 0.0
            : completionTotal / countedDays;
        // The trend compares against finished days, so a today with nothing
        // logged yet sits out (else every morning reads "down").
        final trendCompletion = !todayUntouched
            ? completion
            : countedDays > 1
            ? completionTotal / (countedDays - 1)
            : null;

        // b) Per-item aggregates over the range.
        final itemStats = await _itemStats(start, end, spans, revived);

        // c) Streaks over the whole history, so the best streak matches the
        // all-time streak badges and always includes (so is >=) the current
        // one.
        final (:currentStreak, :bestStreak) = await _streaks(today);

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
        // Null only when no tracker counted then; an empty window is 0%.
        double? previousCompletion;
        if (periodDays > 0) {
          var total = 0.0;
          var counted = 0;
          for (var i = 0; i < periodDays; i++) {
            final day = DateTime(
              prevStart.year,
              prevStart.month,
              prevStart.day + i,
            );
            final count = countOn(day);
            if (count > 0) {
              total += ((prevSums[_encodeDate(day)] ?? 0) / count).clamp(0, 1);
              counted++;
            }
          }
          previousCompletion = counted == 0 ? null : total / counted;
        }

        return PeriodStats(
          completion: completion,
          days: days,
          items: itemStats,
          currentStreak: currentStreak,
          bestStreak: bestStreak,
          previousCompletion: previousCompletion,
          trendCompletion: trendCompletion,
        );
      });
      return Result.success(stats);
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
            'AND $_knownKind AND ($_doneCase)',
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

  @override
  Future<Result<int>> doneDayCount(Set<String> itemIds) async {
    if (itemIds.isEmpty) {
      return const Result.success(0);
    }
    try {
      final row = await _db
          .customSelect(
            'SELECT COUNT(DISTINCT e.date) AS n '
            'FROM daily_entries e '
            'INNER JOIN tracker_items i ON i.id = e.item_id '
            'WHERE e.item_id IN (${List.filled(itemIds.length, '?').join(', ')}) '
            'AND $_knownKind AND ($_doneCase)',
            variables: [for (final id in itemIds) Variable<String>(id)],
            readsFrom: {_db.dailyEntries, _db.trackerItems},
          )
          .getSingle();
      return Result.success(row.read<int>('n'));
    } on Object catch (e) {
      return Result.failure(UnexpectedFailure('Failed to count done days', e));
    }
  }

  @override
  Future<Result<({int current, int best})>> streaks(DateTime today) async {
    try {
      final (:currentStreak, :bestStreak) = await _streaks(today);
      return Result.success((current: currentStreak, best: bestStreak));
    } on Object catch (e) {
      return Result.failure(UnexpectedFailure('Failed to compute streaks', e));
    }
  }

  /// Per-day sum of per-item completion fractions over the items that
  /// counted on that day, keyed by yyyymmdd. Days without entries are absent.
  Future<Map<int, double>> _dayFractionSums(int from, int to) async {
    final rows = await _db
        .customSelect(
          'SELECT e.date AS day, '
          'CAST(SUM(CASE '
          'WHEN $_target IS NULL OR $_target <= 0 '
          'THEN (CASE WHEN e.value > 0 THEN 1.0 ELSE 0.0 END) '
          'ELSE MIN(CAST(e.value AS REAL) / $_target, 1.0) '
          'END) AS REAL) AS fraction_sum '
          'FROM daily_entries e '
          'INNER JOIN tracker_items i ON i.id = e.item_id '
          'WHERE ($_existedOnEntryDay) AND $_knownKind '
          'AND e.date BETWEEN ? AND ? '
          'GROUP BY e.date',
          variables: [Variable<int>(from), Variable<int>(to)],
          readsFrom: {
            _db.dailyEntries,
            _db.trackerItems,
            _db.trackerArchiveSpans,
          },
        )
        .get();
    return {
      for (final row in rows)
        row.read<int>('day'): row.read<double>('fraction_sum'),
    };
  }

  /// `(itemId, yyyymmdd)` of entries back-filled into a past archive span
  /// — those days count for the item after all (few rows: back-fills only).
  Future<Set<(String, int)>> _revivedDays() async {
    final rows = await _db
        .customSelect(
          'SELECT e.item_id AS item_id, e.date AS day '
          'FROM daily_entries e '
          'INNER JOIN tracker_items i ON i.id = e.item_id '
          'WHERE $_inArchiveSpan',
          readsFrom: {
            _db.dailyEntries,
            _db.trackerItems,
            _db.trackerArchiveSpans,
          },
        )
        .get();
    return {
      for (final row in rows)
        (row.read<String>('item_id'), row.read<int>('day')),
    };
  }

  /// Current and best run of consecutive days with at least one completed
  /// item, as islands of consecutive day numbers in SQL. Archived items
  /// count (history is never lost) and hidden unknown-kind ones don't,
  /// matching the achievements' streaks. The current run may end
  /// yesterday: today still counts until it passes empty.
  Future<({int currentStreak, int bestStreak})> _streaks(DateTime today) async {
    const julian =
        "CAST(julianday(printf('%04d-%02d-%02d', "
        'day / 10000, day / 100 % 100, day % 100)) AS INTEGER)';
    final row = await _db
        .customSelect(
          'WITH d AS (SELECT DISTINCT e.date AS day FROM daily_entries e '
          'INNER JOIN tracker_items i ON i.id = e.item_id '
          'WHERE $_knownKind AND ($_doneCase)), '
          'j AS (SELECT $julian AS jd FROM d), '
          'runs AS (SELECT MIN(jd) AS first, MAX(jd) AS last, COUNT(*) AS len '
          'FROM (SELECT jd, jd - ROW_NUMBER() OVER (ORDER BY jd) AS grp FROM j) '
          'GROUP BY grp) '
          'SELECT COALESCE(MAX(len), 0) AS best, '
          'COALESCE(MAX(CASE WHEN first <= t.today AND last >= t.today - 1 '
          'THEN MIN(last, t.today) - first + 1 END), 0) AS current '
          'FROM runs, (SELECT $julian AS today FROM (SELECT ? AS day)) t',
          variables: [Variable<int>(_encodeDate(today))],
          readsFrom: {_db.dailyEntries, _db.trackerItems},
        )
        .getSingle();
    return (
      currentStreak: row.read<int>('current'),
      bestStreak: row.read<int>('best'),
    );
  }

  /// Per non-archived item: done-day count and value sum over the range;
  /// the bar's denominator is the days the item counted within it (from
  /// its creation, minus past archive spans bar their [revived] days).
  Future<List<ItemPeriodStats>> _itemStats(
    DateTime start,
    DateTime end,
    List<ArchiveSpanRow> spans,
    Set<(String, int)> revived,
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
          'AND NOT $_onPastArchiveDay '
          'WHERE i.archived = 0 '
          'GROUP BY i.id ORDER BY i.sort_order',
          variables: [Variable<int>(from), Variable<int>(to)],
          readsFrom: {_db.dailyEntries, _db.trackerItems},
        )
        .get();
    final stats = <ItemPeriodStats>[];
    for (final row in rows) {
      final kind = TrackerKind.fromCode(row.read<int>('kind'));
      if (kind == null) continue; // Unknown kind: hidden, like in items().
      final daysDone = row.read<int>('days_done');
      final isYesNo = kind == TrackerKind.yesNo;
      final itemId = row.read<String>('item_id');
      final createdOn = row.readNullable<int>('created_on');
      final firstDay = createdOn == null || createdOn <= from
          ? start
          : _decodeDate(createdOn);
      var existedDays = createdOn != null && createdOn > to
          ? 0
          : _dayCount(firstDay, end);
      for (final s in spans) {
        if (s.itemId != itemId || existedDays == 0) continue;
        // Overlap of [start_on, end_on) with [firstDay, end].
        final lo = _decodeDate(s.startOn);
        final hi = _decodeDate(s.endOn);
        final a = lo.isAfter(firstDay) ? lo : firstDay;
        final b = DateTime(hi.year, hi.month, hi.day - 1);
        final z = b.isBefore(end) ? b : end;
        if (!a.isAfter(z)) existedDays -= _dayCount(a, z);
      }
      if (createdOn == null || createdOn <= to) {
        final firstCode = _encodeDate(firstDay);
        existedDays += revived
            .where((r) => r.$1 == itemId && r.$2 >= firstCode && r.$2 <= to)
            .length;
      }
      stats.add(
        ItemPeriodStats(
          itemId: itemId,
          daysDone: daysDone,
          periodDays: existedDays,
          // yesNo totals are done-day counts, not raw value sums.
          totalValue: isYesNo ? daysDone : row.read<int>('total_value'),
        ),
      );
    }
    return stats;
  }

  /// Null for a row with an unknown kind code (e.g. written by a newer
  /// app version) — skipped, never deleted or rewritten.
  TrackerItem? _toDomain(TrackerItemRow row) {
    final kind = TrackerKind.fromCode(row.kind);
    if (kind == null) {
      debugPrint('Skipping tracker ${row.id}: unknown kind ${row.kind}');
      return null;
    }
    return TrackerItem(
      id: row.id,
      name: row.name,
      kind: kind,
      dailyTarget: row.dailyTarget,
      icon: row.icon,
      colorIndex: row.colorIndex,
      isDefault: row.isDefault,
      archived: row.archived,
      sortOrder: row.sortOrder,
    );
  }

  TrackerItemsCompanion _toCompanion(TrackerItem item) =>
      TrackerItemsCompanion.insert(
        id: item.id,
        name: item.name,
        kind: item.kind.code,
        dailyTarget: Value(item.dailyTarget),
        icon: item.icon,
        colorIndex: item.colorIndex,
        isDefault: item.isDefault,
        archived: Value(item.archived),
        sortOrder: item.sortOrder,
      );
}
