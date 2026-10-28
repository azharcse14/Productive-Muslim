import '../../../my_mosque/domain/entities/jamaat_config.dart';
import '../../../prayer_times/domain/entities/prayer_day.dart';
import '../../../settings/domain/entities/notification_matrix.dart';
import '../../../settings/domain/entities/prayer_params.dart';

/// One jamaat focus session: phone silent (and on Android, locked) from
/// [start] until [end], or until the user ends it when [end] is null.
final class FocusWindow {
  const FocusWindow({required this.prayer, required this.start, this.end});

  final Prayer prayer;

  /// Wall-clock moments at the configured location.
  final DateTime start;
  final DateTime? end;

  @override
  bool operator ==(Object other) =>
      other is FocusWindow &&
      other.prayer == prayer &&
      other.start == start &&
      other.end == end;

  @override
  int get hashCode => Object.hash(prayer, start, end);

  @override
  String toString() => 'FocusWindow($prayer, $start → $end)';
}

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
  final length = matrix.jamaatFocusDuration;
  final windows = <FocusWindow>[];
  for (final day in days) {
    for (final prayer in Prayer.values) {
      if (!matrix.jamaatFocusPrayers.contains(prayer)) {
        continue;
      }
      final waqt = day.startOf(prayer);
      final jamaatTime = (jamaatAt?.call(waqt) ?? jamaat).timeFor(prayer, waqt);
      if (jamaatTime == null) {
        continue;
      }
      final start = jamaatTime.subtract(matrix.jamaatFocusLead);
      final end = length == Duration.zero ? null : start.add(length);
      if (start.isAfter(until) || !(end ?? start).isAfter(from)) {
        continue;
      }
      windows.add(FocusWindow(prayer: prayer, start: start, end: end));
    }
  }
  windows.sort((a, b) => a.start.compareTo(b.start));
  return windows;
}
