import 'package:flutter_test/flutter_test.dart';
import 'package:productive_muslim/features/my_mosque/domain/entities/jamaat_config.dart';
import 'package:productive_muslim/features/notifications/domain/entities/notification_item.dart';
import 'package:productive_muslim/features/notifications/domain/usecases/build_notification_plan.dart';
import 'package:productive_muslim/features/prayer_times/domain/entities/prayer_day.dart';
import 'package:productive_muslim/features/settings/domain/entities/notification_matrix.dart';
import 'package:productive_muslim/features/settings/domain/entities/prayer_params.dart';

PrayerDay _day(int day) => PrayerDay(
      ishaYesterday: DateTime(2026, 6, day - 1, 20, 15),
      fajr: DateTime(2026, 6, day, 3, 45),
      sunrise: DateTime(2026, 6, day, 5, 10),
      dhuhr: DateTime(2026, 6, day, 12),
      asr: DateTime(2026, 6, day, 16, 30),
      maghrib: DateTime(2026, 6, day, 18, 45),
      isha: DateTime(2026, 6, day, 20, 15),
      fajrTomorrow: DateTime(2026, 6, day + 1, 3, 45),
    );

final _days = [_day(12), _day(13), _day(14)];
final _from = DateTime(2026, 6, 12, 3); // before fajr on day one

List<NotificationItem> _plan({
  NotificationMatrix matrix = const NotificationMatrix(),
  JamaatConfig jamaat = JamaatConfig.none,
  DateTime? from,
  Duration window = const Duration(hours: 48),
  int? maxItems,
  bool keepAlive = false,
}) =>
    buildNotificationPlan(
      from: from ?? _from,
      days: _days,
      matrix: matrix,
      jamaat: jamaat,
      window: window,
      maxItems: maxItems,
      keepAlive: keepAlive,
    );

