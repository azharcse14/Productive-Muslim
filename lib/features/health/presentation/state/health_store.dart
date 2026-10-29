import 'package:shared_preferences/shared_preferences.dart';
import 'package:signals_flutter/signals_flutter.dart';

/// Personal weight log for the Health screen. The daily habits (water,
/// sleep, exercise, miswak) live in Muhasaba; only weight is kept here.
///
/// Stored as `yyyymmdd:kg` strings (mirrors [FastingStore]'s string-list
/// persistence).
final class HealthStore {
  HealthStore(this._prefs, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  static const _key = 'health_weight_v1';

  /// Plausible human range; anything outside is a typo, not a weight.
  static const minKg = 2.0;
  static const maxKg = 400.0;

  final SharedPreferencesAsync _prefs;
  final DateTime Function() _now;

  /// yyyymmdd → kg.
  late final weights = signal(const <int, double>{});
  late final loaded = signal(false);

  static int _stamp(DateTime d) => d.year * 10000 + d.month * 100 + d.day;

  static DateTime _date(int stamp) =>
      DateTime(stamp ~/ 10000, (stamp ~/ 100) % 100, stamp % 100);

  DateTime get today {
    final n = _now();
    return DateTime(n.year, n.month, n.day);
  }

  Future<void>? _loading;

  /// Restores the log once; a failed load is forgotten so the next call
  /// (or write) retries it (mirrors FastingStore).
  Future<void> load() => _loading ??= () async {
    try {
      final stored = await _prefs.getStringList(_key);
      if (stored != null) {
        weights.value = {
          for (final s in stored)
            if (s.split(':') case [final d, final kg])
              if ((int.tryParse(d), double.tryParse(kg)) case (
                final day?,
                final w?,
              ))
                day: w,
        };
      }
      loaded.value = true;
    } on Object {
      _loading = null;
      rethrow;
    }
  }();

  /// Newest first.
  List<(DateTime, double)> get history => [
    for (final e
        in weights.value.entries.toList()
          ..sort((a, b) => b.key.compareTo(a.key)))
      (_date(e.key), e.value),
  ];

  /// Logs [kg] for [date] (null removes it). Out-of-range or future
  /// entries are rejected with false.
  Future<bool> setWeight(DateTime date, double? kg) async {
    final day = DateTime(date.year, date.month, date.day);
    if (day.isAfter(today) || (kg != null && !(kg >= minKg && kg <= maxKg))) {
      return false;
    }
    await load();
    final next = Map<int, double>.from(weights.value);
    if (kg == null) {
      next.remove(_stamp(day));
    } else {
      next[_stamp(day)] = (kg * 10).round() / 10;
    }
    final previous = weights.value;
    weights.value = next;
    try {
      await _prefs.setStringList(_key, [
        for (final e in next.entries) '${e.key}:${e.value}',
      ]);
    } on Object {
      if (identical(weights.value, next)) {
        weights.value = previous;
      }
      rethrow;
    }
    return true;
  }
}
