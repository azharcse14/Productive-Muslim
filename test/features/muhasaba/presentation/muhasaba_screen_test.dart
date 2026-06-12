import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:qalbee/core/l10n/gen/app_localizations.dart';
import 'package:qalbee/core/theme/app_theme.dart';
import 'package:qalbee/core/utils/result.dart';
import 'package:qalbee/features/muhasaba/domain/entities/daily_entry.dart';
import 'package:qalbee/features/muhasaba/domain/entities/period_stats.dart';
import 'package:qalbee/features/muhasaba/domain/entities/tracker_item.dart';
import 'package:qalbee/features/muhasaba/domain/repositories/muhasaba_repository.dart';
import 'package:qalbee/features/muhasaba/presentation/screens/muhasaba_screen.dart';
import 'package:qalbee/features/muhasaba/presentation/state/muhasaba_store.dart';
import 'package:qalbee/features/muhasaba/presentation/widgets/tracker_row.dart';

/// In-memory [MuhasabaRepository] — just enough behavior for the screen.
final class InMemoryMuhasabaRepository implements MuhasabaRepository {
  final Map<String, TrackerItem> storedItems = {};

  /// itemId → (date-only → value).
  final Map<String, Map<DateTime, int>> storedEntries = {};

  static DateTime _d(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  int valueOn(String itemId, DateTime date) =>
      storedEntries[itemId]?[_d(date)] ?? 0;

  @override
  Future<Result<void>> seedDefaultsIfEmpty() async {
    if (storedItems.isEmpty) {
      for (final item in DefaultTrackers.items()) {
        storedItems[item.id] = item;
      }
    }
    return const Result.success(null);
  }

  @override
  Future<Result<List<TrackerItem>>> items({
    bool includeArchived = false,
  }) async {
    final list = [
      for (final item in storedItems.values)
        if (includeArchived || !item.archived) item,
    ]..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return Result.success(list);
  }

  @override
  Future<Result<void>> upsertItem(TrackerItem item) async {
    storedItems[item.id] = item;
    return const Result.success(null);
  }

  @override
  Future<Result<void>> setArchived(
    String id, {
    required bool archived,
  }) async {
    final existing = storedItems[id];
    if (existing != null) {
      storedItems[id] = existing.copyWith(archived: archived);
    }
    return const Result.success(null);
  }

  @override
  Future<Result<List<DailyEntry>>> entriesOn(DateTime date) async {
    final day = _d(date);
    return Result.success([
      for (final MapEntry(key: itemId, value: byDate) in storedEntries.entries)
        if (byDate[day] case final value? when value > 0)
          DailyEntry(itemId: itemId, date: day, value: value),
    ]);
  }

  @override
  Future<Result<void>> setEntry(DailyEntry entry) async {
    final day = _d(entry.date);
    final byDate = storedEntries.putIfAbsent(entry.itemId, () => {});
    if (entry.value <= 0) {
      byDate.remove(day);
    } else {
      byDate[day] = entry.value;
    }
    return const Result.success(null);
  }

  @override
  Future<Result<PeriodStats>> periodStats({
    required DateTime start,
    required DateTime end,
    required DateTime today,
  }) async {
    final active = [
      for (final item in storedItems.values)
        if (!item.archived) item,
    ];

    double completionOn(DateTime day) {
      if (active.isEmpty) {
        return 0;
      }
      var sum = 0.0;
      for (final item in active) {
        sum += item.fractionOf(valueOn(item.id, day));
      }
      return sum / active.length;
    }

    bool anyDoneOn(DateTime day) =>
        active.any((item) => valueOn(item.id, day) > 0);

    final days = <DayCompletion>[];
    for (var d = _d(start);
        !d.isAfter(_d(end));
        d = DateTime(d.year, d.month, d.day + 1)) {
      days.add(DayCompletion(d, completionOn(d)));
    }
    final completion = days.isEmpty
        ? 0.0
        : days.fold(0.0, (sum, d) => sum + d.completion) / days.length;

    final itemStats = [
      for (final item in active)
        ItemPeriodStats(
          itemId: item.id,
          daysDone: days
              .where((d) => item.isDone(valueOn(item.id, d.date)))
              .length,
          periodDays: days.length,
          totalValue:
              days.fold(0, (sum, d) => sum + valueOn(item.id, d.date)),
        ),
    ];

    var current = 0;
    var cursor = _d(today);
    if (!anyDoneOn(cursor)) {
      cursor = DateTime(cursor.year, cursor.month, cursor.day - 1);
    }
    while (anyDoneOn(cursor)) {
      current++;
      cursor = DateTime(cursor.year, cursor.month, cursor.day - 1);
    }

    var best = current;
    var run = 0;
    for (final d in days) {
      run = anyDoneOn(d.date) ? run + 1 : 0;
      if (run > best) {
        best = run;
      }
    }

    double? previousCompletion;
    if (days.isNotEmpty) {
      var prevSum = 0.0;
      var hasPrior = false;
      for (var i = 1; i <= days.length; i++) {
        final d = DateTime(start.year, start.month, start.day - i);
        prevSum += completionOn(d);
        hasPrior = hasPrior || anyDoneOn(d);
      }
      previousCompletion = hasPrior ? prevSum / days.length : null;
    }

    return Result.success(
      PeriodStats(
        completion: completion,
        days: days,
        items: itemStats,
        currentStreak: current,
        bestStreak: best,
        previousCompletion: previousCompletion,
      ),
    );
  }
}

Widget _app() => MaterialApp(
      theme: AppTheme.light(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const MuhasabaScreen(),
    );

void main() {
  late InMemoryMuhasabaRepository repo;
  late MuhasabaStore store;

  setUp(() async {
    repo = InMemoryMuhasabaRepository();
    store = MuhasabaStore(repo);
    await store.load();
    GetIt.I.registerSingleton<MuhasabaStore>(store);
  });

  tearDown(() => GetIt.I.reset());

  Future<void> pumpAndDismissWelcome(WidgetTester tester) async {
    await tester.pumpWidget(_app());
    await tester.tap(find.text("Bismillah, let's begin"));
    await tester.pump();
  }

  group('MuhasabaScreen', () {
    testWidgets('first-day welcome shows then dismisses via start button',
        (tester) async {
      await tester.pumpWidget(_app());
      expect(find.text('Your daily muhasaba'), findsOneWidget);
      expect(find.text("Bismillah, let's begin"), findsOneWidget);

      await tester.tap(find.text("Bismillah, let's begin"));
      await tester.pump();

      expect(find.text('Your daily muhasaba'), findsNothing);
      expect(find.text('Fajr prayer'), findsOneWidget);
    });

    testWidgets('checklist renders salah chips and tracker rows',
        (tester) async {
      await pumpAndDismissWelcome(tester);
      for (final name in [
        'Fajr prayer',
        'Dhuhr prayer',
        'Asr prayer',
        'Maghrib prayer',
        'Isha prayer',
      ]) {
        expect(find.text(name), findsOneWidget);
      }
      expect(find.text('Quran reading'), findsOneWidget);
      expect(find.text('Azkar'), findsOneWidget);
    });

    testWidgets('tapping a salah chip persists value 1', (tester) async {
      await pumpAndDismissWelcome(tester);
      await tester.tap(find.text('Fajr prayer'));
      await tester.pump();
      expect(repo.valueOn('salah_fajr', DateTime.now()), 1);
    });

    testWidgets('count stepper + persists the incremented value',
        (tester) async {
      await pumpAndDismissWelcome(tester);
      final azkarRow = find.ancestor(
        of: find.text('Azkar'),
        matching: find.byType(TrackerRow),
      );
      await tester.tap(
        find.descendant(of: azkarRow, matching: find.byIcon(Icons.add)),
      );
      await tester.pump();
      expect(repo.valueOn('azkar', DateTime.now()), 1);
    });

    testWidgets('dashboard shows period segments and completion card',
        (tester) async {
      await store.setValue('salah_fajr', 1);
      await tester.pumpWidget(_app());
      await tester.tap(find.text('Dashboard'));
      await tester.pumpAndSettle();

      expect(find.text('Week'), findsOneWidget);
      expect(find.text('Month'), findsOneWidget);
      expect(find.text('Year'), findsOneWidget);
      expect(find.text('Overall completion'), findsOneWidget);
      expect(find.text('1 day streak'), findsOneWidget);
    });

    testWidgets('app bar add button opens the item editor sheet',
        (tester) async {
      await pumpAndDismissWelcome(tester);
      await tester.tap(
        find.descendant(
          of: find.byType(AppBar),
          matching: find.byIcon(Icons.add),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Add item'), findsOneWidget);
    });
  });
}
