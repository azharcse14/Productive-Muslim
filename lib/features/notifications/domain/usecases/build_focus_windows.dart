import '../../../my_mosque/domain/entities/jamaat_config.dart';
import '../../../prayer_times/domain/entities/prayer_day.dart';
import '../../../settings/domain/entities/notification_matrix.dart';
import '../../../settings/domain/entities/prayer_params.dart';

/// One jamaat focus session: phone silent (and on Android, locked) from
/// [start] until [end], or until the user ends it when [end] is null.
final class FocusWindow {
  const FocusWindow({
    required this.prayer,
    required this.start,
    this.end,
    this.prayerDay,
    this.jumuah = false,
  });

  final Prayer prayer;

  /// Friday's Dhuhr with a Jumu'ah time set.
  final bool jumuah;

  /// Date of the prayer day's fajr — differs from [start]'s date when isha
  /// runs past midnight (high latitudes). Files "mark as prayed".
  final DateTime? prayerDay;

  /// Wall-clock moments at the configured location.
  final DateTime start;
  final DateTime? end;

  /// Stable id of the jamaat (yyyymmdd of [prayerDay] × 10 + prayer slot),
  /// so the native engine knows a re-sent window that moved is the session
  /// it already ran. 0 when [prayerDay] is unknown.
  int get key => switch (prayerDay) {
    final d? =>
      (d.year * 10000 + d.month * 100 + d.day) * 10 +
          switch (prayer) {
            Prayer.fajr => 1,
            Prayer.dhuhr => 2,
            Prayer.asr => 3,
            Prayer.maghrib => 4,
            Prayer.isha => 5,
          },
    null => 0,
  };

  @override
  bool operator ==(Object other) =>
      other is FocusWindow &&
      other.prayer == prayer &&
      other.start == start &&
      other.end == end &&
      other.jumuah == jumuah;

  @override
  int get hashCode => Object.hash(prayer, start, end, jumuah);

  @override
  String toString() => 'FocusWindow($prayer, $start → $end)';
}

/// How late an "until I end it" session may still start natively — keep in
/// sync with `MANUAL_GRACE_MS` in android/.../JamaatFocus.kt.
const focusManualGrace = Duration(minutes: 30);

/// Jamaat focus sessions over [days] (same contract as
/// `buildNotificationPlan`): each enabled prayer with a jamaat time yields
/// one session starting `jamaatFocusLead` before jamaat. Sessions still
/// running at [from] are kept so a reschedule mid-session doesn't drop it;
/// only those starting within [window] are planned.
List<FocusWindow> buildFocusWindows({
  required DateTime from,
  required List<PrayerDay> days,
  required NotificationMatrix matrix,
  JamaatConfig jamaat = JamaatConfig.none,
  JamaatConfig Function(DateTime at)? jamaatAt,
  Duration window = const Duration(hours: 48),
}) {
  if (!matrix.jamaatFocus) {
    return const [];
  }
  final until = from.add(window);
  final length = matrix.effectiveFocusDuration;
  final windows = <FocusWindow>[];
  for (final day in days) {
    for (final prayer in Prayer.values) {
      if (!matrix.jamaatFocusPrayers.contains(prayer)) {
        continue;
      }
      final waqt = day.startOf(prayer);
      final config = jamaatAt?.call(waqt) ?? jamaat;
      final jamaatTime = config.timeFor(prayer, waqt);
      if (jamaatTime == null) {
        continue;
      }
      final start = jamaatTime.subtract(matrix.jamaatFocusLead);
      final end = length == Duration.zero ? null : start.add(length);
      // Open-ended sessions stay planned through the native late-start grace.
      if (start.isAfter(until) ||
          !(end ?? start.add(focusManualGrace)).isAfter(from)) {
        continue;
      }
      windows.add(
        FocusWindow(
          prayer: prayer,
          start: start,
          end: end,
          prayerDay: DateTime(day.fajr.year, day.fajr.month, day.fajr.day),
          jumuah: config.isJumuah(prayer, waqt),
        ),
      );
    }
  }
  windows.sort((a, b) => a.start.compareTo(b.start));
  return windows;
}