void main() {
  group('buildNotificationPlan — azan items', () {
    test('defaults: one azan per prayer inside the 48h window', () {
      final azans =
          _plan().where((i) => i.kind == NotificationKind.azan).toList();
      // Day 12 all 5, day 13 all 5, day 14 nothing (fajr at 51h > 48h
      // window... fajr day14 = 14th 03:45, from 12th 03:00 → 48.75h: out).
      expect(azans.length, 10);
      expect(azans.every((a) => !a.silent && !a.beepOnly), isTrue);
    });

    test('off mode drops the prayer entirely', () {
      final plan = _plan(
        matrix: const NotificationMatrix(
          prayerModes: {Prayer.dhuhr: AzanMode.off},
        ),
      );
      final dhuhrAzans = plan.where(
        (i) => i.kind == NotificationKind.azan && i.prayer == Prayer.dhuhr,
      );
      expect(dhuhrAzans, isEmpty);
    });

    test('silent and beep modes carry their flags', () {
      final plan = _plan(
        matrix: const NotificationMatrix(
          prayerModes: {
            Prayer.fajr: AzanMode.silent,
            Prayer.asr: AzanMode.beep,
          },
        ),
      );
      final fajr = plan.firstWhere(
        (i) => i.kind == NotificationKind.azan && i.prayer == Prayer.fajr,
      );
      final asr = plan.firstWhere(
        (i) => i.kind == NotificationKind.azan && i.prayer == Prayer.asr,
      );
      expect(fajr.silent, isTrue);
      expect(asr.beepOnly, isTrue);
    });

    test('past items are never scheduled', () {
      final plan = _plan(from: DateTime(2026, 6, 12, 13)); // after dhuhr
      final day12Azans = plan.where(
        (i) =>
            i.kind == NotificationKind.azan &&
            i.at.day == 12 &&
            i.at.isBefore(DateTime(2026, 6, 12, 13)),
      );
      expect(day12Azans, isEmpty);
    });
  });

  group('buildNotificationPlan — sahri & iftar', () {
    test('sahri warning fires lead-time before fajr', () {
      final sahri = _plan()
          .where((i) => i.kind == NotificationKind.sahriWarning)
          .toList();
      expect(sahri.first.at, DateTime(2026, 6, 12, 3, 15)); // 30 min before
    });

    test('sahri warning counts back from the safety-adjusted sahri end', () {
      PrayerDay withMargin(int d) {
        final b = _day(d);
        return PrayerDay(
          ishaYesterday: b.ishaYesterday,
          fajr: b.fajr,
          sunrise: b.sunrise,
          dhuhr: b.dhuhr,
          asr: b.asr,
          maghrib: b.maghrib,
          isha: b.isha,
          fajrTomorrow: b.fajrTomorrow,
          sahriSafety: const Duration(minutes: 5),
        );
      }

      final plan = buildNotificationPlan(
        from: DateTime(2026, 6, 12, 2),
        days: [withMargin(12), withMargin(13)],
        matrix: const NotificationMatrix(),
        jamaat: JamaatConfig.none,
      );
      final sahri =
          plan.where((i) => i.kind == NotificationKind.sahriWarning).first;
      expect(sahri.at, DateTime(2026, 6, 12, 3, 10)); // 3:45 − 5 − 30
    });

    test('sahri toggle off removes warnings', () {
      final plan = _plan(matrix: const NotificationMatrix(sahriAlert: false));
      expect(
        plan.where((i) => i.kind == NotificationKind.sahriWarning),
        isEmpty,
      );
    });

    test('boundary: item exactly at `from` is excluded (custom lead)', () {
      final plan = _plan(
        matrix: const NotificationMatrix(sahriLead: Duration(minutes: 45)),
      );
      // 3:45 - 45min = 3:00 == from → excluded; next day's remains.
      final sahris =
          plan.where((i) => i.kind == NotificationKind.sahriWarning).toList();
      expect(sahris.first.at.day, 13);
    });

    test('iftar fires at maghrib when enabled', () {
      final iftars =
          _plan().where((i) => i.kind == NotificationKind.iftar).toList();
      expect(iftars.first.at, DateTime(2026, 6, 12, 18, 45));
      expect(iftars.length, 2);
    });
  });

  group('buildNotificationPlan — jamaat reminders', () {
    test('require both the toggle and a configured entry', () {
      const jamaat = JamaatConfig({
        Prayer.dhuhr: FixedJamaat(ClockTime(13, 15)),
      });
      // Toggle off → nothing.
      expect(
        _plan(jamaat: jamaat)
            .where((i) => i.kind == NotificationKind.jamaat),
        isEmpty,
      );
      // Toggle on → reminder lead-time before jamaat.
      final plan = _plan(
        jamaat: jamaat,
        matrix: const NotificationMatrix(jamaatReminder: true),
      );
      final reminders =
          plan.where((i) => i.kind == NotificationKind.jamaat).toList();
      expect(reminders.first.at, DateTime(2026, 6, 12, 13)); // 15 min lead
      expect(reminders.length, 2); // day 12 + 13
    });

    test('offset jamaat resolves from waqt start', () {
      const jamaat = JamaatConfig({
        Prayer.maghrib: OffsetJamaat(Duration(minutes: 5)),
      });
      final plan = _plan(
        jamaat: jamaat,
        matrix: const NotificationMatrix(
          jamaatReminder: true,
          jamaatLead: Duration(minutes: 10),
        ),
      );
      final reminder =
          plan.firstWhere((i) => i.kind == NotificationKind.jamaat);
      // 18:45 + 5 − 10 = 18:40.
      expect(reminder.at, DateTime(2026, 6, 12, 18, 40));
    });
  });

  group('buildNotificationPlan — muhasaba nudge', () {
    test('max one per day, 45 min after isha, only when enabled', () {
      expect(
        _plan().where((i) => i.kind == NotificationKind.muhasabaEvening),
        isEmpty,
      );
      final plan = _plan(
        matrix: const NotificationMatrix(muhasabaEveningReminder: true),
      );
      final nudges = plan
          .where((i) => i.kind == NotificationKind.muhasabaEvening)
          .toList();
      expect(nudges.length, 2);
      expect(nudges.first.at, DateTime(2026, 6, 12, 21));
      final perDay = <int>{for (final n in nudges) n.at.day};
      expect(perDay.length, nudges.length); // one per day
    });
  });

  group('buildNotificationPlan — daily reminder', () {
    test('off by default, one per day at the chosen minute when enabled', () {
      expect(
        _plan().where((i) => i.kind == NotificationKind.dailyReminder),
        isEmpty,
      );
      final plan = _plan(
        matrix: const NotificationMatrix(
          dailyReminder: true,
          dailyReminderMinute: 8 * 60, // 08:00 (non-default to be meaningful)
        ),
      );
      final reminders = plan
          .where((i) => i.kind == NotificationKind.dailyReminder)
          .toList();
      // Days 12 & 13 at 08:00 fall in the 48h window; day 14 is past it.
      expect(reminders.length, 2);
      expect(reminders.first.at, DateTime(2026, 6, 12, 8));
      final perDay = <int>{for (final r in reminders) r.at.day};
      expect(perDay.length, reminders.length); // one per day
    });
  });

  group('buildNotificationPlan — general properties', () {
    test('plan is sorted by time', () {
      final plan = _plan(
        matrix: const NotificationMatrix(
          jamaatReminder: true,
          muhasabaEveningReminder: true,
        ),
        jamaat: const JamaatConfig({
          Prayer.dhuhr: OffsetJamaat(Duration(minutes: 20)),
        }),
      );
      for (var i = 1; i < plan.length; i++) {
        expect(plan[i].at.isBefore(plan[i - 1].at), isFalse);
      }
    });

    test('ids are unique within a plan', () {
      final plan = _plan(
        matrix: const NotificationMatrix(
          jamaatReminder: true,
          muhasabaEveningReminder: true,
        ),
        jamaat: const JamaatConfig({
          Prayer.fajr: OffsetJamaat(Duration(minutes: 20)),
        }),
      );
      final ids = plan.map((i) => i.id).toSet();
      expect(ids.length, plan.length);
    });

    test('a shorter window trims the tail', () {
      final plan = _plan(window: const Duration(hours: 12));
      expect(plan.every((i) => !i.at.isAfter(_from.add(const Duration(hours: 12)))),
          isTrue);
      expect(plan.any((i) => i.at.day == 13), isFalse);
    });
  });

  group('buildNotificationPlan — cap & keep-alive', () {
    test('maxItems keeps the earliest items chronologically', () {
      final full = _plan();
      final capped = _plan(maxItems: 5);
      expect(capped, full.take(5).toList());
    });

    test('maxItems larger than the plan changes nothing', () {
      expect(_plan(maxItems: 1000), _plan());
    });

    test('keep-alive is the final item, a minute after the last reminder',
        () {
      final full = _plan();
      final plan = _plan(keepAlive: true);
      expect(plan.length, full.length + 1);
      expect(plan.last.kind, NotificationKind.keepAlive);
      expect(plan.last.at, full.last.at.add(const Duration(minutes: 1)));
      expect(plan.last.prayer, isNull);
    });

    test('keep-alive counts toward the cap and follows the trimmed tail', () {
      final full = _plan();
      final plan = _plan(maxItems: 5, keepAlive: true);
      expect(plan.length, 5);
      expect(plan.take(4).toList(), full.take(4).toList());
      expect(plan.last.kind, NotificationKind.keepAlive);
      expect(plan.last.at, full[3].at.add(const Duration(minutes: 1)));
    });

    test('no keep-alive when nothing is planned', () {
      final allOff = NotificationMatrix(
        prayerModes: {for (final p in Prayer.values) p: AzanMode.off},
        sahriAlert: false,
        iftarAlert: false,
      );
      expect(_plan(matrix: allOff, keepAlive: true), isEmpty);
    });
  });
}
