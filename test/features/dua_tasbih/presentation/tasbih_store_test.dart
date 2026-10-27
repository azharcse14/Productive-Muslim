import 'package:flutter_test/flutter_test.dart';
import 'package:productive_muslim/features/dua_tasbih/presentation/state/tasbih_store.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  TasbihStore makeStore({
    void Function()? haptic,
    void Function()? milestoneHaptic,
    DateTime Function()? now,
  }) => TasbihStore(
    SharedPreferencesAsync(),
    haptic: haptic ?? () {},
    milestoneHaptic: milestoneHaptic ?? () {},
    now: now ?? () => DateTime(2026, 6, 12, 9, 30),
  );

  group('TasbihStore', () {
    test('tap increments the count and fires the injected haptic', () {
      var haptics = 0;
      final store = makeStore(haptic: () => haptics++);

      store.tap();
      store.tap();
      store.tap();

      expect(store.count.value, 3);
      expect(haptics, 3);
      expect(store.totalToday.value, 0);
    });

    test('milestone pulses once when the count reaches the target', () {
      var milestones = 0;
      final store = makeStore(milestoneHaptic: () => milestones++)
        ..setTarget(3);

      store.tap();
      store.tap();
      expect(store.milestone.value, isFalse);

      store.tap();
      expect(store.milestone.value, isTrue);
      expect(milestones, 1);

      store.tap();
      expect(milestones, 1);
    });

    test(
      'an in-progress round survives a restart; undo takes one back',
      () async {
        final store = makeStore()..setTarget(100);
        store
          ..tap()
          ..tap()
          ..tap()
          ..undo();
        await pumpEventQueue();

        final restored = makeStore();
        await restored.load();
        expect(restored.count.value, 2);
        expect(restored.target.value, 100);

        restored
          ..undo()
          ..undo()
          ..undo();
        expect(restored.count.value, 0);
      },
    );

    test(
      'reset(saveToHistory: true) adds the round to today and persists',
      () async {
        final store = makeStore();
        store.tap();
        store.tap();

        await store.reset(saveToHistory: true);

        expect(store.count.value, 0);
        expect(store.milestone.value, isFalse);
        expect(store.totalToday.value, 2);

        // A fresh store on the same day restores the total.
        final restored = makeStore();
        await restored.load();
        expect(restored.totalToday.value, 2);
      },
    );

    test('reset(saveToHistory: false) discards the round', () async {
      final store = makeStore();
      store.tap();

      await store.reset(saveToHistory: false);

      expect(store.count.value, 0);
      expect(store.totalToday.value, 0);
    });

    test('date rollover resets today total', () async {
      final store = makeStore();
      store.tap();
      await store.reset(saveToHistory: true);
      expect(store.totalToday.value, 1);

      final tomorrow = makeStore(now: () => DateTime(2026, 6, 13, 5));
      await tomorrow.load();
      expect(tomorrow.totalToday.value, 0);
    });

    test('same (app-scoped) store resets today total after midnight', () async {
      var now = DateTime(2026, 6, 12, 23, 59);
      final store = makeStore(now: () => now);
      await store.load();
      store.tap();
      await store.reset(saveToHistory: true);
      expect(store.totalToday.value, 1);

      now = DateTime(2026, 6, 13, 0, 1);
      // Re-reading on the new day drops yesterday's total ...
      await store.load();
      expect(store.totalToday.value, 0);

      // ... and so does adding without a reload: a round started on the
      // 13th but saved on the 14th starts the 14th's total afresh.
      store.tap();
      await store.reset(saveToHistory: true);
      expect(store.totalToday.value, 1);
      store.tap();
      now = DateTime(2026, 6, 14, 8);
      await store.reset(saveToHistory: true);
      expect(store.totalToday.value, 1);
    });

    test(
      're-opening the screen (load again) keeps beads tapped meanwhile',
      () async {
        final store = makeStore();
        await store.load();
        store.tap();
        final reopen = store.load(); // screen initState
        store.tap(); // tapped before the reload would have finished
        await reopen;
        await Future<void>.delayed(Duration.zero);
        expect(store.count.value, 2);
      },
    );

    test('lifetime stats load even with no / corrupt today payload', () async {
      final prefs = SharedPreferencesAsync();
      await prefs.setString('tasbih_lifetime', '{"total": 99, "sessions": 3}');

      final fresh = makeStore();
      await fresh.load();
      expect(fresh.lifetimeTotal.value, 99);
      expect(fresh.lifetimeSessions.value, 3);

      await prefs.setString('tasbih_today', '{"date": ');
      final corrupt = makeStore();
      await corrupt.load();
      expect(corrupt.lifetimeTotal.value, 99);
    });

    test('custom target drives the milestone; invalid targets are ignored', () {
      var milestones = 0;
      final store = makeStore(milestoneHaptic: () => milestones++);
      expect(store.target.value, 33);

      store.setTarget(2);
      expect(store.target.value, 2);

      store.setTarget(0);
      expect(store.target.value, 2);

      store.tap();
      store.tap();
      expect(store.milestone.value, isTrue);
      expect(milestones, 1);

      // Raising the target above the count clears the milestone.
      store.setTarget(100);
      expect(store.milestone.value, isFalse);
    });

    test('load ignores a corrupt payload', () async {
      final prefs = SharedPreferencesAsync();
      await prefs.setString('tasbih_today', '{"date": ');

      final store = makeStore();
      await store.load();

      expect(store.totalToday.value, 0);
    });
  });
}
