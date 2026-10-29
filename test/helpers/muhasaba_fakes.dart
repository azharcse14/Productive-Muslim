import 'dart:async';

import 'package:productive_muslim/core/utils/result.dart';
import 'package:productive_muslim/features/muhasaba/domain/entities/daily_entry.dart';
import 'package:productive_muslim/features/muhasaba/domain/entities/period_stats.dart';
import 'package:productive_muslim/features/muhasaba/domain/entities/tracker_item.dart';
import 'package:productive_muslim/features/muhasaba/domain/repositories/muhasaba_repository.dart';
import 'package:productive_muslim/features/muhasaba/presentation/state/muhasaba_store.dart';

/// In-memory MuhasabaRepository good enough for store/screen tests.
/// Aggregation mirrors the domain semantics over its maps (bounded data).
final class InMemoryMuhasabaRepository implements MuhasabaRepository {
  final items_ = <String, TrackerItem>{};

  /// (itemId, yyyymmdd) → value.
  final entries_ = <(String, int), int>{};
  int seeds = 0;

  static int _key(DateTime d) => d.year * 10000 + d.month * 100 + d.day;

  @override
  Future<Result<void>> seedDefaultsIfEmpty() async {
    if (items_.isEmpty) {
      seeds++;
      for (final item in DefaultTrackers.items()) {
        items_[item.id] = item;
      }
    }
    return const Result.success(null);
  }

  @override
  Future<Result<List<TrackerItem>>> items({
    bool includeArchived = false,
  }) async {
    if (includeArchived) allItemsCalls++;
    final list =
        items_.values.where((i) => includeArchived || !i.archived).toList()
          ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return Result.success(list);
  }

  /// When true, [upsertItem] and [setArchived] fail without writing.
  bool failItemWrites = false;

  @override
  Future<Result<void>> upsertItem(TrackerItem item) async {
    if (failItemWrites) {
      return const Result.failure(UnexpectedFailure('save failed'));
    }
    items_[item.id] = item;
    return const Result.success(null);
  }

  @override
  Future<Result<void>> setArchived(String id, {required bool archived}) async {
    if (failItemWrites) {
      return const Result.failure(UnexpectedFailure('save failed'));
    }
    final item = items_[id];
    if (item != null) {
      items_[id] = item.copyWith(archived: archived);
    }
    return const Result.success(null);
  }

  @override
  Future<Result<List<DailyEntry>>> entriesOn(DateTime date) async {
    final k = _key(date);
    return Result.success([
      for (final entry in entries_.entries)
        if (entry.key.$2 == k)
          DailyEntry(itemId: entry.key.$1, date: date, value: entry.value),
    ]);
  }

  /// When set, the next [setEntry] waits on it and fails if it yields false.
  Completer<bool>? gate;

  @override
  Future<Result<void>> setEntry(DailyEntry entry) async {
    if (gate case final g?) {
      gate = null;
      if (!await g.future) {
        return const Result.failure(UnexpectedFailure('save failed'));
      }
    }
    final key = (entry.itemId, _key(entry.date));
    if (entry.value <= 0) {
      entries_.remove(key);
    } else {
      entries_[key] = entry.value;
    }
    return const Result.success(null);
  }

  /// periodStats() call count (single-flight tests).
  int periodStatsCalls = 0;
  int allItemsCalls = 0;

  /// When set, the next [periodStats] waits on it (out-of-order replies).
  Completer<void>? statsGate;

  @override
  Future<Result<PeriodStats>> periodStats({
    required DateTime start,
    required DateTime end,
    required DateTime today,
  }) async {
    periodStatsCalls++;
    if (statsGate case final g?) {
      statsGate = null;
      await g.future;
    }
    final active = items_.values.where((i) => !i.archived).toList();
    final days = <DayCompletion>[];
    var day = DateTime(start.year, start.month, start.day);
    while (!day.isAfter(end)) {
      var sum = 0.0;
      for (final item in active) {
        final value = entries_[(item.id, _key(day))] ?? 0;
        sum += item.fractionOf(value);
      }
      days.add(DayCompletion(day, active.isEmpty ? 0 : sum / active.length));
      day = day.add(const Duration(days: 1));
    }
    final completion = days.isEmpty
        ? 0.0
        : days.map((d) => d.completion).reduce((a, b) => a + b) / days.length;
    final itemStats = [
      for (final item in active)
        ItemPeriodStats(
          itemId: item.id,
          daysDone: days
              .where((d) => item.isDone(entries_[(item.id, _key(d.date))] ?? 0))
              .length,
          periodDays: days.length,
          totalValue: days
              .map((d) => entries_[(item.id, _key(d.date))] ?? 0)
              .fold(0, (a, b) => a + b),
        ),
    ];
    bool dayHasDone(DateTime d) =>
        active.any((item) => item.isDone(entries_[(item.id, _key(d))] ?? 0));
    var current = 0;
    var probe = today;
    if (!dayHasDone(probe)) {
      probe = probe.subtract(const Duration(days: 1));
    }
    while (dayHasDone(probe)) {
      current++;
      probe = probe.subtract(const Duration(days: 1));
    }
    var best = 0;
    var run = 0;
    for (final d in days) {
      run = dayHasDone(d.date) ? run + 1 : 0;
      if (run > best) {
        best = run;
      }
    }
    return Result.success(
      PeriodStats(
        completion: completion,
        days: days,
        items: itemStats,
        currentStreak: current,
        bestStreak: best,
      ),
    );
  }

  @override
  Future<Result<Set<DateTime>>> doneDates(Set<String> itemIds) async =>
      Result.success({
        for (final MapEntry(key: (id, day), value: v) in entries_.entries)
          if (itemIds.contains(id) && (items_[id]?.isDone(v) ?? false))
            DateTime(day ~/ 10000, (day % 10000) ~/ 100, day % 100),
      });
}

Future<(MuhasabaStore, InMemoryMuhasabaRepository)> makeMuhasabaStore({
  DateTime Function()? now,
  Set<String> Function(DateTime date)? lockedSalahOn,
  // Stats follow each setValue immediately unless a test opts in.
  Duration statsDebounce = Duration.zero,
}) async {
  final repo = InMemoryMuhasabaRepository();
  final store = MuhasabaStore(
    repo,
    now: now,
    lockedSalahOn: lockedSalahOn,
    statsDebounce: statsDebounce,
  );
  await store.load();
  return (store, repo);
}
