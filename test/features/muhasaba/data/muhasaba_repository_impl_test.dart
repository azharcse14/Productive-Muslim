import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:productive_muslim/core/utils/result.dart';
import 'package:productive_muslim/features/muhasaba/data/database/muhasaba_database.dart';
import 'package:productive_muslim/features/muhasaba/data/repositories/muhasaba_repository_impl.dart';
import 'package:productive_muslim/features/muhasaba/domain/entities/daily_entry.dart';
import 'package:productive_muslim/features/muhasaba/domain/entities/period_stats.dart';
import 'package:productive_muslim/features/muhasaba/domain/entities/tracker_item.dart';

void main() {
  late MuhasabaDatabase db;
  late MuhasabaRepositoryImpl repo;

  setUp(() {
    db = MuhasabaDatabase(NativeDatabase.memory());
    repo = MuhasabaRepositoryImpl(db);
  });

  tearDown(() async {
    await db.close();
  });

  /// Unwraps a [Result], failing the test on failure.
  Future<T> unwrap<T>(Future<Result<T>> future) async {
    final result = await future;
    return result.fold(
      (value) => value,
      (f) => fail('Expected success, got failure: ${f.message}'),
    );
  }

  group('seedDefaultsIfEmpty', () {
    test('populates all defaults exactly once', () async {
      await unwrap(repo.seedDefaultsIfEmpty());
      final defaults = DefaultTrackers.items();
      final items = await unwrap(repo.items());
      expect(items.length, defaults.length);
      expect(items, defaults);

      // Second call is a no-op even after a mutation.
      await unwrap(
        repo.setArchived(DefaultTrackers.salahIds.first, archived: true),
      );
      await unwrap(repo.seedDefaultsIfEmpty());
      final after = await unwrap(repo.items(includeArchived: true));
      expect(after.length, defaults.length);
      expect(after.first.archived, isTrue);
    });
  });

  group('items', () {
    test('orders by sortOrder', () async {
      await unwrap(repo.upsertItem(_item('c', sortOrder: 2)));
      await unwrap(repo.upsertItem(_item('a', sortOrder: 0)));
      await unwrap(repo.upsertItem(_item('b', sortOrder: 1)));
      final items = await unwrap(repo.items());
      expect(items.map((i) => i.id).toList(), ['a', 'b', 'c']);
    });

    test('excludes archived by default, includes on request', () async {
      await unwrap(repo.upsertItem(_item('a', sortOrder: 0)));
      await unwrap(repo.upsertItem(_item('b', sortOrder: 1)));
      await unwrap(repo.setArchived('a', archived: true));

      final visible = await unwrap(repo.items());
      expect(visible.map((i) => i.id).toList(), ['b']);

      final all = await unwrap(repo.items(includeArchived: true));
      expect(all.map((i) => i.id).toList(), ['a', 'b']);
      expect(all.first.archived, isTrue);
    });
  });

  group('upsertItem', () {
    test('custom item insert + edit roundtrip', () async {
      const original = TrackerItem(
        id: 'custom',
        name: 'My habit',
        kind: TrackerKind.count,
        dailyTarget: 33,
        icon: 'beads',
        colorIndex: 4,
        sortOrder: 12,
      );
      await unwrap(repo.upsertItem(original));
      var items = await unwrap(repo.items());
      expect(items.single, original);

      final edited = original.copyWith(
        name: 'Renamed',
        dailyTarget: () => null,
        colorIndex: 2,
      );
      await unwrap(repo.upsertItem(edited));
      items = await unwrap(repo.items());
      expect(items.single, edited);
      expect(items.single.dailyTarget, isNull);
    });
  });

  group('setArchived', () {
    test('archive/restore preserves the item and its entries', () async {
      await unwrap(repo.upsertItem(_item('a', sortOrder: 0)));
      final date = DateTime(2026, 6, 12);
      await unwrap(repo.setEntry(_entry('a', date, 1)));

      await unwrap(repo.setArchived('a', archived: true));
      // Entries survive archiving — never deleted.
      var entries = await unwrap(repo.entriesOn(date));
      expect(entries.single.itemId, 'a');
      final archived = await unwrap(repo.items(includeArchived: true));
      expect(archived.single.archived, isTrue);

      await unwrap(repo.setArchived('a', archived: false));
      final restored = await unwrap(repo.items());
      expect(restored.single.archived, isFalse);
      entries = await unwrap(repo.entriesOn(date));
      expect(entries.single.value, 1);
    });
  });

  group('setEntry / entriesOn', () {
    test('upsert, overwrite, delete-on-zero', () async {
      await unwrap(repo.upsertItem(_item('a', sortOrder: 0)));
      final date = DateTime(2026, 6, 12);

      await unwrap(repo.setEntry(_entry('a', date, 5)));
      var entries = await unwrap(repo.entriesOn(date));
      expect(entries.single, _entry('a', date, 5));

      await unwrap(repo.setEntry(_entry('a', date, 9)));
      entries = await unwrap(repo.entriesOn(date));
      expect(entries.single.value, 9);

      await unwrap(repo.setEntry(_entry('a', date, 0)));
      entries = await unwrap(repo.entriesOn(date));
      expect(entries, isEmpty);
    });

    test('entriesOn isolates dates', () async {
      await unwrap(repo.upsertItem(_item('a', sortOrder: 0)));
      await unwrap(repo.setEntry(_entry('a', DateTime(2026, 6, 12), 3)));

      final on12th = await unwrap(repo.entriesOn(DateTime(2026, 6, 12)));
      expect(on12th, hasLength(1));
      expect(on12th.single.date, DateTime(2026, 6, 12));

      final on13th = await unwrap(repo.entriesOn(DateTime(2026, 6, 13)));
      expect(on13th, isEmpty);
    });
  });

  group('periodStats', () {
    final start = DateTime(2026, 6, 6);
    final end = DateTime(2026, 6, 12);
    final today = DateTime(2026, 6, 12);

    /// Items: a = yesNo (no target), b = count target 100,
    /// c = duration target 10. Entries over Jun 6–12, 2026:
    ///   Jun 6: nothing                         -> completion 0
    ///   Jun 7: a=1 (done)                      -> 1/3
    ///   Jun 8: b=100 (done), c=5 (half)        -> 1.5/3
    ///   Jun 9: b=40 (partial, not done)        -> 0.4/3
    ///   Jun 10: a=1 (done), c=10 (done)        -> 2/3
    ///   Jun 11: b=150 (done, clamped)          -> 1/3
    ///   Jun 12: a=1 (done)                     -> 1/3
    Future<void> seedScenario() async {
      await unwrap(
        repo.upsertItem(_item('a', sortOrder: 0)),
      );
      await unwrap(
        repo.upsertItem(
          _item('b', sortOrder: 1, kind: TrackerKind.count, dailyTarget: 100),
        ),
      );
      await unwrap(
        repo.upsertItem(
          _item('c', sortOrder: 2, kind: TrackerKind.duration, dailyTarget: 10),
        ),
      );
      await unwrap(repo.setEntry(_entry('a', DateTime(2026, 6, 7), 1)));
      await unwrap(repo.setEntry(_entry('b', DateTime(2026, 6, 8), 100)));
      await unwrap(repo.setEntry(_entry('c', DateTime(2026, 6, 8), 5)));
      await unwrap(repo.setEntry(_entry('b', DateTime(2026, 6, 9), 40)));
      await unwrap(repo.setEntry(_entry('a', DateTime(2026, 6, 10), 1)));
      await unwrap(repo.setEntry(_entry('c', DateTime(2026, 6, 10), 10)));
      await unwrap(repo.setEntry(_entry('b', DateTime(2026, 6, 11), 150)));
      await unwrap(repo.setEntry(_entry('a', DateTime(2026, 6, 12), 1)));
    }

    Future<PeriodStats> stats({DateTime? anchor}) => unwrap(
          repo.periodStats(start: start, end: end, today: anchor ?? today),
        );

    test('days: exactly 7 chronological entries including zero days',
        () async {
      await seedScenario();
      final result = await stats();
      expect(result.days, hasLength(7));
      for (var i = 0; i < 7; i++) {
        expect(result.days[i].date, DateTime(2026, 6, 6 + i));
      }
      final expected = [0.0, 1 / 3, 1.5 / 3, 0.4 / 3, 2 / 3, 1 / 3, 1 / 3];
      for (var i = 0; i < 7; i++) {
        expect(
          result.days[i].completion,
          closeTo(expected[i], 0.01),
          reason: 'day ${result.days[i].date}',
        );
      }
    });

    test('completion is the mean of day completions', () async {
      await seedScenario();
      final result = await stats();
      const mean = (0 + 1 / 3 + 1.5 / 3 + 0.4 / 3 + 2 / 3 + 1 / 3 + 1 / 3) / 7;
      expect(result.completion, closeTo(mean, 0.01));
    });

    test('per-item daysDone / totalValue / periodDays', () async {
      await seedScenario();
      final result = await stats();
      expect(result.items, hasLength(3));
      final byId = {for (final s in result.items) s.itemId: s};

      // a (yesNo): done Jun 7, 10, 12; totalValue = done-day count.
      expect(byId['a']!.daysDone, 3);
      expect(byId['a']!.totalValue, 3);
      expect(byId['a']!.periodDays, 7);

      // b (count, target 100): done Jun 8, 11; sum 100+40+150.
      expect(byId['b']!.daysDone, 2);
      expect(byId['b']!.totalValue, 290);

      // c (duration, target 10): done Jun 10; sum 5+10.
      expect(byId['c']!.daysDone, 1);
      expect(byId['c']!.totalValue, 15);
    });

    test('streaks: done-done-gap-done-done-done ending today', () async {
      await seedScenario();
      // Done days: 7, 8 | gap 9 | 10, 11, 12 (today).
      final result = await stats();
      expect(result.currentStreak, 3);
      expect(result.bestStreak, 3);
    });

    test('current streak survives an empty today (anchors at yesterday)',
        () async {
      await seedScenario();
      final result = await stats(anchor: DateTime(2026, 6, 13));
      // Jun 13 has nothing yet -> streak still counts Jun 10-12.
      expect(result.currentStreak, 3);
    });

    test('current streak is 0 when today and yesterday have no done items',
        () async {
      await seedScenario();
      final result = await stats(anchor: DateTime(2026, 6, 14));
      expect(result.currentStreak, 0);
      // Best streak within the range is unaffected.
      expect(result.bestStreak, 3);
    });

    test('previousCompletion: null without prior data, then correct',
        () async {
      await seedScenario();
      var result = await stats();
      expect(result.previousCompletion, isNull);

      // Prior week (May 30 - Jun 5): a done May 31 (1/3), b=50 on
      // Jun 2 (0.5/3). Mean over 7 days = (1/3 + 1/6) / 7.
      await unwrap(repo.setEntry(_entry('a', DateTime(2026, 5, 31), 1)));
      await unwrap(repo.setEntry(_entry('b', DateTime(2026, 6, 2), 50)));
      result = await stats();
      expect(result.previousCompletion, isNotNull);
      expect(result.previousCompletion, closeTo((1 / 3 + 1 / 6) / 7, 0.01));
    });

    test('archived items are excluded from completion math', () async {
      await seedScenario();
      // c has entries on Jun 8 and Jun 10; archiving must drop it from
      // the math while keeping its rows.
      await unwrap(repo.setArchived('c', archived: true));
      final result = await stats();

      expect(result.items.map((s) => s.itemId).toList(), ['a', 'b']);
      // Jun 10 was (a done + c done) / 3; now a done over 2 items.
      expect(result.days[4].completion, closeTo(0.5, 0.01));
      // Jun 8 was (b done + c half) / 3; now b done over 2 items.
      expect(result.days[2].completion, closeTo(0.5, 0.01));
      // c's entries still exist.
      final entries = await unwrap(repo.entriesOn(DateTime(2026, 6, 8)));
      expect(entries.map((e) => e.itemId), contains('c'));
    });

    test('best streak is never below the current streak', () async {
      await unwrap(repo.upsertItem(_item('a', sortOrder: 0)));
      // 10 consecutive done days ending Jun 12 — longer than a week range.
      for (var d = 3; d <= 12; d++) {
        await unwrap(repo.setEntry(_entry('a', DateTime(2026, 6, d), 1)));
      }
      final result = await stats();
      expect(result.currentStreak, 10);
      expect(result.bestStreak, 10);
    });

    test('doneDates: distinct days, archived items included', () async {
      await unwrap(repo.upsertItem(_item('a', sortOrder: 0)));
      await unwrap(repo.upsertItem(_item('b', sortOrder: 1)));
      await unwrap(repo.setEntry(_entry('a', DateTime(2026, 6, 4), 1)));
      await unwrap(repo.setEntry(_entry('b', DateTime(2026, 6, 4), 1)));
      await unwrap(repo.setEntry(_entry('b', DateTime(2026, 6, 2), 1)));
      await unwrap(repo.setArchived('b', archived: true));
      final days = await unwrap(repo.doneDates({'a', 'b'}));
      expect(days, {DateTime(2026, 6, 4), DateTime(2026, 6, 2)});
    });

    test('no items at all yields empty zeroed stats', () async {
      final result = await stats();
      expect(result.days, hasLength(7));
      expect(result.days.every((d) => d.completion == 0), isTrue);
      expect(result.completion, 0);
      expect(result.items, isEmpty);
      expect(result.currentStreak, 0);
      expect(result.bestStreak, 0);
      expect(result.previousCompletion, isNull);
    });
  });
}

TrackerItem _item(
  String id, {
  required int sortOrder,
  TrackerKind kind = TrackerKind.yesNo,
  int? dailyTarget,
}) =>
    TrackerItem(
      id: id,
      name: id,
      kind: kind,
      dailyTarget: dailyTarget,
      sortOrder: sortOrder,
    );

DailyEntry _entry(String itemId, DateTime date, int value) =>
    DailyEntry(itemId: itemId, date: date, value: value);
