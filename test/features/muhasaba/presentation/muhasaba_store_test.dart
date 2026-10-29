import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:productive_muslim/features/muhasaba/domain/entities/tracker_item.dart';
import 'package:productive_muslim/features/muhasaba/presentation/state/muhasaba_store.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import '../../../helpers/muhasaba_fakes.dart';

DateTime _fixedNow() => DateTime(2026, 6, 12, 21, 30);

void main() {
  // load() attaches an AppLifecycleListener (midnight roll-over on resume).
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MuhasabaStore', () {
    test('load seeds defaults once and splits archived', () async {
      final (store, repo) = await makeMuhasabaStore(now: _fixedNow);
      expect(repo.seeds, 1);
      expect(store.items.value.length, DefaultTrackers.items().length);
      expect(store.archivedItems.value, isEmpty);
      await store.load();
      expect(repo.seeds, 1, reason: 'seed is idempotent');
    });

    test('setValue persists, updates the map, deletes on zero', () async {
      final (store, repo) = await makeMuhasabaStore(now: _fixedNow);
      await store.setValue('quran', 15);
      expect(store.valueOf('quran'), 15);
      expect(repo.entries_[('quran', 20260612)], 15);
      await store.setValue('quran', 0);
      expect(store.valueOf('quran'), 0);
      expect(repo.entries_.containsKey(('quran', 20260612)), isFalse);
    });

    test('back-fill: selecting yesterday edits that day only', () async {
      final (store, repo) = await makeMuhasabaStore(now: _fixedNow);
      await store.selectDate(DateTime(2026, 6, 11));
      expect(store.selectedIsToday, isFalse);
      expect(store.canGoForward, isTrue);
      await store.setValue('sadaqah', 1);
      expect(repo.entries_[('sadaqah', 20260611)], 1);
      expect(repo.entries_.containsKey(('sadaqah', 20260612)), isFalse);
    });

    test('future dates are rejected', () async {
      final (store, _) = await makeMuhasabaStore(now: _fixedNow);
      await store.selectDate(DateTime(2026, 6, 13));
      expect(store.selectedDate.value, DateTime(2026, 6, 12));
      expect(store.canGoForward, isFalse);
    });

    test(
      'togglePrayerOn flips today without moving a back-fill selection',
      () async {
        final (store, repo) = await makeMuhasabaStore(now: _fixedNow);
        final today = DateTime(2026, 6, 12);
        await store.togglePrayerOn('salah_fajr', today);
        await store.selectDate(DateTime(2026, 6, 10));
        // Home still sees today's real tick while the tab shows another day…
        expect(store.entriesOn(today)['salah_fajr'], 1);
        expect(store.valueOf('salah_fajr'), 0);
        // …so a tap un-ticks it (what the user saw), not a blind flip.
        await store.togglePrayerOn('salah_fajr', today);
        expect(repo.entries_.containsKey(('salah_fajr', 20260612)), isFalse);
        expect(store.selectedDate.value, DateTime(2026, 6, 10));
      },
    );

    test('togglePrayerOn files overnight isha on yesterday', () async {
      final (store, repo) = await makeMuhasabaStore(
        now: () => DateTime(2026, 6, 12, 1, 30),
        // Before Fajr every salah is locked for the new day.
        lockedSalahOn: (date) =>
            date == DateTime(2026, 6, 12) ? {'salah_fajr', 'salah_isha'} : {},
      );
      await store.togglePrayerOn('salah_isha', DateTime(2026, 6, 11));
      expect(repo.entries_[('salah_isha', 20260611)], 1);
      expect(store.entriesOn(DateTime(2026, 6, 11))['salah_isha'], 1);
      expect(repo.entries_.containsKey(('salah_isha', 20260612)), isFalse);
    });

    test('a failed save rolls back only its own key', () async {
      final (store, repo) = await makeMuhasabaStore(now: _fixedNow);
      final gate = repo.gate = Completer<bool>();
      final first = store.setValue('quran', 15); // held, then fails
      await store.setValue('sadaqah', 1); // succeeds meanwhile
      gate.complete(false);
      await first;
      expect(store.valueOf('quran'), 0);
      expect(store.valueOf('sadaqah'), 1, reason: 'not reverted');
      expect(repo.entries_[('sadaqah', 20260612)], 1);
    });

    test('locked salah cannot be checked ahead of its waqt', () async {
      // Asr/Maghrib/Isha haven't started today; Fajr/Dhuhr have.
      final (store, repo) = await makeMuhasabaStore(
        now: _fixedNow,
        lockedSalahOn: (date) =>
            date == DateTime(2026, 6, 12) ? {'salah_asr', 'salah_isha'} : {},
      );
      expect(store.lockedSalah, {'salah_asr', 'salah_isha'});
      // A locked salah is silently refused.
      await store.setValue('salah_asr', 1);
      expect(store.valueOf('salah_asr'), 0);
      expect(repo.entries_.containsKey(('salah_asr', 20260612)), isFalse);
      // togglePrayerOn respects the lock too.
      await store.togglePrayerOn('salah_isha', DateTime(2026, 6, 12));
      expect(repo.entries_.containsKey(('salah_isha', 20260612)), isFalse);
      // An unlocked salah works normally.
      await store.setValue('salah_fajr', 1);
      expect(repo.entries_[('salah_fajr', 20260612)], 1);
    });

    test('back-filling a past date unlocks every salah', () async {
      final (store, repo) = await makeMuhasabaStore(
        now: _fixedNow,
        lockedSalahOn: (date) =>
            date == DateTime(2026, 6, 12) ? {'salah_asr'} : {},
      );
      await store.selectDate(DateTime(2026, 6, 11));
      expect(store.lockedSalah, isEmpty);
      await store.setValue('salah_asr', 1);
      expect(repo.entries_[('salah_asr', 20260611)], 1);
    });

    test('stats refresh after entries and period changes', () async {
      final (store, _) = await makeMuhasabaStore(now: _fixedNow);
      await store.setValue('salah_fajr', 1);
      final week = store.stats.value!;
      expect(week.days.length, 7);
      expect(week.currentStreak, 1);
      await store.setPeriod(MuhasabaPeriod.today);
      expect(store.stats.value!.days.length, 1);
      expect(store.stats.value!.completion, greaterThan(0));
    });

    test('setValue bursts recompute stats once, after the debounce', () async {
      final (store, repo) = await makeMuhasabaStore(
        now: _fixedNow,
        statsDebounce: const Duration(milliseconds: 40),
      );
      final before = repo.periodStatsCalls;
      for (var v = 1; v <= 3; v++) {
        await store.setValue('azkar', v);
      }
      // The tapped value is instant; stats wait for the burst to end.
      expect(store.valueOf('azkar'), 3);
      expect(repo.periodStatsCalls, before);
      await Future<void>.delayed(const Duration(milliseconds: 80));
      expect(repo.periodStatsCalls, before + 1);
      expect(
        store.stats.value!.items
            .firstWhere((i) => i.itemId == 'azkar')
            .totalValue,
        3,
      );
      store.dispose();
    });

    test('addItem refreshes stats', () async {
      final (store, repo) = await makeMuhasabaStore(now: _fixedNow);
      final before = repo.periodStatsCalls;
      await store.addItem(
        name: 'Walk',
        kind: TrackerKind.yesNo,
        icon: 'walk',
        colorIndex: 0,
      );
      expect(repo.periodStatsCalls, before + 1);
    });

    test('firstDay until the very first entry', () async {
      final (store, _) = await makeMuhasabaStore(now: _fixedNow);
      expect(store.firstDay.value, isTrue);
      await store.setValue('azkar', 100);
      expect(store.firstDay.value, isFalse);
    });

    test('addItem creates a custom tracker; archive hides it', () async {
      final (store, _) = await makeMuhasabaStore(now: _fixedNow);
      await store.addItem(
        name: 'Morning walk',
        kind: TrackerKind.duration,
        dailyTarget: 30,
        icon: 'walk',
        colorIndex: 2,
      );
      final custom = store.items.value.firstWhere(
        (i) => i.name == 'Morning walk',
      );
      expect(custom.isDefault, isFalse);
      await store.setArchived(custom.id, archived: true);
      expect(store.items.value.any((i) => i.id == custom.id), isFalse);
      expect(store.archivedItems.value.any((i) => i.id == custom.id), isTrue);
    });

    test('rolls over to the new day when "today" was selected', () async {
      var clock = DateTime(2026, 6, 12, 23, 50);
      final (store, repo) = await makeMuhasabaStore(now: () => clock);
      await store.setValue('salah_isha', 1);
      clock = DateTime(2026, 6, 13, 0, 10);
      await store.rollOverIfNewDay();
      expect(store.selectedDate.value, DateTime(2026, 6, 13));
      expect(store.stats.value!.days.last.date, DateTime(2026, 6, 13));
      // Check-ins now land on the new day, not yesterday.
      await store.togglePrayerOn('salah_fajr', DateTime(2026, 6, 13));
      expect(repo.entries_[('salah_fajr', 20260613)], 1);
      expect(store.valueOf('salah_fajr'), 1);
    });

    test(
      'markDoneOn files the given day, keeps the selection, never un-marks',
      () async {
        final (store, repo) = await makeMuhasabaStore(now: _fixedNow);
        await store.selectDate(DateTime(2026, 6, 10)); // back-filling
        // Late tap on yesterday's isha azan.
        await store.markDoneOn('salah_isha', DateTime(2026, 6, 11));
        expect(repo.entries_[('salah_isha', 20260611)], 1);
        expect(repo.entries_.containsKey(('salah_isha', 20260612)), isFalse);
        expect(store.selectedDate.value, DateTime(2026, 6, 10));
        await store.markDoneOn('salah_isha', DateTime(2026, 6, 11));
        expect(repo.entries_[('salah_isha', 20260611)], 1);
      },
    );

    test(
      'markDoneOn never lowers an existing value; updates the shown day',
      () async {
        final (store, repo) = await makeMuhasabaStore(now: _fixedNow);
        await store.setValue('quran', 15); // today is selected
        await store.markDoneOn('quran', DateTime(2026, 6, 12));
        expect(repo.entries_[('quran', 20260612)], 15);
        expect(store.valueOf('quran'), 15);
        await store.markDoneOn('salah_maghrib', DateTime(2026, 6, 12));
        expect(store.valueOf('salah_maghrib'), 1, reason: 'cache follows');
      },
    );

    test('markDoneOn ignores a date after today', () async {
      final (store, repo) = await makeMuhasabaStore(now: _fixedNow);
      await store.markDoneOn('salah_fajr', DateTime(2026, 6, 13));
      expect(repo.entries_.containsKey(('salah_fajr', 20260613)), isFalse);
    });

    test('roll-over keeps a back-filled date', () async {
      var clock = DateTime(2026, 6, 12, 23, 50);
      final (store, _) = await makeMuhasabaStore(now: () => clock);
      await store.selectDate(DateTime(2026, 6, 10));
      clock = DateTime(2026, 6, 13, 0, 10);
      await store.rollOverIfNewDay();
      expect(store.selectedDate.value, DateTime(2026, 6, 10));
      expect(store.stats.value!.days.last.date, DateTime(2026, 6, 13));
    });

    test(
      'updateItem refreshes stats (target change flips done-days)',
      () async {
        final (store, _) = await makeMuhasabaStore(now: _fixedNow);
        await store.setValue('azkar', 50); // below the 100 target
        int azkarDone() => store.stats.value!.items
            .firstWhere((i) => i.itemId == 'azkar')
            .daysDone;
        expect(azkarDone(), 0);
        final azkar = store.items.value.firstWhere((i) => i.id == 'azkar');
        await store.updateItem(azkar.copyWith(dailyTarget: () => 33));
        expect(azkarDone(), 1);
      },
    );

    test('a failed save bumps saveFailures (the screen toasts it)', () async {
      final (store, repo) = await makeMuhasabaStore(now: _fixedNow);
      final before = store.saveFailures.value;
      repo.gate = Completer<bool>()..complete(false);
      await store.setValue('quran', 5);
      expect(store.saveFailures.value, before + 1);
      expect(store.valueOf('quran'), 0);
    });

    test('reorder persists the new order, archived trail', () async {
      final (store, repo) = await makeMuhasabaStore(now: _fixedNow);
      await store.setArchived('tahajjud', archived: true);
      final ids = [for (final i in store.items.value) i.id];
      final reordered = [...ids.reversed];
      await store.reorder(reordered);
      expect([for (final i in store.items.value) i.id], reordered);
      expect(repo.items_['tahajjud']!.sortOrder, reordered.length);
    });

    test('welcome dismissal is persisted across loads', () async {
      SharedPreferencesAsyncPlatform.instance =
          InMemorySharedPreferencesAsync.empty();
      final repo = InMemoryMuhasabaRepository();
      final prefs = SharedPreferencesAsync();
      final first = MuhasabaStore(repo, now: _fixedNow, prefs: prefs);
      await first.load();
      expect(first.welcomeDismissed.value, isFalse);
      await first.dismissWelcome();
      final second = MuhasabaStore(repo, now: _fixedNow, prefs: prefs);
      await second.load();
      expect(second.welcomeDismissed.value, isTrue);
      first.dispose();
      second.dispose();
    });
  });
}
