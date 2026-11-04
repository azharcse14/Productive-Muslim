import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:productive_muslim/core/l10n/gen/app_localizations.dart';
import 'package:productive_muslim/core/theme/app_theme.dart';
import 'package:productive_muslim/features/achievements/presentation/state/achievement_store.dart';
import 'package:productive_muslim/features/achievements/presentation/widgets/badge_unlock_listener.dart';
import 'package:productive_muslim/features/muhasaba/domain/entities/daily_entry.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../helpers/muhasaba_fakes.dart';

const _toast = 'New badge: Three in a row';

void main() {
  late InMemoryMuhasabaRepository repo;
  late AchievementStore store;
  late Signal<int> activity;
  late Signal<bool> enabled;
  late Signal<bool> paused;

  setUp(() async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    repo = InMemoryMuhasabaRepository();
    await repo.seedDefaults();
    store = AchievementStore(
      muhasaba: repo,
      prefs: SharedPreferencesAsync(),
      now: () => DateTime(2026, 6, 10),
    );
    await store.load();
    activity = signal(0);
    enabled = signal(true);
    paused = signal(false);
  });

  Widget app({Key? key}) => MaterialApp(
    theme: AppTheme.light(),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: BadgeUnlockListener(
      key: key,
      store: store,
      enabled: () => enabled.value,
      paused: () => paused.value,
      watchActivity: () => activity.value,
      child: const Scaffold(body: Text('any tab')),
    ),
  );

  /// Logs a 3-day streak (unlocks "Three in a row") and signals activity.
  Future<void> unlockStreak(WidgetTester tester) async {
    for (final day in [8, 9, 10]) {
      await repo.setEntry(
        DailyEntry(
          itemId: 'salah_fajr',
          date: DateTime(2026, 6, day),
          value: 1,
        ),
      );
    }
    activity.value++;
    await tester.pump();
    await tester.pump();
  }

  Future<void> dismissToast(WidgetTester tester) async {
    // A snackbar with an action stays until dismissed.
    tester
        .state<ScaffoldMessengerState>(find.byType(ScaffoldMessenger))
        .hideCurrentSnackBar();
    await tester.pumpAndSettle();
  }

  testWidgets('an unlock toasts once, wherever the user is', (tester) async {
    await tester.pumpWidget(app());
    await tester.pump();
    expect(find.text(_toast), findsNothing);

    await unlockStreak(tester);
    expect(find.text(_toast), findsOneWidget);
    expect(find.text('View'), findsOneWidget);

    await dismissToast(tester);
    // More activity and a rebuild: the same badge never toasts again.
    activity.value++;
    await tester.pumpWidget(app());
    await tester.pump();
    await tester.pump();
    expect(find.text(_toast), findsNothing);
  });

  testWidgets('a pending badge is not replayed by a new shell (restart)', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    await unlockStreak(tester);
    await dismissToast(tester);

    // A fresh listener (cold start / shell remount) with the badge unseen.
    await tester.pumpWidget(app(key: UniqueKey()));
    await tester.pump();
    activity.value++;
    await tester.pump();
    await tester.pump();
    expect(store.newlyUnlocked.value, isNotEmpty);
    expect(find.text(_toast), findsNothing);
  });

  testWidgets('a badge that re-locks and unlocks again toasts once', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    await unlockStreak(tester);
    expect(find.text(_toast), findsOneWidget);
    await dismissToast(tester);

    Future<void> setDay10(int value) async {
      await repo.setEntry(
        DailyEntry(
          itemId: 'salah_fajr',
          date: DateTime(2026, 6, 10),
          value: value,
        ),
      );
      activity.value++;
      await tester.pump();
      await tester.pump();
    }

    await setDay10(0); // untick: the streak badge re-locks
    expect(store.newlyUnlocked.value, isEmpty);
    await setDay10(1); // retick: unlocked again
    expect(store.newlyUnlocked.value, isNotEmpty);
    expect(find.text(_toast), findsNothing);
  });

  testWidgets('a failed first load still toasts once a refresh succeeds', (
    tester,
  ) async {
    // Three in a row was already unlocked before this session.
    for (final day in [8, 9, 10]) {
      await repo.setEntry(
        DailyEntry(
          itemId: 'salah_fajr',
          date: DateTime(2026, 6, day),
          value: 1,
        ),
      );
    }
    repo.failItemReads = true;
    store = AchievementStore(
      muhasaba: repo,
      prefs: SharedPreferencesAsync(),
      now: () => DateTime(2026, 6, 10),
    );
    await expectLater(store.load(), throwsA(anything));
    await tester.pumpWidget(app());
    await tester.pump();

    // Recovered: the next scan baselines the old badge, no toast.
    repo.failItemReads = false;
    activity.value++;
    await tester.pump();
    await tester.pump();
    expect(store.loaded.value, isTrue);
    expect(find.textContaining('New badge'), findsNothing);

    // A real unlock afterwards toasts.
    for (var day = 4; day <= 7; day++) {
      await repo.setEntry(
        DailyEntry(
          itemId: 'salah_fajr',
          date: DateTime(2026, 6, day),
          value: 1,
        ),
      );
    }
    activity.value++;
    await tester.pump();
    await tester.pump();
    expect(find.text('New badge: A steady week'), findsOneWidget);
  });

  testWidgets('with achievements hidden nothing toasts', (tester) async {
    enabled.value = false;
    await tester.pumpWidget(app());
    await unlockStreak(tester);
    expect(find.text(_toast), findsNothing);
    // Evaluated meanwhile (e.g. by the badge wall).
    await store.refresh();

    // Turning them on takes the current badges as the baseline.
    enabled.value = true;
    await tester.pump();
    await tester.pump();
    expect(find.text(_toast), findsNothing);
  });

  testWidgets('an unlock found by its own first scan toasts', (tester) async {
    // Logged after the store loaded: only the listener's scan sees it.
    for (final day in [8, 9, 10]) {
      await repo.setEntry(
        DailyEntry(
          itemId: 'salah_fajr',
          date: DateTime(2026, 6, day),
          value: 1,
        ),
      );
    }
    await tester.pumpWidget(app());
    await tester.pump();
    await tester.pump();
    expect(find.text(_toast), findsOneWidget);
  });

  testWidgets('a locked section holds the toast until unlocked', (
    tester,
  ) async {
    paused.value = true;
    await tester.pumpWidget(app());
    await tester.pump();
    await unlockStreak(tester);
    expect(find.text(_toast), findsNothing);

    paused.value = false;
    await tester.pump();
    expect(find.text(_toast), findsOneWidget);
  });

  testWidgets('locking the section drops a showing toast', (tester) async {
    await tester.pumpWidget(app());
    await unlockStreak(tester);
    expect(find.text(_toast), findsOneWidget);

    paused.value = true;
    await tester.pumpAndSettle();
    expect(find.text(_toast), findsNothing);
  });

  testWidgets('several unlocks at once each toast, one after another', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    await tester.pump();
    // Ten days of fajr: Three in a row, A steady week, Ten days of salah.
    for (var day = 1; day <= 10; day++) {
      await repo.setEntry(
        DailyEntry(
          itemId: 'salah_fajr',
          date: DateTime(2026, 6, day),
          value: 1,
        ),
      );
    }
    activity.value++;
    await tester.pump();
    await tester.pump();
    final seen = <String>{};
    for (var i = 0; i < 3; i++) {
      await tester.pumpAndSettle();
      final text = tester.widget<Text>(find.textContaining('New badge')).data!;
      seen.add(text);
      await tester.pump(const Duration(seconds: 5)); // auto-dismiss
    }
    expect(seen, {
      'New badge: Three in a row',
      'New badge: A steady week',
      'New badge: Ten days of salah',
    });
  });
}
