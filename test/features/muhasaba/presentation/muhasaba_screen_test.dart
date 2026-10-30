import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';
import 'package:productive_muslim/core/l10n/gen/app_localizations.dart';
import 'package:productive_muslim/core/theme/app_theme.dart';
import 'package:productive_muslim/core/utils/result.dart';
import 'package:productive_muslim/features/achievements/presentation/state/achievement_store.dart';
import 'package:productive_muslim/features/achievements/presentation/widgets/achievements_summary_card.dart';
import 'package:productive_muslim/features/muhasaba/domain/entities/daily_entry.dart';
import 'package:productive_muslim/features/muhasaba/domain/entities/period_stats.dart';
import 'package:productive_muslim/features/muhasaba/domain/entities/tracker_item.dart';
import 'package:productive_muslim/features/muhasaba/domain/repositories/muhasaba_repository.dart';
import 'package:productive_muslim/features/muhasaba/presentation/screens/muhasaba_screen.dart';
import 'package:productive_muslim/features/muhasaba/presentation/state/muhasaba_store.dart';
import 'package:productive_muslim/features/muhasaba/presentation/widgets/tracker_row.dart';
import 'package:productive_muslim/features/settings/domain/entities/app_settings.dart';
import 'package:productive_muslim/features/settings/presentation/state/settings_store.dart';
import 'package:productive_muslim/shared/widgets/q_button.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import '../../../helpers/settings_fakes.dart';

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
  Future<Result<void>> seedDefaults() async {
    final upgrade = storedItems.isNotEmpty;
    for (final item in DefaultTrackers.items()) {
      storedItems.putIfAbsent(
        item.id,
        () => upgrade ? item.copyWith(archived: true) : item,
      );
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
  Future<Result<void>> reorder(List<String> ids) async {
    for (final (i, id) in ids.indexed) {
      if (storedItems[id] case final item?) {
        storedItems[id] = item.copyWith(sortOrder: i);
      }
    }
    return const Result.success(null);
  }

  @override
  Future<Result<void>> setArchived(String id, {required bool archived}) async {
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
    for (
      var d = _d(start);
      !d.isAfter(_d(end));
      d = DateTime(d.year, d.month, d.day + 1)
    ) {
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
          totalValue: days.fold(0, (sum, d) => sum + valueOn(item.id, d.date)),
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

  @override
  Future<Result<Set<DateTime>>> doneDates(Set<String> itemIds) async =>
      Result.success({
        for (final id in itemIds)
          for (final MapEntry(key: day, value: v)
              in (storedEntries[id] ?? const <DateTime, int>{}).entries)
            if (storedItems[id]?.isDone(v) ?? false) day,
      });
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
    store = MuhasabaStore(repo, statsDebounce: Duration.zero);
    await store.load();
    GetIt.I.registerSingleton<MuhasabaStore>(store);
    // The dashboard embeds the achievements summary card.
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    GetIt.I.registerSingleton<AchievementStore>(
      AchievementStore(muhasaba: repo, prefs: SharedPreferencesAsync()),
    );
    GetIt.I.registerSingleton<SettingsStore>(await makeSettingsStore());
  });

  tearDown(() => GetIt.I.reset());

  Future<void> pumpAndDismissWelcome(WidgetTester tester) async {
    await tester.pumpWidget(_app());
    await tester.tap(find.text("Bismillah, let's begin"));
    await tester.pumpAndSettle(); // let the list cascade land
  }

  group('MuhasabaScreen', () {
    testWidgets('horizontal fling pages the day; never past today', (
      tester,
    ) async {
      await pumpAndDismissWelcome(tester);
      final today = store.selectedDate.value;
      final list = find.byType(ListView).first;

      // Toward the next day from today: blocked.
      await tester.fling(list, const Offset(-300, 0), 1000);
      await tester.pumpAndSettle();
      expect(store.selectedDate.value, today);

      // Back a day.
      await tester.fling(list, const Offset(300, 0), 1000);
      await tester.pumpAndSettle();
      expect(
        store.selectedDate.value,
        DateTime(today.year, today.month, today.day - 1),
      );
    });

    testWidgets('first-day welcome shows then dismisses via start button', (
      tester,
    ) async {
      await tester.pumpWidget(_app());
      expect(find.text('Your daily muhasaba'), findsOneWidget);
      expect(find.text("Bismillah, let's begin"), findsOneWidget);

      await tester.tap(find.text("Bismillah, let's begin"));
      await tester.pump();

      expect(find.text('Your daily muhasaba'), findsNothing);
      expect(find.text('Fajr'), findsOneWidget);
    });

    testWidgets('checklist renders salah chips and tracker rows', (
      tester,
    ) async {
      await pumpAndDismissWelcome(tester);
      for (final name in ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha']) {
        expect(find.text(name), findsOneWidget);
      }
      expect(find.text('Quran reading'), findsOneWidget);
      expect(find.text('Azkar'), findsOneWidget);
    });

    testWidgets('tapping a salah chip persists value 1', (tester) async {
      await pumpAndDismissWelcome(tester);
      await tester.tap(find.text('Fajr'));
      await tester.pump();
      expect(repo.valueOn('salah_fajr', DateTime.now()), 1);
    });

    testWidgets('locked salah chip is disabled and ignores taps', (
      tester,
    ) async {
      await GetIt.I.reset();
      final lockedRepo = InMemoryMuhasabaRepository();
      final lockedStore = MuhasabaStore(
        lockedRepo,
        lockedSalahOn: (_) => {'salah_asr'},
        statsDebounce: Duration.zero,
      );
      await lockedStore.load();
      GetIt.I.registerSingleton<MuhasabaStore>(lockedStore);

      await pumpAndDismissWelcome(tester);
      // The locked Asr chip carries a quiet clock icon instead of the mosque.
      expect(find.byIcon(Icons.schedule), findsOneWidget);
      await tester.tap(find.text('Asr'));
      await tester.pump();
      // Value stays unset, and a toast explains why.
      expect(lockedRepo.valueOn('salah_asr', DateTime.now()), 0);
      expect(
        find.text("This prayer's time hasn't started yet"),
        findsOneWidget,
      );
    });

    testWidgets('date picker ends at the store today, not the device day', (
      tester,
    ) async {
      // Manual city a day ahead of the device (NY evening → Dhaka morning).
      final ahead = DateTime.now().add(const Duration(days: 1));
      final aheadStore = MuhasabaStore(
        InMemoryMuhasabaRepository(),
        now: () => ahead,
        statsDebounce: Duration.zero,
      );
      await aheadStore.load();
      GetIt.I.unregister<MuhasabaStore>();
      GetIt.I.registerSingleton<MuhasabaStore>(aheadStore);

      await pumpAndDismissWelcome(tester);
      await tester.tap(find.text(DateFormat.MMMEd('en').format(ahead)));
      await tester.pumpAndSettle();
      final picker = tester.widget<DatePickerDialog>(
        find.byType(DatePickerDialog),
      );
      expect(picker.lastDate, aheadStore.today);
      expect(picker.initialDate, aheadStore.today);
    });

    testWidgets('count stepper + persists the incremented value', (
      tester,
    ) async {
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

    testWidgets('dashboard shows period segments and completion card', (
      tester,
    ) async {
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

    testWidgets('achievements card is hidden by default, shown when enabled', (
      tester,
    ) async {
      await store.setValue('salah_fajr', 1);
      await tester.pumpWidget(_app());
      await tester.tap(find.text('Dashboard'));
      await tester.pumpAndSettle();
      expect(find.byType(AchievementsSummaryCard), findsNothing);

      await GetIt.I.reset();
      GetIt.I
        ..registerSingleton<MuhasabaStore>(store)
        ..registerSingleton<AchievementStore>(
          AchievementStore(muhasaba: repo, prefs: SharedPreferencesAsync()),
        )
        ..registerSingleton<SettingsStore>(
          await makeSettingsStore(const AppSettings(showAchievements: true)),
        );
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(_app());
      await tester.tap(find.text('Dashboard'));
      await tester.pumpAndSettle();
      expect(find.byType(AchievementsSummaryCard), findsOneWidget);
    });

    testWidgets('item editor: Save needs a name; closing asks before discard', (
      tester,
    ) async {
      await pumpAndDismissWelcome(tester);
      await tester.tap(
        find.descendant(
          of: find.byType(AppBar),
          matching: find.byIcon(Icons.add),
        ),
      );
      await tester.pumpAndSettle();
      final save = find.widgetWithText(QButton, 'Save');
      expect(tester.widget<QButton>(save).onPressed, isNull);

      await tester.enterText(find.byType(TextField), 'Walk');
      await tester.pump();
      expect(tester.widget<QButton>(save).onPressed, isNotNull);

      // Back with a typed name: confirm first; Cancel keeps the sheet.
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Discard your changes?'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Add item'), findsOneWidget);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Discard'));
      await tester.pumpAndSettle();
      expect(find.text('Add item'), findsNothing);
      expect(store.items.value.any((i) => i.name == 'Walk'), isFalse);
    });

    testWidgets('app bar add button opens the item editor sheet', (
      tester,
    ) async {
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
