import 'package:shared_preferences/shared_preferences.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../../core/utils/hijri_date.dart';
import '../../domain/entities/fasting_stats.dart';
import '../../domain/entities/recommended_fast.dart';
import '../../domain/usecases/recommended_fasts.dart';

/// Personal nafl-fast log + the recommended-fast calendar.
///
/// Logged days are stored as a set of `yyyymmdd` ints (mirrors
/// [DuaFavoritesStore]'s string-list persistence). All recommended-fast
/// queries delegate to the pure [RecommendedFasts] domain.
final class FastingStore {
  FastingStore(
    this._prefs, {
    DateTime Function()? now,
    int Function()? hijriOffset,
  }) : _now = now ?? DateTime.now,
       _hijriOffset = hijriOffset ?? _noOffset;

  static int _noOffset() => 0;

  static const _key = 'fasting_log_v1';

  final SharedPreferencesAsync _prefs;
  final DateTime Function() _now;

  /// User's moon-sighting adjustment (AppSettings.hijriOffsetDays).
  final int Function() _hijriOffset;

  /// Logged fast days, each encoded as `year * 10000 + month * 100 + day`.
  late final logged = signal(const <int>{});
  late final loaded = signal(false);

  static int _stamp(DateTime d) => d.year * 10000 + d.month * 100 + d.day;

  /// Midnight-normalised "today" per the injected clock.
  DateTime get today {
    final n = _now();
    return DateTime(n.year, n.month, n.day);
  }

  Future<void>? _loading;

  /// Restores the persisted log, once per store; [toggle] awaits it first,
  /// so a write never replaces the stored history with an empty log. A
  /// failed load is forgotten, so the next call (or toggle) retries it
  /// (mirrors ExpenseStore).
  Future<void> load() => _loading ??= () async {
    try {
      final stored = await _prefs.getStringList(_key);
      if (stored != null) {
        logged.value = {
          for (final s in stored)
            if (int.tryParse(s) case final v?) v,
        };
      }
      loaded.value = true;
    } on Object {
      _loading = null;
      rethrow;
    }
  }();

  /// Whether [date] is logged as fasted.
  bool isLogged(DateTime date) =>
      logged.value.contains(_stamp(DateTime(date.year, date.month, date.day)));

  /// Whether fasting is forbidden on [date] (the Eids and Tashreeq).
  bool isForbidden(DateTime date) => RecommendedFasts.isForbidden(
    HijriDate.fromGregorian(date, offsetDays: _hijriOffset()),
  );

  /// Whether [date] may be newly logged: not in the future, not forbidden.
  /// Ramadan day — the fast is obligatory, never offered as voluntary.
  bool isRamadan(DateTime date) =>
      HijriDate.fromGregorian(date, offsetDays: _hijriOffset()).month ==
      HijriDate.ramadanMonth;

  bool canLog(DateTime date) =>
      !DateTime(date.year, date.month, date.day).isAfter(today) &&
      !isForbidden(date);

  /// Adds or removes [date] from the log, updating the signal immediately
  /// then persisting. Adding is a no-op unless [canLog]; removing is always
  /// allowed.
  Future<void> toggle(DateTime date) async {
    await load();
    final stamp = _stamp(DateTime(date.year, date.month, date.day));
    final next = Set<int>.from(logged.value);
    if (!next.remove(stamp)) {
      if (!canLog(date)) {
        return;
      }
      next.add(stamp);
    }
    final previous = logged.value;
    logged.value = next;
    try {
      await _prefs.setStringList(_key, [for (final v in next) v.toString()]);
    } on Object {
      // Not saved: don't show a tick the log doesn't have — unless another
      // toggle has already moved the log on.
      if (identical(logged.value, next)) {
        logged.value = previous;
      }
      rethrow;
    }
  }

  /// The recommended fasts (if any) for [date].
  List<RecommendedFast> recommendedOn(DateTime date) =>
      RecommendedFasts.on(date, offsetDays: _hijriOffset());

  /// The next [count] recommended fasting days from today onward.
  List<UpcomingFast> upcoming({int count = 7}) => RecommendedFasts.upcoming(
    today,
    count: count,
    offsetDays: _hijriOffset(),
  );

  /// Simple, no-shame stats over the log.
  FastingStats stats() {
    final t = today;
    final offset = _hijriOffset();
    final h = HijriDate.fromGregorian(t, offsetDays: offset);
    var thisMonth = 0;
    var thisHijri = 0;
    for (final stamp in logged.value) {
      final year = stamp ~/ 10000;
      final month = (stamp ~/ 100) % 100;
      final day = stamp % 100;
      if (year == t.year && month == t.month) {
        thisMonth++;
      }
      final hijri = HijriDate.fromGregorian(
        DateTime(year, month, day),
        offsetDays: offset,
      );
      if (hijri.year == h.year && hijri.month == h.month) {
        thisHijri++;
      }
    }
    return FastingStats(
      total: logged.value.length,
      thisMonth: thisMonth,
      thisHijriMonth: thisHijri,
    );
  }

  /// Heatmap columns (week-per-column, 7 rows) for the current Gregorian
  /// month: level 4 = fasted, level 0 = not yet, -1 = padding/out-of-range.
  /// Mirrors the muhasaba heatmap layout (Sunday-first padding).
  List<List<int>> monthHeatmap() {
    final t = today;
    final daysInMonth = DateTime(t.year, t.month + 1, 0).day;
    final first = DateTime(t.year, t.month);
    final levels = <int>[
      for (var i = 0; i < first.weekday % 7; i++) -1,
      for (var d = 1; d <= daysInMonth; d++)
        isLogged(DateTime(t.year, t.month, d)) ? 4 : 0,
    ];
    while (levels.length % 7 != 0) {
      levels.add(-1);
    }
    return [
      for (var w = 0; w < levels.length ~/ 7; w++)
        levels.sublist(w * 7, w * 7 + 7),
    ];
  }
}
