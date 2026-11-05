import 'dart:async';

import 'package:signals_flutter/signals_flutter.dart';

import '../../../../core/settings/settings_store.dart';
import '../../../../core/utils/bangla_date.dart';
import '../../../../core/utils/hijri_date.dart';
import '../../../../core/utils/wall_time.dart';
import '../../../my_mosque/domain/entities/jamaat_config.dart';
import '../../../my_mosque/domain/entities/mosque_profile.dart';
import '../../../my_mosque/domain/entities/mosque_schedule.dart';
import '../../../my_mosque/domain/usecases/resolve_active_mosque.dart';
import '../../../my_mosque/presentation/state/mosque_store.dart';
import '../../../settings/domain/entities/prayer_params.dart';
import '../../../settings/domain/repositories/zoned_clock.dart';
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
    DateTime Function()? utcNow,
  }) : _getPrayerDay = getPrayerDay,
       _clock = clock,
       _settings = settings,
       _mosque = mosque,
       _utcNow = utcNow ?? _deviceUtcNow {
    now = signal(_wallNow());
    // Slow until Home shows and resumes it: other screens (e.g. a cold
    // start into Muhasaba) create the store but need only the day flip.
    pause();
    // Expire a temporary mosque override once the schedule crosses into a
    // different window (the auto target no longer matches its baseline) or
    // its day ends. Resolution ignores it either way; this just tidies up.
    _overrideWatcher = effect(() {
      final auto = _autoMosqueId.value; // memoized — fires only on a boundary
      final day = dateKey.value;
      final state = _mosque.state.value;
      final override = state.activeOverride;
      if (override != null &&
          (override.baselineAutoId != auto ||
              !override.liveAt(day, state.rules))) {
        unawaited(_mosque.clearOverride());
      }
    });
  }

  late final void Function() _overrideWatcher;

  final GetPrayerDay _getPrayerDay;
  final ZonedClock _clock;
  final SettingsStore _settings;
  final MosqueStore _mosque;
  final DateTime Function() _utcNow;

  static DateTime _deviceUtcNow() => DateTime.now().toUtc();

  /// The device's real instant read with the last [now] tick.
  late DateTime _nowUtc;

  /// Wall clock at the configured location, ticked every second.
  late final Signal<DateTime> now;
  Timer? _ticker;

  Duration? _period;

  /// Slows the tick to once a minute while Home is hidden (saves battery).
  /// Not stopped: the store is app-wide, and Fasting / My Mosque / Muhasaba
  /// read [dateKey] and [prayerDay], which must still flip at midnight.
  void pause() => _tick(const Duration(minutes: 1));

  /// Re-syncs [now] immediately and restarts the per-second tick.
  void resume() => _tick(const Duration(seconds: 1));

  void _tick(Duration period) {
    // Always re-read: a show/resume on the slow tick may come up to a
    // minute (or a day flip) after the last one.
    now.value = _wallNow();
    if (_period == period) {
      return;
    }
    _ticker?.cancel();
    _period = period;
    _ticker = Timer.periodic(period, (_) {
      now.value = _wallNow();
    });
  }

  DateTime _wallNow() {
    _nowUtc = _utcNow();
    final location = _settings.location.value;
    return location == null ? floatingNow() : _clock.nowAt(location);
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

  late final hijriDate = computed(
    () => HijriDate.fromGregorian(
      dateKey.value,
      offsetDays: _settings.settings.value.hijriOffsetDays,
    ),
  );

  /// The Islamic day begins at Maghrib: from then until midnight the Home
  /// header shows tomorrow's Hijri date (null otherwise). [hijriDate], which
  /// drives Ramadan mode and the calendar, stays midnight-based.
  late final hijriAfterMaghrib = computed<HijriDate?>(() {
    final day = prayerDay.value;
    if (day == null || now.value.isBefore(day.maghrib)) {
      return null;
    }
    final d = dateKey.value;
    return HijriDate.fromGregorian(
      DateTime(d.year, d.month, d.day + 1),
      offsetDays: _settings.settings.value.hijriOffsetDays,
    );
  });
  late final banglaDate = computed(
    () => BanglaDate.fromGregorian(dateKey.value),
  );

  /// Ramadan per the offset-adjusted [hijriDate] (drives the countdown's
  /// sahri/iftar overrides).
  late final ramadanMode = computed(
    () => hijriDate.value.month == HijriDate.ramadanMonth,
  );

  /// Whether yesterday was a fast day: its iftar can fall after midnight.
  late final _ramadanYesterday = computed(() {
    final d = dateKey.value;
    return HijriDate.fromGregorian(
          DateTime(d.year, d.month, d.day - 1),
          offsetDays: _settings.settings.value.hijriOffsetDays,
        ).month ==
        HijriDate.ramadanMonth;
  });

  /// The mosque active right now (manual selection, schedule, or override),
  /// memoized so the home subtree rebuilds only when it actually changes.
  late final mosqueResolution = computed(
    () => resolveActiveMosque(_mosque.state.value, now.value),
  );

  /// The schedule's current target ignoring any override — drives override
  /// expiry. Memoized (String?), so it flips only at a window boundary.
  late final _autoMosqueId = computed(
    () => resolveAutoMosqueId(_mosque.state.value, now.value),
  );

  /// Each waqt's jamaat config: the mosque active at that waqt's start
  /// (yesterday's for the overnight waqt) — unless the waqt has begun and an
  /// override is in effect now. The same rule notifications schedule by, so
  /// Home's rows and countdown match the reminders. One memoized computed per
  /// prayer: reads `now` every second but flips only when a config changes.
  late final Map<Prayer, Computed<JamaatConfig>> _waqtConfig = {
    for (final prayer in Prayer.values)
      prayer: computed(() {
        final range = waqtRangeOf(prayer);
        if (range == null) {
          return JamaatConfig.none;
        }
        return resolveMosqueForWaqt(
              _mosque.state.value,
              range.$1,
              now.value,
            ).profile?.config ??
            JamaatConfig.none;
      }),
  };

  /// Whether today's Dhuhr reads Jumu'ah: a Friday, and the mosque that
  /// Dhuhr follows has a Jumu'ah time. Memoized: flips at most at a day or
  /// mosque change.
  late final jumuahToday = computed(
    () =>
        prayerDay.value?.dhuhr.weekday == DateTime.friday &&
        _waqtConfig[Prayer.dhuhr]!.value.jumuah != null,
  );

  /// Each prayer row's jamaat moment, from that waqt's mosque
  /// ([_waqtConfig]). A jamaat at or past its waqt's end is stale (e.g. a
  /// summer time in winter) and left out, as the countdown and
  /// notifications do.
  late final rowJamaat = computed<Map<Prayer, DateTime>>(() {
    if (prayerDay.value == null) {
      return const {};
    }
    final rows = <Prayer, DateTime>{};
    for (final prayer in Prayer.values) {
      final (start, end) = waqtRangeOf(prayer)!;
      final config = _waqtConfig[prayer]!.value;
      if (config.timeFor(prayer, start) case final t? when t.isBefore(end)) {
        rows[prayer] = t;
      }
    }
    return rows;
  });

  /// Sets a temporary override to [mosqueId] (auto mode), baselined to the
  /// schedule's current target so it self-expires at the next window boundary.
  Future<void> overrideMosque(String mosqueId) => _mosque.setOverride(
    mosqueId,
    resolveAutoMosqueId(_mosque.state.value, now.value),
    now.value,
  );

  Future<void> clearMosqueOverride() => _mosque.clearOverride();

  /// All saved mosque profiles (for the home switcher).
  late final mosqueProfiles = computed<List<MosqueProfile>>(
    () => _mosque.state.value.profiles,
  );

  /// Picks a mosque from the home switcher: a temporary override in auto mode,
  /// or a permanent active switch in manual mode.
  Future<void> selectMosque(String id) =>
      _mosque.state.value.mode == ScheduleMode.auto
      ? overrideMosque(id)
      : _mosque.setActive(id);

  late final countdownTarget = computed<CountdownTarget?>(() {
    final day = prayerDay.value;
    if (day == null) {
      return null;
    }
    return resolveCountdownTarget(
      now: now.value,
      day: day,
      // The running waqt's mosque, as its row and notifications use.
      jamaat: switch (activeWaqt.value?.prayer) {
        final prayer? => _waqtConfig[prayer]!.value,
        null => JamaatConfig.none,
      },
      ramadanMode: ramadanMode.value,
      ramadanTonight: sahriInRamadan.value,
      ramadanYesterday: _ramadanYesterday.value,
    );
  });

  /// Changes once per waqt — the table's highlight dependency.
  late final activeWaqt = computed(
    () => prayerDay.value?.activeWaqtAt(now.value),
  );

  /// From iftar (= Maghrib) to midnight. One switch for [nextSahriEnd] and
  /// [sahriFastDay], so the card's fast day and sahri time flip together.
  late final _afterIftar = computed(() {
    final day = prayerDay.value;
    return day != null && !now.value.isBefore(day.iftar);
  });

  /// Today's sahri end until iftar, then tonight's (before tomorrow's Fajr).
  late final nextSahriEnd = computed<DateTime?>(() {
    final day = prayerDay.value;
    if (day == null) {
      return null;
    }
    return _afterIftar.value
        ? day.fajrTomorrow.subtract(day.sahriSafety)
        : day.sahriEnd;
  });

  /// The day whose fast the sahri/iftar card is about: today until iftar,
  /// then tomorrow — from iftar the card shows tonight's sahri, which
  /// opens tomorrow's fast.
  late final sahriFastDay = computed<DateTime>(() {
    final d = dateKey.value;
    return _afterIftar.value ? DateTime(d.year, d.month, d.day + 1) : d;
  });

  /// Whether [sahriFastDay] is in Ramadan (offset-aware): no "sahri ends
  /// tonight" on Eid eve, and it already shows the evening before 1 Ramadan.
  late final sahriInRamadan = computed(
    () =>
        (hijriAfterMaghrib.value ?? hijriDate.value).month ==
        HijriDate.ramadanMonth,
  );

  /// True after midnight but before Fajr: the active waqt is yesterday's.
  late final _preFajr = computed(() {
    final day = prayerDay.value;
    return day != null && now.value.isBefore(day.fajr);
  });

  /// Yesterday's waqt still running after midnight (Isha, or Maghrib when
  /// that Isha starts past midnight), or null once Fajr begins.
  late final overnightRange = computed<ActiveWaqt?>(
    () => _preFajr.value ? activeWaqt.value : null,
  );

  /// [overnightRange]'s prayer.
  late final overnightWaqt = computed<Prayer?>(
    () => overnightRange.value?.prayer,
  );

  /// The window a table row shows: yesterday's for the overnight waqt,
  /// today's otherwise (null until a location is set).
  (DateTime, DateTime)? waqtRangeOf(Prayer prayer) {
    final day = prayerDay.value;
    if (day == null) {
      return null;
    }
    return switch (overnightRange.value) {
      final o? when o.prayer == prayer => (o.start, o.end),
      _ => (day.startOf(prayer), day.endOf(prayer)),
    };
  }

  /// The muhasaba day a prayer's check-in belongs to: today, except the
  /// overnight waqt before Fajr, which is still yesterday's (the same day
  /// the azan notification's "mark as prayed" files it under).
  DateTime salahDate(Prayer prayer) {
    final d = dateKey.value;
    return prayer == overnightWaqt.value
        ? DateTime(d.year, d.month, d.day - 1)
        : d;
  }

  /// Bitmask of prayers whose waqt has started (overnight: yesterday's
  /// waqt counts). Reads `now` every second but its value only flips at a
  /// waqt boundary, so downstream (the table) doesn't rebuild per second.
  late final _startedMask = computed<int>(() {
    final day = prayerDay.value;
    if (day == null) {
      return 0;
    }
    final n = now.value;
    var mask = 0;
    for (final (i, prayer) in Prayer.values.indexed) {
      if (!n.isBefore(day.startOf(prayer)) || prayer == overnightWaqt.value) {
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
  /// day changes or Fajr begins, so the special-times card doesn't rebuild per second.
  late final specialWindows = computed<List<SpecialWindow>>(() {
    final day = prayerDay.value;
    if (day == null) {
      return const [];
    }
    return resolveSpecialWindows(
      day,
      preFajr: _preFajr.value,
      zone: switch (location.value) {
        final loc? => (
          instantOf: (wall) => _clock.utcInstantOf(loc, wall),
          wallOf: (instant) => _clock.instantAt(loc, instant),
        ),
        null => null,
      },
    );
  });

  /// The special window the clock is currently inside, or null. A value
  /// type, so it only flips at a window boundary (no per-second rebuild).
  late final activeSpecial = computed<SpecialWindow?>(() {
    final n = now.value;
    for (final w in specialWindows.value) {
      if (w.containsAt(n)) {
        return w;
      }
    }
    return null;
  });

  /// The window to surface on Home: the one running now, else the next to
  /// start today. Flips only at a window boundary.
  late final currentOrNextSpecial = computed<SpecialWindow?>(() {
    if (activeSpecial.value case final active?) {
      return active;
    }
    final n = now.value;
    SpecialWindow? next;
    for (final w in specialWindows.value) {
      if (w.start.isAfter(n) &&
          (next == null || w.start.isBefore(next.start))) {
        next = w;
      }
    }
    return next;
  });

  /// Per-second values, isolated so only the hero numeral subtree ticks.
  late final remaining = computed(() {
    final target = countdownTarget.value;
    if (target == null) {
      return Duration.zero;
    }
    // Through real instants: wall times are floating, so subtracting them
    // directly would miss the location's own DST shift.
    final r = target.remainingAt(now.value, instantOf.value, _nowInstant());
    return r.isNegative ? Duration.zero : r;
  });

  late final progress = computed(
    () =>
        countdownTarget.value?.progressAt(
          now.value,
          instantOf.value,
          _nowInstant(),
        ) ??
        0.0,
  );

  /// [now]'s real instant (null until setup): the device instant read with
  /// it, so the location's repeated fall-back hour isn't guessed.
  DateTime? _nowInstant() => switch (location.value) {
    final loc? => nowInstant(
      now.value,
      deviceUtc: _nowUtc,
      instantOf: (wall) => _clock.utcInstantOf(loc, wall),
      wallOf: (instant) => _clock.instantAt(loc, instant),
    ),
    null => null,
  };

  /// Wall time → real instant at the location (null until setup).
  late final instantOf = computed<DateTime Function(DateTime)?>(() {
    final loc = location.value;
    return loc == null ? null : (wall) => _clock.utcInstantOf(loc, wall);
  });

  /// Stops the tick outright (Home itself gone); [resume] restarts it.
  void stop() {
    _ticker?.cancel();
    _ticker = null;
    _period = null;
  }

  void dispose() {
    stop();
    _overrideWatcher();
  }
}
