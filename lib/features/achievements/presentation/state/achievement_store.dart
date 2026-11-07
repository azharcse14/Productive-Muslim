import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../../core/utils/result.dart';
import '../../../dua_tasbih/presentation/state/tasbih_store.dart';
import '../../../fasting/presentation/state/fasting_store.dart';
import '../../../muhasaba/domain/entities/tracker_item.dart';
import '../../../muhasaba/domain/repositories/muhasaba_repository.dart';
import '../../../quran/presentation/state/quran_store.dart';
import '../../domain/achievements.dart';

/// App-scoped achievements state. Assembles [AchievementStats] from the
/// existing stores/repos, evaluates the pure catalog, and persists the set
/// of badges already seen (so a future "newly unlocked" toast is possible).
/// Persistence mirrors [TasbihStore]: a single JSON blob via
/// [SharedPreferencesAsync].
final class AchievementStore {
  AchievementStore({
    required MuhasabaRepository muhasaba,
    required SharedPreferencesAsync prefs,
    TasbihStore? tasbih,
    QuranStore? quran,
    FastingStore? fasting,
    DateTime Function()? now,
  }) : _muhasaba = muhasaba,
       _tasbih = tasbih,
       _quran = quran,
       _fasting = fasting,
       _prefs = prefs,
       _now = now ?? DateTime.now;

  static const _seenKey = 'achievements_seen';

  final MuhasabaRepository _muhasaba;
  final TasbihStore? _tasbih;
  final QuranStore? _quran;

  /// Nafl-fast tracker log — unioned with muhasaba `roza` days.
  final FastingStore? _fasting;
  final SharedPreferencesAsync _prefs;
  final DateTime Function() _now;

  late final stats = signal(const AchievementStats());

  /// True once badges were evaluated successfully — by [load] or, after a
  /// failed first load, by any later [refresh].
  late final loaded = signal(false);

  /// Ids the user has already seen unlocked (persisted).
  late final seen = signal(const <String>{});

  /// Evaluated catalog — recomputes whenever [stats] changes.
  late final progress = computed(
    () => AchievementEvaluator.evaluate(stats.value),
  );

  late final unlockedCount = computed(
    () => progress.value.where((p) => p.unlocked).length,
  );

  late final totalCount = computed(() => progress.value.length);

  /// Unlocked badges the user has NOT seen yet (for an optional toast).
  late final newlyUnlocked = computed(() {
    final seenIds = seen.value;
    return [
      for (final p in progress.value)
        if (p.unlocked && !seenIds.contains(p.achievement.id)) p.achievement,
    ];
  });

  Future<void> load() async {
    await _loadSeen();
    await refresh();
  }

  Future<void> _loadSeen() async {
    final raw = await _prefs.getString(_seenKey);
    if (raw == null) {
      return;
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        seen.value = {
          for (final id in decoded)
            if (id is String) id,
        };
      }
    } on FormatException {
      // Corrupt payload — start fresh.
    }
  }

  /// Re-reads every source and rebuilds [stats]. Call after returning to the
  /// achievements screen so totals reflect the latest activity.
  Future<void>? _refreshing;
  var _refreshAgain = false;

  /// Re-evaluates badges; completes with the read's [Failure] as error
  /// when a source can't be read. Single-flight: calls during a run
  /// collapse into one trailing run, so rapid check-ins don't stack
  /// 10-year scans.
  Future<void> refresh() {
    if (_refreshing != null) {
      _refreshAgain = true;
      return _refreshing!;
    }
    return _refreshing = () async {
      try {
        do {
          _refreshAgain = false;
          await _evaluate();
        } while (_refreshAgain);
      } finally {
        _refreshing = null;
      }
    }();
  }

  /// Reads the non-muhasaba signals badges depend on, so an effect calling
  /// it re-runs (and can [refresh]) when any of them changes.
  void watchSources() {
    _fasting?.logged.value;
    _fasting?.loaded.value;
    _tasbih?.lifetimeTotal.value;
    _quran?.bookmarks.value;
    _quran?.lastRead.value;
    _quran?.progressLoaded.value;
  }

  Future<void> _evaluate() async {
    // Bookmarks / last-read live in QuranStore, which is otherwise only
    // loaded by the Quran screen.
    final quran = _quran;
    if (quran != null && !quran.progressLoaded.value) {
      await quran.load();
    }
    // A failed read throws (stats untouched) rather than evaluating empty
    // data: badges would read locked, then "newly unlocked" on recovery.
    Future<T> read<T>(Future<Result<T>> result) async =>
        (await result).fold((value) => value, (f) => throw f);
    Future<int> countOf(Set<String> ids) => read(_muhasaba.doneDayCount(ids));
    // Streaks in SQL, archived items included: archiving a tracker must not
    // re-lock streak badges.
    final streaks = await read(_muhasaba.streaks(_today()));
    final salahDays = await countOf(DefaultTrackers.salahIds.toSet());
    final quranDays = await countOf(const {'quran'});
    final rozaDays = await read(_muhasaba.doneDates(const {'roza'}));
    final tahajjudDays = await countOf(const {'tahajjud'});
    final sadaqahDays = await countOf(const {'sadaqah'});

    // A store whose read failed holds empty data, not the user's: keep
    // the totals it feeds as they were until it really loads.
    final prior = stats.value;
    final fasting = _fasting;
    final fastingDays = fasting == null || fasting.loaded.value
        ? {
            ...rozaDays,
            for (final s in fasting?.logged.value ?? const <int>{})
              DateTime(s ~/ 10000, (s ~/ 100) % 100, s % 100),
          }.length
        : prior.fastingDaysDone;
    final quranRead = quran == null || quran.progressLoaded.value;

    stats.value = AchievementStats(
      currentStreak: streaks.current,
      bestStreak: streaks.best,
      salahDaysDone: salahDays,
      quranDaysDone: quranDays,
      fastingDaysDone: fastingDays,
      tahajjudDaysDone: tahajjudDays,
      sadaqahDaysDone: sadaqahDays,
      totalDhikr: _tasbih?.lifetimeTotal.value ?? 0,
      tasbihSessions: _tasbih?.lifetimeSessions.value ?? 0,
      quranBookmarks: quranRead
          ? quran?.bookmarks.value.length ?? 0
          : prior.quranBookmarks,
      hasStartedReading: quranRead
          ? quran?.lastRead.value != null
          : prior.hasStartedReading,
    );
    loaded.value = true;
  }

  /// Marks every currently-unlocked badge as seen and persists the set.
  /// Never forgets: a badge that re-locks and unlocks again isn't "new".
  Future<void> markAllSeen() async {
    final ids = {
      ...seen.value,
      for (final p in progress.value)
        if (p.unlocked) p.achievement.id,
    };
    if (ids.length == seen.value.length && ids.containsAll(seen.value)) {
      return;
    }
    seen.value = ids;
    await _prefs.setString(_seenKey, jsonEncode(ids.toList()));
  }

  /// Test seam — set [stats] directly, bypassing the real sources.
  @visibleForTesting
  void debugSetStats(AchievementStats s) => stats.value = s;

  DateTime _today() {
    final n = _now();
    return DateTime(n.year, n.month, n.day);
  }
}
