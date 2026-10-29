import '../../../my_mosque/domain/entities/jamaat_config.dart';
import '../../../settings/domain/entities/prayer_params.dart';
import '../entities/countdown_target.dart';
import '../entities/prayer_day.dart';

/// The smart-countdown state machine (guide §5) — a pure function with
/// exhaustive tests. Rules:
///
/// 1. Ramadan overrides:
///    - before sahri end → "Sahri ends in" (Fajr minus the safety margin)
///    - Asr start → Maghrib → "Iftar in" (targets Maghrib)
/// 2. Between waqts (sunrise→dhuhr gap) → next waqt start.
/// 3. Inside a waqt, jamaat configured for it AND still in the future →
///    jamaat; otherwise → waqt end.
CountdownTarget resolveCountdownTarget({
  required DateTime now,
  required PrayerDay day,
  required JamaatConfig jamaat,
  required bool ramadanMode,
}) {
  if (ramadanMode) {
    if (now.isBefore(day.sahriEnd)) {
      return CountdownTarget(
        kind: CountdownKind.sahriEnd,
        prayer: Prayer.fajr,
        at: day.sahriEnd,
        windowStart: day.ishaYesterday,
      );
    }
    if (!now.isBefore(day.asr) && now.isBefore(day.maghrib)) {
      return CountdownTarget(
        kind: CountdownKind.iftar,
        prayer: Prayer.maghrib,
        at: day.iftar,
        windowStart: day.asr,
      );
    }
  }

  final active = day.activeWaqtAt(now);
  if (active == null) {
    // Sunrise→dhuhr gap: count toward the next waqt start.
    return CountdownTarget(
      kind: CountdownKind.waqtStart,
      prayer: Prayer.dhuhr,
      at: day.dhuhr,
      windowStart: day.sunrise,
    );
  }

  final jamaatAt = jamaat.timeFor(active.prayer, active.start);
  if (jamaatAt != null && jamaatAt.isAfter(now)) {
    return CountdownTarget(
      kind: CountdownKind.jamaat,
      prayer: active.prayer,
      at: jamaatAt,
      windowStart: active.start,
    );
  }

  return CountdownTarget(
    kind: CountdownKind.waqtEnd,
    prayer: active.prayer,
    at: active.end,
    windowStart: active.start,
  );
}

/// Visual urgency for the countdown card (design: calm → amber when
/// jamaat ≤ [jamaatSoon] → urgent in the last [waqtEnding] of the waqt;
/// Ramadan targets carry their own states). Once the target's prayer is
/// [prayed] there is nothing left to rush: calm. Inside a [forbidden]
/// (makruh) window the card warns: urgent.
CountdownUrgency countdownUrgencyFor({
  required DateTime now,
  required CountdownTarget target,
  bool prayed = false,
  bool forbidden = false,
  Duration jamaatSoon = const Duration(minutes: 10),
  Duration waqtEnding = const Duration(minutes: 20),
  DateTime Function(DateTime)? instantOf,
}) {
  final remaining = target.remainingAt(now, instantOf);
  return switch (target.kind) {
    CountdownKind.sahriEnd => CountdownUrgency.sahri,
    CountdownKind.iftar => CountdownUrgency.iftar,
    _ when prayed => CountdownUrgency.calm,
    _ when forbidden => CountdownUrgency.urgent,
    CountdownKind.jamaat when remaining <= jamaatSoon => CountdownUrgency.amber,
    CountdownKind.waqtEnd when remaining <= waqtEnding =>
      CountdownUrgency.urgent,
    _ => CountdownUrgency.calm,
  };
}
