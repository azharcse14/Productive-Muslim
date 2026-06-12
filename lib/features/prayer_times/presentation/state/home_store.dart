import 'dart:async';

import 'package:signals_flutter/signals_flutter.dart';

import '../../../../core/utils/bangla_date.dart';
import '../../../../core/utils/hijri_date.dart';
import '../../../my_mosque/domain/entities/jamaat_config.dart';
import '../../../settings/domain/repositories/zoned_clock.dart';
import '../../../settings/presentation/state/settings_store.dart';
import '../../domain/entities/countdown_target.dart';
import '../../domain/entities/prayer_day.dart';
import '../../domain/usecases/get_prayer_day.dart';
import '../../domain/usecases/resolve_countdown.dart';

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
  })  : _getPrayerDay = getPrayerDay,
        _clock = clock,
        _settings = settings {
    now = signal(_wallNow());
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      now.value = _wallNow();
    });
  }

  final GetPrayerDay _getPrayerDay;
  final ZonedClock _clock;
  final SettingsStore _settings;

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

  late final hijriDate = computed(() => HijriDate.fromGregorian(dateKey.value));
  late final banglaDate =
      computed(() => BanglaDate.fromGregorian(dateKey.value));

  /// Tabular hijri can be ±1 day off actual sighting; treated as Ramadan
  /// when the tabular month is Ramadan (refined in Phase 10 with a user
  /// offset setting).
  late final ramadanMode =
      computed(() => hijriDate.value.month == HijriDate.ramadanMonth);

  /// Jamaat config arrives with My Mosque (Phase 5); none until then.
  late final jamaatConfig = signal(JamaatConfig.none);

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
