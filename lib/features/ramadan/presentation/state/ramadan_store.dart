import 'dart:async';

import 'package:signals_flutter/signals_flutter.dart';

import '../../../../core/utils/hijri_date.dart';
import '../../../prayer_times/domain/usecases/get_prayer_day.dart';
import '../../../settings/presentation/state/settings_store.dart';
import '../../domain/usecases/ramadan_utils.dart';

/// One row of the Ramadan month table: the Gregorian civil day plus its
/// sahri-end and iftar wall-clock times at the configured location.
/// [roza] is the Ramadan day number (1-based), kept per row because a day
/// whose prayer times fail to compute is left out of the table.
typedef RamadanRow = (DateTime day, DateTime sahri, DateTime iftar, int roza);

/// Ramadan-screen state over the pure [RamadanUtils] date math. Everything
/// date-derived is `computed` (guide §4: derive, don't duplicate),
/// including the ~30-day month table (memoised until its inputs change).
final class RamadanStore {
  RamadanStore(
    GetPrayerDay getPrayerDay,
    SettingsStore settings, {
    DateTime Function()? now,
  }) : _getPrayerDay = getPrayerDay,
       _settings = settings,
       _now = now ?? DateTime.now {
    // The screen can stay open past midnight: re-read the day each minute.
    // [today] memoizes by ==, so dependants recompute only when it flips.
    _ticker = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _minute.value++,
    );
  }

  final GetPrayerDay _getPrayerDay;
  final SettingsStore _settings;
  final DateTime Function() _now;
  late final Timer _ticker;

  DateTime _day() {
    final n = _now();
    return DateTime(n.year, n.month, n.day);
  }

  late final _minute = signal(0);

  /// Today's civil date (y/m/d only) at the caller-provided clock. Re-read
  /// each minute and on a location change (the clock follows the
  /// location's timezone, which may sit on another date).
  late final today = computed(() {
    _minute.value;
    _settings.location.value;
    return _day();
  });

  /// User's moon-sighting adjustment, applied to every Hijri conversion.
  late final _offset = computed(() => _settings.settings.value.hijriOffsetDays);

  late final hijriToday = computed(
    () => HijriDate.fromGregorian(today.value, offsetDays: _offset.value),
  );

  late final isRamadan = computed(
    () => RamadanUtils.isRamadan(hijriToday.value),
  );

  /// Fasting-day number (1..29/30), or null outside Ramadan.
  late final rozaDay = computed(() => RamadanUtils.rozaDay(hijriToday.value));

  /// Hijri year of the current (or next) Ramadan, and days until its first
  /// day — 0 when today is already inside it.
  late final nextRamadan = computed(
    () => RamadanUtils.nextRamadan(today.value, offsetDays: _offset.value),
  );

  /// Number of days in that Ramadan (29 or 30).
  late final ramadanLength = computed(
    () => RamadanUtils.ramadanLength(nextRamadan.value.$1),
  );

  /// The month table for the current-or-next Ramadan — empty when no
  /// location is configured. A `computed`, so it rebuilds (once, memoised)
  /// whenever location, prayer params / sahri margin or the hijri offset
  /// change, e.g. after setting a location from this screen.
  late final monthRows = computed<List<RamadanRow>>(() {
    final location = _settings.location.value;
    if (location == null) {
      return const [];
    }
    final params = _settings.prayerParams.value;
    final rows = <RamadanRow>[];
    final days = RamadanUtils.gregorianDaysOf(
      nextRamadan.value.$1,
      offsetDays: _offset.value,
    );
    for (final (index, day) in days.indexed) {
      final prayerDay = _getPrayerDay(
        location: location,
        params: params,
        date: day,
      ).valueOrNull;
      if (prayerDay != null) {
        rows.add((day, prayerDay.sahriEnd, prayerDay.iftar, index + 1));
      }
    }
    return rows;
  });

  /// The row for the day after [day], or null past the month's end or
  /// when that day's times failed to compute (the table skips it).
  RamadanRow? rowAfter(DateTime day) {
    final next = DateTime(day.year, day.month, day.day + 1);
    for (final row in monthRows.value) {
      if (row.$1 == next) {
        return row;
      }
    }
    return null;
  }

  void dispose() => _ticker.cancel();
}
