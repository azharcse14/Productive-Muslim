import 'package:flutter_test/flutter_test.dart';
import 'package:qalbee/features/muhasaba/domain/entities/tracker_item.dart';
import 'package:qalbee/features/muhasaba/presentation/state/muhasaba_store.dart';

import '../../../helpers/muhasaba_fakes.dart';

DateTime _fixedNow() => DateTime(2026, 6, 12, 21, 30);

void main() {
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

    test('togglePrayerToday flips today even while back-filling', () async {
      final (store, repo) = await makeMuhasabaStore(now: _fixedNow);
      await store.selectDate(DateTime(2026, 6, 10));
      await store.togglePrayerToday('salah_fajr');
      expect(repo.entries_[('salah_fajr', 20260612)], 1);
      expect(store.selectedIsToday, isTrue);
      await store.togglePrayerToday('salah_fajr');
      expect(repo.entries_.containsKey(('salah_fajr', 20260612)), isFalse);
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
      final custom =
          store.items.value.firstWhere((i) => i.name == 'Morning walk');
      expect(custom.isDefault, isFalse);
      await store.setArchived(custom.id, archived: true);
      expect(store.items.value.any((i) => i.id == custom.id), isFalse);
      expect(
        store.archivedItems.value.any((i) => i.id == custom.id),
        isTrue,
      );
    });
  });
}
