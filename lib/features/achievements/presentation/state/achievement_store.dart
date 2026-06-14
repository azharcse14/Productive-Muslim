import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../dua_tasbih/presentation/state/tasbih_store.dart';
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
    DateTime Function()? now,
  })  : _muhasaba = muhasaba,
        _tasbih = tasbih,
        _quran = quran,
        _prefs = prefs,
        _now = now ?? DateTime.now;

  static const _seenKey = 'achievements_seen';

  final MuhasabaRepository _muhasaba;
  final TasbihStore? _tasbih;
  final QuranStore? _quran;
  final SharedPreferencesAsync _prefs;
  final DateTime Function() _now;

  late final stats = signal(const AchievementStats());
  late final loaded = signal(false);

  /// Ids the user has already seen unlocked (persisted).
  late final seen = signal(const <String>{});

  /// Evaluated catalog — recomputes whenever [stats] changes.
  late final progress =
      computed(() => AchievementEvaluator.evaluate(stats.value));

  late final unlockedCount =
      computed(() => progress.value.where((p) => p.unlocked).length);

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
    loaded.value = true;
  }

  Future<void> _loadSeen() async {
    final raw = await _prefs.getString(_seenKey);
    if (raw == null) {
      return;
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        seen.value = {for (final id in decoded) if (id is String) id};
      }
    } on FormatException {
      // Corrupt payload — start fresh.
    }
  }

  /// Re-reads every source and rebuilds [stats]. Call after returning to the
  /// achievements screen so totals reflect the latest activity.
  Future<void> refresh() async {
    final today = _today();
    // Wide window so per-item done-day totals are effectively all-time.
    final start = DateTime(today.year - 10, today.month, today.day);
    final result = await _muhasaba.periodStats(
      start: start,
      end: today,
      today: today,
    );
    final ps = result.valueOrNull;

    var salahDays = 0;
    var quranDays = 0;
    var fastingDays = 0;
    var tahajjudDays = 0;
    var sadaqahDays = 0;
    if (ps != null) {
      for (final it in ps.items) {
        if (DefaultTrackers.salahIds.contains(it.itemId)) {
          salahDays += it.daysDone;
        } else if (it.itemId == 'quran') {
          quranDays = it.daysDone;
        } else if (it.itemId == 'roza') {
          fastingDays = it.daysDone;
        } else if (it.itemId == 'tahajjud') {
          tahajjudDays = it.daysDone;
        } else if (it.itemId == 'sadaqah') {
          sadaqahDays = it.daysDone;
        }
      }
    }

    stats.value = AchievementStats(
      currentStreak: ps?.currentStreak ?? 0,
      bestStreak: ps?.bestStreak ?? 0,
      salahDaysDone: salahDays,
      quranDaysDone: quranDays,
      fastingDaysDone: fastingDays,
      tahajjudDaysDone: tahajjudDays,
      sadaqahDaysDone: sadaqahDays,
      totalDhikr: _tasbih?.lifetimeTotal.value ?? 0,
      tasbihSessions: _tasbih?.lifetimeSessions.value ?? 0,
      quranBookmarks: _quran?.bookmarks.value.length ?? 0,
      hasStartedReading: _quran?.lastRead.value != null,
    );
  }

  /// Marks every currently-unlocked badge as seen and persists the set.
  Future<void> markAllSeen() async {
    final ids = {
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
