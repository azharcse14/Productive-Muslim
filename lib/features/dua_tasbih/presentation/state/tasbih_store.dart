import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart' show HapticFeedback;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:signals_flutter/signals_flutter.dart';

/// Tasbih counter state: current round, target preset, and today's running
/// total (persisted as one JSON blob, reset on date rollover).
final class TasbihStore {
  TasbihStore(
    this._prefs, {
    void Function()? haptic,
    void Function()? milestoneHaptic,
    DateTime Function()? now,
  })  : _haptic = haptic ?? _defaultTapHaptic,
        _milestoneHaptic = milestoneHaptic ?? _defaultMilestoneHaptic,
        _now = now ?? DateTime.now;

  static const _key = 'tasbih_today';

  final SharedPreferencesAsync _prefs;
  final void Function() _haptic;
  final void Function() _milestoneHaptic;
  final DateTime Function() _now;

  late final count = signal(0);
  late final target = signal(33);

  /// Counts saved to history today (current round not included).
  late final totalToday = signal(0);

  /// Pulses true the moment [count] reaches [target] (screen scale pulse).
  late final milestone = signal(false);

  static void _defaultTapHaptic() => unawaited(HapticFeedback.lightImpact());

  static void _defaultMilestoneHaptic() =>
      unawaited(HapticFeedback.mediumImpact());

  String _todayKey() {
    final n = _now();
    final mm = n.month.toString().padLeft(2, '0');
    final dd = n.day.toString().padLeft(2, '0');
    return '${n.year}$mm$dd';
  }

  /// Restores today's saved total (a stored total from another day is stale
  /// and resets to zero).
  Future<void> load() async {
    final raw = await _prefs.getString(_key);
    if (raw == null) {
      return;
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        return;
      }
      final map = decoded.cast<String, Object?>();
      if (map['date'] == _todayKey() && map['total'] is int) {
        totalToday.value = map['total']! as int;
      }
    } on FormatException {
      // Corrupt payload — start fresh.
    }
  }

  void tap() {
    _haptic();
    count.value = count.value + 1;
    if (count.value == target.value) {
      milestone.value = true;
      _milestoneHaptic();
    }
  }

  void setTarget(int n) {
    if (n < 1) {
      return;
    }
    target.value = n;
    if (count.value < n) {
      milestone.value = false;
    }
  }

  /// Ends the round. With [saveToHistory] the round is added to today's
  /// total and persisted; otherwise the count is simply discarded.
  Future<void> reset({required bool saveToHistory}) async {
    if (saveToHistory && count.value > 0) {
      totalToday.value = totalToday.value + count.value;
      await _prefs.setString(
        _key,
        jsonEncode({'date': _todayKey(), 'total': totalToday.value}),
      );
    }
    count.value = 0;
    milestone.value = false;
  }
}
