import 'package:flutter_test/flutter_test.dart';
import 'package:productive_muslim/features/dua_tasbih/presentation/state/tasbih_store.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

/// Records the order of string writes.
final class _RecordingPrefs extends InMemorySharedPreferencesAsync {
  _RecordingPrefs() : super.empty();

  final writes = <String>[];

  @override
  Future<bool> setString(
    String key,
    String value,
    SharedPreferencesOptions options,
  ) {
    writes.add(key);
    return super.setString(key, value, options);
  }
}

/// Prefs whose writes to [failKey] fail (full disk, platform error).
final class _FailingKeyPrefs extends InMemorySharedPreferencesAsync {
  _FailingKeyPrefs(this.failKey) : super.empty();

  final String failKey;

  @override
  Future<bool> setString(
    String key,
    String value,
    SharedPreferencesOptions options,
  ) => key == failKey
      ? Future.error(StateError('disk full'))
      : super.setString(key, value, options);
}

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

    test('taps during a saving reset start the next round', () async {
      final store = makeStore()
        ..tap()
        ..tap()
        ..tap();

      final saving = store.reset(saveToHistory: true);
      store
        ..tap()
        ..tap();
      await saving;

      expect(store.count.value, 2);
      expect(store.totalToday.value, 3);
      expect(store.lifetimeTotal.value, 3);
    });

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
      // 13th but saved on the 14th belongs to the 13th, so the 14th's total
      // starts at zero (the beads still count towards lifetime).
      store.tap();
      await store.reset(saveToHistory: true);
      expect(store.totalToday.value, 1);
      store.tap();
      now = DateTime(2026, 6, 14, 8);
      final lifetimeBefore = store.lifetimeTotal.value;
      await store.reset(saveToHistory: true);
      expect(store.totalToday.value, 0);
      expect(store.lifetimeTotal.value, lifetimeBefore + 1);
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

    test(
      'a target below the count saves the round and starts a fresh one',
      () async {
        var milestones = 0;
        final store = makeStore(milestoneHaptic: () => milestones++);
        await store.load();
        store.setTarget(100);
        for (var i = 0; i < 70; i++) {
          store.tap();
        }

        store.setTarget(33);
        expect(store.count.value, 0);
        expect(store.target.value, 33);
        await pumpEventQueue();
        expect(store.totalToday.value, 70);
        expect(store.lifetimeSessions.value, 1);

        // The new round can reach its target again.
        for (var i = 0; i < 33; i++) {
          store.tap();
        }
        expect(store.milestone.value, isTrue);
        expect(milestones, 1);

        // Equal to the count keeps the round.
        store.setTarget(33);
        expect(store.count.value, 33);
      },
    );

    test('load ignores a corrupt payload', () async {
      final prefs = SharedPreferencesAsync();
      await prefs.setString('tasbih_today', '{"date": ');

      final store = makeStore();
      await store.load();

      expect(store.totalToday.value, 0);
    });

    test(
      'a stale persisted round is credited to lifetime, not today',
      () async {
        final store = makeStore();
        await store.load();
        store
          ..setTarget(100)
          ..tap()
          ..tap();
        await pumpEventQueue();

        final nextDay = makeStore(now: () => DateTime(2026, 6, 13, 10));
        await nextDay.load();
        expect(nextDay.count.value, 0);
        expect(nextDay.target.value, 100);
        expect(nextDay.totalToday.value, 0);
        expect(nextDay.lifetimeTotal.value, 2);
        expect(nextDay.lifetimeSessions.value, 1);
      },
    );

    test(
      'a day change in either direction re-reads that day, never clobbers',
      () async {
        var now = DateTime(2026, 11, 3, 9);
        final store = makeStore(now: () => now);
        await store.load();
        for (var i = 0; i < 300; i++) {
          store.tap();
        }
        await store.reset(saveToHistory: true);
        expect(store.totalToday.value, 300);

        // Manual city switched to a zone still on the 2nd.
        now = DateTime(2026, 11, 2, 18);
        store.rollOverDay();
        await pumpEventQueue();
        expect(store.totalToday.value, 0);
        store
          ..tap()
          ..tap();
        await store.reset(saveToHistory: true);
        expect(store.totalToday.value, 2);

        // Back on the 3rd: the 300 come back and the next save adds to them.
        now = DateTime(2026, 11, 3, 9, 5);
        store.rollOverDay();
        await pumpEventQueue();
        expect(store.totalToday.value, 300);
        for (var i = 0; i < 33; i++) {
          store.tap();
        }
        await store.reset(saveToHistory: true);
        expect(store.totalToday.value, 333);

        final restored = makeStore(now: () => now);
        await restored.load();
        expect(restored.totalToday.value, 333);
      },
    );

    test('countedToday adds the round in progress, not a stale one', () {
      var now = DateTime(2026, 6, 12, 23, 58);
      final store = makeStore(now: () => now)
        ..tap()
        ..tap();
      expect(store.countedToday, 2);
      // Past midnight the open round belongs to yesterday.
      now = DateTime(2026, 6, 13, 0, 1);
      expect(store.countedToday, 0);
    });

    test('auto-next saves a full round on the next bead (persisted)', () async {
      final store = makeStore();
      await store.load();
      await store.setAutoNextRound(value: true);
      store
        ..setTarget(2)
        ..tap()
        ..tap();
      expect(store.count.value, 2); // the target is still shown

      store.tap();
      await pumpEventQueue();
      expect(store.count.value, 1);
      expect(store.totalToday.value, 2);
      expect(store.lifetimeSessions.value, 1);

      final restored = makeStore();
      await restored.load();
      expect(restored.autoNextRound.value, isTrue);
    });

    test('without auto-next the count runs past the target', () {
      final store = makeStore()
        ..setTarget(1)
        ..tap()
        ..tap();
      expect(store.count.value, 2);
    });

    test('a stale round is cleared before it is credited', () async {
      final prefs = _RecordingPrefs();
      SharedPreferencesAsyncPlatform.instance = prefs;
      final store = makeStore();
      await store.load();
      store
        ..tap()
        ..tap();
      await pumpEventQueue();

      prefs.writes.clear();
      final nextDay = makeStore(now: () => DateTime(2026, 6, 13, 10));
      await nextDay.load();
      // Killed between the writes, the round must not be credited twice.
      expect(prefs.writes, ['tasbih_round', 'tasbih_lifetime']);
      expect(nextDay.lifetimeTotal.value, 2);
    });

    test(
      'a failed day-total write is reported and still credits lifetime',
      () async {
        SharedPreferencesAsyncPlatform.instance = _FailingKeyPrefs(
          'tasbih_today',
        );
        final store = makeStore();
        await store.load();
        await store.setAutoNextRound(value: true);
        store
          ..setTarget(2)
          ..tap()
          ..tap()
          ..tap(); // auto-next saves the full round
        await pumpEventQueue();

        expect(store.saveFailures.value, 1);
        expect(store.count.value, 1);
        expect(store.lifetimeTotal.value, 2);
        expect(store.lifetimeSessions.value, 1);
        final restored = makeStore();
        await restored.load();
        expect(restored.lifetimeTotal.value, 2);
      },
    );

    test('a failed round write is reported, not thrown', () async {
      SharedPreferencesAsyncPlatform.instance = _FailingKeyPrefs(
        'tasbih_round',
      );
      final store = makeStore();
      await store.load();
      store
        ..tap()
        ..setTarget(5);
      await pumpEventQueue();

      expect(store.count.value, 1);
      expect(store.saveFailures.value, 2);
    });
  });
}
