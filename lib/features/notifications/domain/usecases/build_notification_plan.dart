import '../../../../core/utils/hijri_date.dart';
import '../../../my_mosque/domain/entities/jamaat_config.dart';
import '../../../prayer_times/domain/entities/prayer_day.dart';
import '../../../settings/domain/entities/notification_matrix.dart';
import '../../../settings/domain/entities/prayer_params.dart';
import '../entities/notification_item.dart';
import 'build_focus_windows.dart';

/// Builds the notification plan (guide §5) as pure logic.
///
/// [days] are consecutive [PrayerDay]s covering [window] — start the day
/// before [from]'s (its isha may fall after midnight) and pass one spare so
/// a late-evening [from] still fills the whole window. Only items strictly after [from] and within [window]
/// are planned.
///
/// [maxItems] caps the plan (iOS allows only 64 pending notifications);
/// the earliest items are kept. With [keepAlive], one extra low-priority
/// [NotificationKind.keepAlive] item asks the user to open the app so the
/// schedule is refilled — [keepAliveLead] before the last planned item, so
/// there is time to act before reminders run out (a minute after it when
/// the plan is shorter than that). It counts toward [maxItems].
///
/// Sahri/iftar alerts are Ramadan-only: a day qualifies when its Gregorian
/// date maps to Ramadan with [hijriOffsetDays] applied (same rule as the
/// home countdown's `ramadanMode`).
///
/// [jamaatAt], when given, resolves the jamaat config at each prayer's waqt
/// start (so time-based mosque rules apply per prayer) and takes precedence
/// over [jamaat].
///
/// Each of [focusWindows] with an end gets a [NotificationKind.focusEnd]
/// item then; with [focusStartNudges] (iOS, where the app can't silence
/// the phone) also a [NotificationKind.jamaatFocus] nudge at its start.
/// How long before the plan's last reminder the keep-alive nudge fires.
const keepAliveLead = Duration(hours: 12);

List<NotificationItem> buildNotificationPlan({
  required DateTime from,
  required List<PrayerDay> days,
  required NotificationMatrix matrix,
  required JamaatConfig jamaat,
  JamaatConfig Function(DateTime at)? jamaatAt,
  Duration window = const Duration(hours: 48),
  int? maxItems,
  bool keepAlive = false,
  int hijriOffsetDays = 0,
  List<FocusWindow> focusWindows = const [],
  bool focusStartNudges = false,
}) {
  final until = from.add(window);
  final items = <NotificationItem>[];

  bool inWindow(DateTime at) => at.isAfter(from) && !at.isAfter(until);

  for (final day in days) {
    // Azan per prayer, honoring the matrix mode.
    for (final prayer in Prayer.values) {
      final mode = matrix.modeFor(prayer);
      final start = day.startOf(prayer);
      final config = jamaatAt?.call(start) ?? jamaat;
      final jumuah = config.isJumuah(prayer, start);
      if (mode != AzanMode.off && inWindow(start)) {
        items.add(
          NotificationItem(
            kind: NotificationKind.azan,
            prayer: prayer,
            prayerDay: DateTime(day.fajr.year, day.fajr.month, day.fajr.day),
            at: start,
            silent: mode == AzanMode.silent,
            beepOnly: mode == AzanMode.beep,
            jumuah: jumuah,
          ),
        );
      }

      // Jamaat reminder: requires the global toggle AND a configured
      // entry for this prayer.
      if (matrix.jamaatReminder) {
        final jamaatTime = config.timeFor(prayer, start);
        if (jamaatTime != null) {
          final remindAt = jamaatTime.subtract(matrix.jamaatLead);
          if (inWindow(remindAt)) {
            items.add(
              NotificationItem(
                kind: NotificationKind.jamaat,
                prayer: prayer,
                at: remindAt,
                eventAt: jamaatTime,
                jumuah: jumuah,
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
          NotificationItem(
            kind: NotificationKind.sahriWarning,
            at: warnAt,
            eventAt: day.sahriEnd,
          ),
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
      final remindAt = DateTime(
        date.year,
        date.month,
        date.day,
        minute ~/ 60,
        minute % 60,
      );
      if (inWindow(remindAt)) {
        items.add(
          NotificationItem(kind: NotificationKind.dailyReminder, at: remindAt),
        );
      }
    }

    if (matrix.dailyAyahReminder) {
      final minute = matrix.dailyAyahMinute;
      final remindAt = DateTime(
        date.year,
        date.month,
        date.day,
        minute ~/ 60,
        minute % 60,
      );
      if (inWindow(remindAt)) {
        items.add(
          NotificationItem(kind: NotificationKind.dailyAyah, at: remindAt),
        );
      }
    }

    if (matrix.dailyHadithReminder) {
      final minute = matrix.dailyHadithMinute;
      final remindAt = DateTime(
        date.year,
        date.month,
        date.day,
        minute ~/ 60,
        minute % 60,
      );
      if (inWindow(remindAt)) {
        items.add(
          NotificationItem(kind: NotificationKind.dailyHadith, at: remindAt),
        );
      }
    }
  }

  for (final focus in focusWindows) {
    if (focusStartNudges && inWindow(focus.start)) {
      items.add(
        NotificationItem(
          kind: NotificationKind.jamaatFocus,
          prayer: focus.prayer,
          at: focus.start,
          jumuah: focus.jumuah,
        ),
      );
    }
    final end = focus.end;
    if (end != null && inWindow(end)) {
      items.add(
        NotificationItem(
          kind: NotificationKind.focusEnd,
          prayer: focus.prayer,
          prayerDay: focus.prayerDay,
          at: end,
          jumuah: focus.jumuah,
        ),
      );
    }
  }

  items.sort((a, b) => a.at.compareTo(b.at));
  final cap = maxItems == null ? null : maxItems - (keepAlive ? 1 : 0);
  final plan = cap != null && items.length > cap
      ? items.sublist(0, cap < 0 ? 0 : cap)
      : items;
  if (keepAlive && plan.isNotEmpty) {
    final last = plan.last.at;
    final early = last.subtract(keepAliveLead);
    final at = early.isAfter(from)
        ? early
        : last.add(const Duration(minutes: 1));
    // Inserted in time order (no re-sort: List.sort isn't stable).
    final index = plan.indexWhere((i) => i.at.isAfter(at));
    plan.insert(
      index < 0 ? plan.length : index,
      NotificationItem(kind: NotificationKind.keepAlive, at: at),
    );
  }
  return plan;
}
