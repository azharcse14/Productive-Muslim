import '../../../../core/utils/hijri_date.dart';
import '../../../my_mosque/domain/entities/jamaat_config.dart';
import '../../../prayer_times/domain/entities/prayer_day.dart';
import '../../../settings/domain/entities/notification_matrix.dart';
import '../../../settings/domain/entities/prayer_params.dart';
import '../entities/notification_item.dart';

/// Builds the notification plan (guide §5) as pure logic.
///
/// [days] are consecutive [PrayerDay]s starting at [from]'s day — pass
/// enough to cover [window] plus one so a late-evening [from] still fills
/// the whole window. Only items strictly after [from] and within [window]
/// are planned.
///
/// [maxItems] caps the plan (iOS allows only 64 pending notifications);
/// the earliest items are kept. With [keepAlive], one extra low-priority
/// [NotificationKind.keepAlive] item fires a minute after the last planned
/// item, asking the user to open the app so the schedule is refilled. It
/// counts toward [maxItems].
///
/// Sahri/iftar alerts are Ramadan-only: a day qualifies when its Gregorian
/// date maps to Ramadan with [hijriOffsetDays] applied (same rule as the
/// home countdown's `ramadanMode`).
List<NotificationItem> buildNotificationPlan({
  required DateTime from,
  required List<PrayerDay> days,
  required NotificationMatrix matrix,
  required JamaatConfig jamaat,
  Duration window = const Duration(hours: 48),
  int? maxItems,
  bool keepAlive = false,
  int hijriOffsetDays = 0,
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

    final date = DateTime(day.fajr.year, day.fajr.month, day.fajr.day);
    final ramadan =
        HijriDate.fromGregorian(date, offsetDays: hijriOffsetDays).month ==
            HijriDate.ramadanMonth;

    if (ramadan && matrix.sahriAlert) {
      final warnAt = day.sahriEnd.subtract(matrix.sahriLead);
      if (inWindow(warnAt)) {
        items.add(
          NotificationItem(kind: NotificationKind.sahriWarning, at: warnAt),
        );
      }
    }

    if (ramadan && matrix.iftarAlert && inWindow(day.iftar)) {
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

    // Daily "content of the day" reminder — once per day at the user's chosen
    // local time (minutes past midnight). Anchored to the day's fajr date so a
    // 3-day window yields at most one per calendar day.
    if (matrix.dailyReminder) {
      // Field constructor, not midnight + Duration: stays on the wall-clock
      // time across a DST shift.
      final minute = matrix.dailyReminderMinute;
      final remindAt =
          DateTime(date.year, date.month, date.day, minute ~/ 60, minute % 60);
      if (inWindow(remindAt)) {
        items.add(
          NotificationItem(kind: NotificationKind.dailyReminder, at: remindAt),
        );
      }
    }
  }

  items.sort((a, b) => a.at.compareTo(b.at));
  final cap = maxItems == null ? null : maxItems - (keepAlive ? 1 : 0);
  final plan = cap != null && items.length > cap
      ? items.sublist(0, cap < 0 ? 0 : cap)
      : items;
  if (keepAlive && plan.isNotEmpty) {
    plan.add(
      NotificationItem(
        kind: NotificationKind.keepAlive,
        at: plan.last.at.add(const Duration(minutes: 1)),
      ),
    );
  }
  return plan;
}
