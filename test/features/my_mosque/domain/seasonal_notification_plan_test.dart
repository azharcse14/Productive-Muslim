import 'package:flutter_test/flutter_test.dart';
import 'package:productive_muslim/features/my_mosque/domain/entities/jamaat_config.dart';
import 'package:productive_muslim/features/my_mosque/domain/entities/mosque_profile.dart';
import 'package:productive_muslim/features/my_mosque/domain/entities/mosque_schedule.dart';
import 'package:productive_muslim/features/my_mosque/domain/entities/mosque_state.dart';
import 'package:productive_muslim/features/my_mosque/domain/usecases/resolve_active_mosque.dart';
import 'package:productive_muslim/features/notifications/domain/entities/notification_item.dart';
import 'package:productive_muslim/features/notifications/domain/usecases/build_notification_plan.dart';
import 'package:productive_muslim/features/prayer_times/domain/entities/prayer_day.dart';
import 'package:productive_muslim/features/settings/domain/entities/notification_matrix.dart';
import 'package:productive_muslim/features/settings/domain/entities/prayer_params.dart';

PrayerDay _day(DateTime d) => PrayerDay(
  ishaYesterday: DateTime(d.year, d.month, d.day - 1, 19),
  fajr: DateTime(d.year, d.month, d.day, 4, 50),
  sunrise: DateTime(d.year, d.month, d.day, 6, 5),
  dhuhr: DateTime(d.year, d.month, d.day, 11, 45),
  asr: DateTime(d.year, d.month, d.day, 15, 30),
  maghrib: DateTime(d.year, d.month, d.day, 17, 20),
  isha: DateTime(d.year, d.month, d.day, 18, 35),
  fajrTomorrow: DateTime(d.year, d.month, d.day + 1, 4, 50),
);

void main() {
  test('jamaat reminders switch mosque on the day a season starts', () {
    // Summer Dhuhr 13:15 by default; the winter profile (12:45) from Nov 1.
    const state = MosqueState(
      profiles: [
        MosqueProfile(
          id: 'summer',
          name: 'Summer',
          entries: {Prayer.dhuhr: FixedJamaat(ClockTime(13, 15))},
        ),
        MosqueProfile(
          id: 'winter',
          name: 'Winter',
          entries: {Prayer.dhuhr: FixedJamaat(ClockTime(12, 45))},
        ),
      ],
      mode: ScheduleMode.auto,
      defaultId: 'summer',
      seasons: [
        MosqueSeason(
          mosqueId: 'winter',
          start: (month: 11, day: 1),
          end: (month: 2, day: 28),
        ),
      ],
    );
    final days = [for (var d = 30; d <= 36; d++) _day(DateTime(2026, 10, d))];
    // As NotificationController wires it.
    final plan = buildNotificationPlan(
      from: DateTime(2026, 10, 30, 3),
      days: days,
      matrix: const NotificationMatrix(jamaatReminder: true),
      jamaat: JamaatConfig.none,
      jamaatAt: (at) =>
          resolveActiveMosque(state, at).profile?.config ?? JamaatConfig.none,
      window: const Duration(days: 7),
    );
    final dhuhr = [
      for (final i in plan)
        if (i.kind == NotificationKind.jamaat && i.prayer == Prayer.dhuhr) i.at,
    ];
    expect(dhuhr, [
      DateTime(2026, 10, 30, 13), // 13:15 − 15, summer
      DateTime(2026, 10, 31, 13),
      DateTime(2026, 11, 1, 12, 30), // 12:45 − 15, winter from Nov 1
      DateTime(2026, 11, 2, 12, 30),
      DateTime(2026, 11, 3, 12, 30),
      DateTime(2026, 11, 4, 12, 30),
      DateTime(2026, 11, 5, 12, 30),
    ]);
  });
}
