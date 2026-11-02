import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../../core/utils/haptics.dart';

/// Tasbih counter state: current round, target preset, and today's running
/// total (persisted as one JSON blob, re-read on a day change).
final class TasbihStore {
  TasbihStore(
    this._prefs, {
    void Function()? haptic,
    void Function()? milestoneHaptic,
    DateTime Function()? now,
  }) : _haptic = haptic ?? _defaultTapHaptic,
       _milestoneHaptic = milestoneHaptic ?? _defaultMilestoneHaptic,
       _now = now ?? DateTime.now;

  static const _key = 'tasbih_today';

  /// The in-progress round ({count, target, day}), so an OS kill mid-round
  /// doesn't lose it. A round belongs to the day its first bead was
  /// tapped: one left over from an earlier day is credited to the lifetime
  /// stats only (that day's total is gone) and never to today's total.
  static const _roundKey = 'tasbih_round';
  static const _lifetimeKey = 'tasbih_lifetime';
  static const _phraseKey = 'tasbih_phrase';

  final SharedPreferencesAsync _prefs;
  final void Function() _haptic;
  final void Function() _milestoneHaptic;
  final DateTime Function() _now;

  late final count = signal(0);
  late final target = signal(33);

  /// Counts saved to history today (current round not included).
  late final totalToday = signal(0);

  /// The day key [totalToday] belongs to; a different day means it is stale.
  String? _totalDay;

  /// The latest re-read of the stored total after a day change; [reset]
  /// waits for it so a save never lands on a total about to be replaced.
  Future<void> _reloading = Future<void>.value();
  int _reloadGen = 0;

  /// Day key of the in-progress round's first bead; null while count is 0.
  String? _roundDay;

  /// Lifetime dhikr saved across all rounds (drives achievement badges).
  late final lifetimeTotal = signal(0);

  /// Lifetime number of saved tasbih rounds.
  late final lifetimeSessions = signal(0);

  /// Pulses true the moment [count] reaches [target] (screen scale pulse).
  late final milestone = signal(false);

  /// The chosen dhikr phrase id (the screen owns the list and validates
  /// it); null until [load] or [setPhrase]. Persisted.
  late final phrase = signal<String?>(null);

  Future<void> setPhrase(String id) {
    phrase.value = id;
    return _prefs.setString(_phraseKey, id);
  }

  static void _defaultTapHaptic() => Haptics.light();

  static void _defaultMilestoneHaptic() => Haptics.medium();

  String _todayKey() {
    final n = _now();
    final mm = n.month.toString().padLeft(2, '0');
    final dd = n.day.toString().padLeft(2, '0');
    return '${n.year}$mm$dd';
  }

  /// Restores today's saved total (a stored total from another day is stale
  /// and resets to zero) and the lifetime stats. Once loaded, later calls
  /// (every screen open) only roll the day over — re-reading prefs would
  /// clobber beads tapped while the read was in flight.
  Future<void> load() async {
    if (_totalDay != null) {
      rollOverDay();
      await _reloading;
      return;
    }
    final today = _todayKey();
    phrase.value ??= await _prefs.getString(_phraseKey);
    totalToday.value = (await _readStored()).totalFor(today);
    _totalDay = today;
    await _loadLifetime();
    await _loadRound();
  }

