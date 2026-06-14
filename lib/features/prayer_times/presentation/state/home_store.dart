import 'dart:async';

import 'package:signals_flutter/signals_flutter.dart';

import '../../../../core/utils/bangla_date.dart';
import '../../../../core/utils/hijri_date.dart';
import '../../../my_mosque/presentation/state/mosque_store.dart';
import '../../../settings/domain/entities/prayer_params.dart';
import '../../../settings/domain/repositories/zoned_clock.dart';
import '../../../settings/presentation/state/settings_store.dart';
import '../../domain/entities/countdown_target.dart';
import '../../domain/entities/prayer_day.dart';
import '../../domain/entities/special_time.dart';
import '../../domain/usecases/get_prayer_day.dart';
import '../../domain/usecases/resolve_countdown.dart';
import '../../domain/usecases/resolve_special_times.dart';

/// Coarse time-of-day buckets for the header greeting. Memoized so the home
/// only rebuilds at a boundary, not every second.
enum DayPart { morning, afternoon, evening, night }

/// Home-screen state. ONE 1-second timer drives ONE `now` signal;
/// everything else is `computed` (guide §4: derive, don't duplicate).
/// Computed values memoize by ==, so only the countdown subtree sees
/// per-second changes — the table/header rebuild only when their derived
/// values actually flip.
final class HomeStore {
  HomeStore({
    required GetPrayerDay getPrayerDay,
    required ZonedClock clock,
    required SettingsStore settings,
    required MosqueStore mosque,
  })  : _getPrayerDay = getPrayerDay,
        _clock = clock,
        _settings = settings,
        _mosque = mosque {
    now = signal(_wallNow());
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      now.value = _wallNow();
    });
  }

  final GetPrayerDay _getPrayerDay;
  final ZonedClock _clock;
  final SettingsStore _settings;
  final MosqueStore _mosque;

  /// Wall clock at the configured location, ticked every second.
  late final Signal<DateTime> now;
  late Timer _ticker;

  DateTime _wallNow() {
    final location = _settings.location.value;
    return location == null ? DateTime.now() : _clock.nowAt(location);
  }

  /// The configured location (null until setup).
  late final location = computed(() => _settings.location.value);

  /// y/m/d only — flips at midnight and triggers a recompute.
  late final dateKey = computed(() {
    final n = now.value;
    return DateTime(n.year, n.month, n.day);
  });

  late final prayerDay = computed<PrayerDay?>(() {
    final location = _settings.location.value;
    if (location == null) {
      return null;
    }
    return _getPrayerDay(
      location: location,
      params: _settings.prayerParams.value,
      date: dateKey.value,
    ).valueOrNull;
  });

  /// Time-of-day bucket for the greeting; flips only at a boundary, so reading
  /// it at the top of the home tree doesn't force a per-second rebuild.
  late final daypart = computed<DayPart>(() {
    final h = now.value.hour;
    if (h >= 4 && h < 12) {
      return DayPart.morning;
    }
    if (h >= 12 && h < 16) {
      return DayPart.afternoon;
    }
    if (h >= 16 && h < 20) {
      return DayPart.evening;
    }
    return DayPart.night;
  });

  late final hijriDate = computed(() => HijriDate.fromGregorian(dateKey.value));
  late final banglaDate =
      computed(() => BanglaDate.fromGregorian(dateKey.value));

  /// Tabular hijri can be ±1 day off actual sighting; treated as Ramadan
  /// when the tabular month is Ramadan (refined in Phase 10 with a user
  /// offset setting).
  late final ramadanMode =
      computed(() => hijriDate.value.month == HijriDate.ramadanMonth);

  /// The active mosque profile's jamaat times.
  late final jamaatConfig = computed(() => _mosque.activeConfig.value);

  late final countdownTarget = computed<CountdownTarget?>(() {
    final day = prayerDay.value;
    if (day == null) {
      return null;
    }
    return resolveCountdownTarget(
      now: now.value,
      day: day,
      jamaat: jamaatConfig.value,
      ramadanMode: ramadanMode.value,
    );
  });

  late final urgency = computed<CountdownUrgency>(() {
    final target = countdownTarget.value;
    if (target == null) {
      return CountdownUrgency.calm;
    }
    return countdownUrgencyFor(now: now.value, target: target);
  });

  /// Changes once per waqt — the table's highlight dependency.
  late final activeWaqt =
      computed(() => prayerDay.value?.activeWaqtAt(now.value));

  /// Bitmask of prayers whose waqt has started today. Reads `now` every
  /// second but its value only flips at a waqt boundary, so downstream
  /// (the table) doesn't rebuild per second.
  late final _startedMask = computed<int>(() {
    final day = prayerDay.value;
    if (day == null) {
      return 0;
    }
    final n = now.value;
    var mask = 0;
    for (final (i, prayer) in Prayer.values.indexed) {
      if (!n.isBefore(day.startOf(prayer))) {
        mask |= 1 << i;
      }
    }
    return mask;
  });

  /// Prayers whose waqt hasn't begun yet — not checkable on the table.
  late final lockedPrayers = computed<Set<Prayer>>(() {
    final mask = _startedMask.value;
    return {
      for (final (i, prayer) in Prayer.values.indexed)
        if (mask & (1 << i) == 0) prayer,
    };
  });

  /// Today's forbidden (makruh) and nafl windows — flips only when the
  /// day changes, so the special-times card doesn't rebuild per second.
  late final specialWindows = computed<List<SpecialWindow>>(() {
    final day = prayerDay.value;
    if (day == null) {
      return const [];
    }
    return resolveSpecialWindows(day);
  });

  /// The special window the clock is currently inside, or null. A value
  /// type, so it only flips at a window boundary (no per-second rebuild).
  late final activeSpecial = computed<SpecialTime?>(() {
    final n = now.value;
    for (final w in specialWindows.value) {
      if (w.containsAt(n)) {
        return w.time;
      }
    }
    return null;
  });

  /// Per-second values, isolated so only the hero numeral subtree ticks.
  late final remaining = computed(() {
    final target = countdownTarget.value;
    if (target == null) {
      return Duration.zero;
    }
    final r = target.remainingAt(now.value);
    return r.isNegative ? Duration.zero : r;
  });

  late final progress = computed(
    () => countdownTarget.value?.progressAt(now.value) ?? 0.0,
  );

  void dispose() {
    _ticker.cancel();
  }
}
