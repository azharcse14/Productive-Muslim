import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../../core/utils/haptics.dart';

/// Tasbih counter state: current round, target preset, and today's running
/// total (persisted as one JSON blob, reset on date rollover).
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

  /// The in-progress round ({count, target}), so an OS kill mid-round
  /// doesn't lose it.
  static const _roundKey = 'tasbih_round';
  static const _lifetimeKey = 'tasbih_lifetime';

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

  /// Lifetime dhikr saved across all rounds (drives achievement badges).
  late final lifetimeTotal = signal(0);

  /// Lifetime number of saved tasbih rounds.
  late final lifetimeSessions = signal(0);

  /// Pulses true the moment [count] reaches [target] (screen scale pulse).
  late final milestone = signal(false);

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
      return;
    }
    final today = _todayKey();
    totalToday.value = await _readTotal(today);
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
        if (m['count'] case final int c when c >= 0) {
          count.value = c;
        }
        if (m['target'] case final int t when t >= 1) {
          target.value = t;
        }
      }
    } on FormatException {
      // Corrupt payload — start fresh.
    }
  }

  // ponytail: one prefs write per bead; debounce if taps ever get heavy.
  void _saveRound() => unawaited(
    _prefs.setString(
      _roundKey,
      jsonEncode({'count': count.value, 'target': target.value}),
    ),
  );

  Future<int> _readTotal(String today) async {
    final raw = await _prefs.getString(_key);
    if (raw == null) {
      return 0;
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        final map = decoded.cast<String, Object?>();
        if (map['date'] == today && map['total'] is int) {
          return map['total']! as int;
        }
      }
    } on FormatException {
      // Corrupt payload — start fresh.
    }
    return 0;
  }

  /// Zeroes [totalToday] once the day it was counted on has passed (the
  /// store is app-scoped, so it can outlive midnight).
  void rollOverDay() {
    final today = _todayKey();
    if (_totalDay != today) {
      _totalDay = today;
      totalToday.value = 0;
    }
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

  void tap() {
    rollOverDay();
    _haptic();
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
    if (saveToHistory && count.value > 0) {
      rollOverDay();
      totalToday.value = totalToday.value + count.value;
      await _prefs.setString(
        _key,
        jsonEncode({'date': _todayKey(), 'total': totalToday.value}),
      );
      lifetimeTotal.value = lifetimeTotal.value + count.value;
      lifetimeSessions.value = lifetimeSessions.value + 1;
      await _prefs.setString(
        _lifetimeKey,
        jsonEncode({
          'total': lifetimeTotal.value,
          'sessions': lifetimeSessions.value,
        }),
      );
    }
    count.value = 0;
    milestone.value = false;
    _saveRound();
  }
}