  Future<void> _loadRound() async {
    final raw = await _prefs.getString(_roundKey);
    if (raw == null) {
      return;
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        final m = decoded.cast<String, Object?>();
        if (m['target'] case final int t when t >= 1) {
          target.value = t;
        }
        if (m['count'] case final int c when c > 0) {
          // Payloads from before the day field count as today's.
          final day = m['day'] is String ? m['day']! as String : _todayKey();
          if (day == _todayKey()) {
            count.value = c;
            _roundDay = day;
          } else {
            // Clear first, as [reset] does: killed between the two writes,
            // the round is lost rather than credited twice on next launch.
            await _writeRound();
            await _creditLifetime(c);
          }
        }
      }
    } on FormatException {
      // Corrupt payload — start fresh.
    }
  }

  // ponytail: one prefs write per bead; debounce if taps ever get heavy.
  void _saveRound() => unawaited(_writeRound());

  Future<void> _writeRound() => _prefs.setString(
    _roundKey,
    jsonEncode({
      'count': count.value,
      'target': target.value,
      'day': _roundDay,
    }),
  );

  /// The persisted total and the day it belongs to (null day: none stored).
  Future<_StoredTotal> _readStored() async {
    final raw = await _prefs.getString(_key);
    if (raw == null) {
      return const _StoredTotal(null, 0);
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        final map = decoded.cast<String, Object?>();
        if (map['date'] case final String day when map['total'] is int) {
          return _StoredTotal(day, map['total']! as int);
        }
      }
    } on FormatException {
      // Corrupt payload — start fresh.
    }
    return const _StoredTotal(null, 0);
  }

  /// Follows the day [totalToday] belongs to (the store is app-scoped, so it
  /// can outlive midnight; a city or time-zone switch can also step the day
  /// back). On any change it re-reads that day's stored total rather than
  /// assuming zero.
  void rollOverDay() {
    final today = _todayKey();
    if (_totalDay == today) {
      return;
    }
    _totalDay = today;
    totalToday.value = 0;
    final gen = ++_reloadGen;
    _reloading = _readStored().then((stored) {
      if (gen == _reloadGen) {
        totalToday.value = stored.totalFor(today);
      }
    });
  }

  Future<void> _loadLifetime() async {
    final raw = await _prefs.getString(_lifetimeKey);
    if (raw == null) {
      return;
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        final m = decoded.cast<String, Object?>();
        if (m['total'] is int) {
          lifetimeTotal.value = m['total']! as int;
        }
        if (m['sessions'] is int) {
          lifetimeSessions.value = m['sessions']! as int;
        }
      }
    } on FormatException {
      // Corrupt payload — start fresh.
    }
  }

  Future<void> _creditLifetime(int beads) async {
    lifetimeTotal.value = lifetimeTotal.value + beads;
    lifetimeSessions.value = lifetimeSessions.value + 1;
    await _prefs.setString(
      _lifetimeKey,
      jsonEncode({
        'total': lifetimeTotal.value,
        'sessions': lifetimeSessions.value,
      }),
    );
  }

  void tap() {
    rollOverDay();
    _haptic();
    if (count.value == 0) {
      _roundDay = _todayKey();
    }
    count.value = count.value + 1;
    if (count.value == target.value) {
      milestone.value = true;
      _milestoneHaptic();
    }
    _saveRound();
  }

  /// Takes back one stray bead.
  void undo() {
    if (count.value == 0) {
      return;
    }
    count.value = count.value - 1;
    if (count.value < target.value) {
      milestone.value = false;
    }
    _saveRound();
  }

  void setTarget(int n) {
    if (n < 1) {
      return;
    }
    target.value = n;
    if (count.value < n) {
      milestone.value = false;
    }
    _saveRound();
  }

  /// Ends the round. With [saveToHistory] the round is added to today's
  /// total and persisted; otherwise the count is simply discarded.
  Future<void> reset({required bool saveToHistory}) async {
    // Snapshot and clear synchronously: taps landing during the awaits
    // below start the next round instead of being lost or miscredited.
    final round = count.value;
    final roundDay = _roundDay;
    _roundDay = null;
    count.value = 0;
    milestone.value = false;
    // First: killed before the total is written, the round is lost — better
    // than restoring it next to a total that already counts it.
    _saveRound();
    if (saveToHistory && round > 0) {
      rollOverDay();
      await _reloading;
      final today = _todayKey();
      // A round started before midnight is not part of today's total.
      if (roundDay == null || roundDay == today) {
        totalToday.value = totalToday.value + round;
        final total = totalToday.value;
        // ponytail: one stored day only — a day behind the stored one (zone
        // switched back) keeps its total in memory rather than clobbering
        // the later day's; store a per-day map if that ever matters.
        final stored = await _readStored();
        if (stored.day == null || stored.day!.compareTo(today) <= 0) {
          await _prefs.setString(
            _key,
            jsonEncode({'date': today, 'total': total}),
          );
        }
      }
      await _creditLifetime(round);
    }
  }
}

/// The persisted today-total payload.
final class _StoredTotal {
  const _StoredTotal(this.day, this.total);

  final String? day;
  final int total;

  int totalFor(String today) => day == today ? total : 0;
}
