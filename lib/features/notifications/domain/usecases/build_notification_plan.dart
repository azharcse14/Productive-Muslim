import '../../../my_mosque/domain/entities/jamaat_config.dart';
import '../../../prayer_times/domain/entities/prayer_day.dart';
import '../../../settings/domain/entities/notification_matrix.dart';
import '../../../settings/domain/entities/prayer_params.dart';
import '../entities/notification_item.dart';

/// Builds the ~48h notification plan (guide §5) as pure logic.
///
/// [days] are consecutive [PrayerDay]s starting at [from]'s day — pass
/// three so a late-evening [from] still fills the whole window.
/// Only items strictly after [from] and within [window] are planned.
List<NotificationItem> buildNotificationPlan({
  required DateTime from,
  required List<PrayerDay> days,
  required NotificationMatrix matrix,
  required JamaatConfig jamaat,
  Duration window = const Duration(hours: 48),
}) {
  final until = from.add(window);
  final items = <NotificationItem>[];

  bool inWindow(DateTime at) => at.isAfter(from) && !at.isAfter(until);

  for (final day in days) {
    // Azan per prayer, honoring the matrix mode.
    for (final prayer in Prayer.values) {
      final mode = matrix.modeFor(prayer);
      final start = day.startOf(prayer);
      if (mode != AzanMode.off && inWindow(start)) {
        items.add(
          NotificationItem(
            kind: NotificationKind.azan,
            prayer: prayer,
            at: start,
            silent: mode == AzanMode.silent,
            beepOnly: mode == AzanMode.beep,
          ),
        );
      }

      // Jamaat reminder: requires the global toggle AND a configured
      // entry for this prayer.
      if (matrix.jamaatReminder) {
        final jamaatAt = jamaat.timeFor(prayer, start);
        if (jamaatAt != null) {
          final remindAt = jamaatAt.subtract(matrix.jamaatLead);
          if (inWindow(remindAt)) {
            items.add(
              NotificationItem(
                kind: NotificationKind.jamaat,
                prayer: prayer,
                at: remindAt,
              ),
            );
          }
        }
      }
    }

    if (matrix.sahriAlert) {
      final warnAt = day.sahriEnd.subtract(matrix.sahriLead);
      if (inWindow(warnAt)) {
        items.add(
          NotificationItem(kind: NotificationKind.sahriWarning, at: warnAt),
        );
      }
    }

    if (matrix.iftarAlert && inWindow(day.iftar)) {
      items.add(NotificationItem(kind: NotificationKind.iftar, at: day.iftar));
    }

    // Evening nudge — max one per day, at isha + 45 min (quiet hour
    // before sleep, after the last prayer of the day).
    if (matrix.muhasabaEveningReminder) {
      final nudgeAt = day.isha.add(const Duration(minutes: 45));
      if (inWindow(nudgeAt)) {
        items.add(
          NotificationItem(kind: NotificationKind.muhasabaEvening, at: nudgeAt),
        );
      }
    }
  }

  items.sort((a, b) => a.at.compareTo(b.at));
  return items;
}
