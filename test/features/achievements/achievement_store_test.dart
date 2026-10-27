import 'package:flutter_test/flutter_test.dart';
import 'package:productive_muslim/features/achievements/presentation/state/achievement_store.dart';
import 'package:productive_muslim/features/fasting/presentation/state/fasting_store.dart';
import 'package:productive_muslim/features/muhasaba/domain/entities/daily_entry.dart';
import 'package:productive_muslim/features/quran/presentation/state/quran_store.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import '../../helpers/content_fakes.dart';
import '../../helpers/muhasaba_fakes.dart';

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  test('badge totals count distinct days from every source', () async {
    final repo = InMemoryMuhasabaRepository();
    await repo.seedDefaultsIfEmpty();
    Future<void> log(String id, int day) => repo.setEntry(
          DailyEntry(itemId: id, date: DateTime(2026, 6, day), value: 1),
        );
    // Two prayers on Jun 1 + one on Jun 2 = 2 salah days, not 3 prayers.
    await log('salah_fajr', 1);
    await log('salah_dhuhr', 1);
    await log('salah_fajr', 2);
    // roza on Jun 3, then archived: its history still counts.
    await log('roza', 3);
    await repo.setArchived('roza', archived: true);
    // Fasting tracker: Jun 3 (same day as roza) + Jun 4.
    final fasting = FastingStore(SharedPreferencesAsync());
    await fasting.toggle(DateTime(2026, 6, 3));
    await fasting.toggle(DateTime(2026, 6, 4));
    // Quran store never opened by its screen — the store loads it.
    final quranRepo = FakeQuranRepository();
    await quranRepo.toggleBookmark(7);
    final quran = QuranStore(quranRepo, SharedPreferencesAsync());

    final store = AchievementStore(
      muhasaba: repo,
      prefs: SharedPreferencesAsync(),
      fasting: fasting,
      quran: quran,
      now: () => DateTime(2026, 6, 10),
    );
    await store.load();

    expect(store.stats.value.salahDaysDone, 2);
    expect(store.stats.value.fastingDaysDone, 2);
    expect(store.stats.value.quranBookmarks, 1);
  });

  test('refresh is single-flight: a burst collapses into one trailing run',
      () async {
    final repo = InMemoryMuhasabaRepository();
    await repo.seedDefaultsIfEmpty();
    final store = AchievementStore(
      muhasaba: repo,
      prefs: SharedPreferencesAsync(),
      now: () => DateTime(2026, 6, 10),
    );
    await Future.wait([for (var i = 0; i < 10; i++) store.refresh()]);
    expect(repo.allItemsCalls, 2, reason: 'first run + one trailing run');
  });

  test('streaksOf: runs, gaps, and a current run ending yesterday', () {
    DateTime d(int day) => DateTime(2026, 6, day);
    final s = AchievementStore.streaksOf(
      {d(1), d(2), d(3), d(4), d(7), d(8), d(9)},
      d(10),
    );
    expect(s.best, 4);
    expect(s.current, 3, reason: 'today (10th) empty: run ends on the 9th');
    expect(AchievementStore.streaksOf({d(1)}, d(10)).current, 0);
  });
}
