import 'package:signals_flutter/signals_flutter.dart';

import '../../../../core/utils/hijri_date.dart';
import '../../../prayer_times/domain/usecases/get_prayer_day.dart';
import '../../../settings/presentation/state/settings_store.dart';
import '../../domain/usecases/ramadan_utils.dart';

/// One row of the Ramadan month table: the Gregorian civil day plus its
/// sahri-end and iftar wall-clock times at the configured location.
typedef RamadanRow = (DateTime day, DateTime sahri, DateTime iftar);

/// Ramadan-screen state over the pure [RamadanUtils] date math. Everything
/// date-derived is `computed` (guide §4: derive, don't duplicate); the
/// month table is computed once via [load] because it spans ~30 prayer-day
/// calculations.
final class RamadanStore {
  RamadanStore(
    GetPrayerDay getPrayerDay,
    SettingsStore settings, {
    DateTime Function()? now,
  })  : _getPrayerDay = getPrayerDay,
        _settings = settings,
        _now = now ?? DateTime.now;

  final GetPrayerDay _getPrayerDay;
  final SettingsStore _settings;
  final DateTime Function() _now;

  /// Today's civil date (y/m/d only) at the caller-provided clock.
  late final today = computed(() {
    final n = _now();
    return DateTime(n.year, n.month, n.day);
  });

  late final hijriToday = computed(() => HijriDate.fromGregorian(today.value));

  late final isRamadan =
      computed(() => RamadanUtils.isRamadan(hijriToday.value));

  /// Fasting-day number (1..29/30), or null outside Ramadan.
  late final rozaDay = computed(() => RamadanUtils.rozaDay(hijriToday.value));

  /// Hijri year of the current (or next) Ramadan, and days until its first
  /// day — 0 when today is already inside it.
  late final nextRamadan =
      computed(() => RamadanUtils.nextRamadan(today.value));

  /// Number of days in that Ramadan (29 or 30).
  late final ramadanLength =
      computed(() => RamadanUtils.ramadanLength(nextRamadan.value.$1));

  /// The month table — empty until [load] runs, and empty when no location
  /// is configured.
  late final monthRows = signal(const <RamadanRow>[]);

  /// Builds [monthRows] for the current-or-next Ramadan. Cheap enough to
  /// run synchronously (~30 adhan computations), but done once here rather
  /// than per build.
  void load() {
    final location = _settings.location.value;
    if (location == null) {
      monthRows.value = const [];
      return;
    }
    final params = _settings.prayerParams.value;
    final rows = <RamadanRow>[];
    for (final day in RamadanUtils.gregorianDaysOf(nextRamadan.value.$1)) {
      final prayerDay = _getPrayerDay(
        location: location,
        params: params,
        date: day,
      ).valueOrNull;
      if (prayerDay != null) {
        rows.add((day, prayerDay.sahriEnd, prayerDay.iftar));
      }
    }
    monthRows.value = rows;
  }
}
