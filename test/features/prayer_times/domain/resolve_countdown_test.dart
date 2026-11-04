import 'package:flutter_test/flutter_test.dart';
import 'package:productive_muslim/features/my_mosque/domain/entities/jamaat_config.dart';
import 'package:productive_muslim/features/prayer_times/domain/entities/countdown_target.dart';
import 'package:productive_muslim/features/prayer_times/domain/entities/prayer_day.dart';
import 'package:productive_muslim/features/prayer_times/domain/usecases/resolve_countdown.dart';
import 'package:productive_muslim/features/settings/domain/entities/prayer_params.dart';

// A representative day (wall clock).
final _day = PrayerDay(
  ishaYesterday: DateTime(2026, 6, 11, 20, 15),
  fajr: DateTime(2026, 6, 12, 3, 45),
  sunrise: DateTime(2026, 6, 12, 5, 10),
  dhuhr: DateTime(2026, 6, 12, 12),
  asr: DateTime(2026, 6, 12, 16, 30),
  maghrib: DateTime(2026, 6, 12, 18, 45),
  isha: DateTime(2026, 6, 12, 20, 15),
  fajrTomorrow: DateTime(2026, 6, 13, 3, 44),
);

CountdownTarget _resolve(
  DateTime now, {
  JamaatConfig jamaat = JamaatConfig.none,
  bool ramadan = false,
}) => resolveCountdownTarget(
  now: now,
  day: _day,
  jamaat: jamaat,
  ramadanMode: ramadan,
);

void main() {
  group('resolveCountdownTarget — normal days', () {
    test('pre-fajr: overnight isha waqt counts to its end (fajr)', () {
      final t = _resolve(DateTime(2026, 6, 12, 2));
      expect(t.kind, CountdownKind.waqtEnd);
      expect(t.prayer, Prayer.isha);
      expect(t.at, _day.fajr);
      expect(t.windowStart, _day.ishaYesterday);
    });

    test('inside fajr waqt without jamaat → fajr ends at sunrise', () {
      final t = _resolve(DateTime(2026, 6, 12, 4));
      expect(t.kind, CountdownKind.waqtEnd);
      expect(t.prayer, Prayer.fajr);
      expect(t.at, _day.sunrise);
    });

    test('sunrise→dhuhr gap targets dhuhr start', () {
      final t = _resolve(DateTime(2026, 6, 12, 9));
      expect(t.kind, CountdownKind.waqtStart);
      expect(t.prayer, Prayer.dhuhr);
      expect(t.at, _day.dhuhr);
      expect(t.windowStart, _day.sunrise);
    });

    test('future jamaat (offset) takes precedence over waqt end', () {
      const jamaat = JamaatConfig({
        Prayer.fajr: OffsetJamaat(Duration(minutes: 30)),
      });
      final t = _resolve(DateTime(2026, 6, 12, 4), jamaat: jamaat);
      expect(t.kind, CountdownKind.jamaat);
      expect(t.at, DateTime(2026, 6, 12, 4, 15));
      expect(t.windowStart, _day.fajr);
    });

    test('passed jamaat falls back to waqt end', () {
      const jamaat = JamaatConfig({
        Prayer.fajr: OffsetJamaat(Duration(minutes: 30)),
      });
      final t = _resolve(DateTime(2026, 6, 12, 4, 30), jamaat: jamaat);
      expect(t.kind, CountdownKind.waqtEnd);
      expect(t.at, _day.sunrise);
    });

    test('fixed jamaat resolves on the waqt-start date', () {
      const jamaat = JamaatConfig({
        Prayer.dhuhr: FixedJamaat(ClockTime(13, 15)),
      });
      final t = _resolve(DateTime(2026, 6, 12, 12, 30), jamaat: jamaat);
      expect(t.kind, CountdownKind.jamaat);
      expect(t.at, DateTime(2026, 6, 12, 13, 15));
    });

    test('NoJamaat entry behaves like unconfigured', () {
      const jamaat = JamaatConfig({Prayer.dhuhr: NoJamaat()});
      final t = _resolve(DateTime(2026, 6, 12, 12, 30), jamaat: jamaat);
      expect(t.kind, CountdownKind.waqtEnd);
    });

    test('isha waqt rolls over midnight to tomorrow\'s fajr', () {
      final t = _resolve(DateTime(2026, 6, 12, 23, 50));
      expect(t.kind, CountdownKind.waqtEnd);
      expect(t.prayer, Prayer.isha);
      expect(t.at, _day.fajrTomorrow);
    });
  });

  group('resolveCountdownTarget — Ramadan overrides', () {
    test('sahri end honours the safety margin', () {
      final day = PrayerDay(
        ishaYesterday: _day.ishaYesterday,
        fajr: _day.fajr,
        sunrise: _day.sunrise,
        dhuhr: _day.dhuhr,
        asr: _day.asr,
        maghrib: _day.maghrib,
        isha: _day.isha,
        fajrTomorrow: _day.fajrTomorrow,
        sahriSafety: const Duration(minutes: 10),
      );
      expect(day.sahriEnd, DateTime(2026, 6, 12, 3, 35));
      CountdownTarget at(DateTime now) => resolveCountdownTarget(
        now: now,
        day: day,
        jamaat: JamaatConfig.none,
        ramadanMode: true,
      );
      final before = at(DateTime(2026, 6, 12, 3, 30));
      expect(before.kind, CountdownKind.sahriEnd);
      expect(before.at, DateTime(2026, 6, 12, 3, 35));
      // Inside the margin, sahri is over: fall back to the isha waqt end.
      final inMargin = at(DateTime(2026, 6, 12, 3, 40));
      expect(inMargin.kind, CountdownKind.waqtEnd);
      expect(inMargin.at, _day.fajr);
    });

    test('pre-fajr targets sahri end', () {
      final t = _resolve(DateTime(2026, 6, 12, 2), ramadan: true);
      expect(t.kind, CountdownKind.sahriEnd);
      expect(t.prayer, Prayer.fajr);
      expect(t.at, _day.sahriEnd);
    });

    test('asr→maghrib window targets iftar even with jamaat configured', () {
      const jamaat = JamaatConfig({
        Prayer.asr: OffsetJamaat(Duration(minutes: 20)),
      });
      final t = _resolve(
        DateTime(2026, 6, 12, 16, 35),
        jamaat: jamaat,
        ramadan: true,
      );
      expect(t.kind, CountdownKind.iftar);
      expect(t.at, _day.iftar);
      expect(t.windowStart, _day.asr);
    });

    test('exactly at asr start the iftar override applies', () {
      final t = _resolve(_day.asr, ramadan: true);
      expect(t.kind, CountdownKind.iftar);
    });

    test('after maghrib Ramadan behaves normally again', () {
      final t = _resolve(DateTime(2026, 6, 12, 19), ramadan: true);
      expect(t.kind, CountdownKind.waqtEnd);
      expect(t.prayer, Prayer.maghrib);
    });

    test('after isha, before midnight, targets tomorrow\'s sahri end', () {
      final t = _resolve(DateTime(2026, 6, 12, 22), ramadan: true);
      expect(t.kind, CountdownKind.sahriEnd);
      expect(t.prayer, Prayer.fajr);
      expect(t.at, _day.fajrTomorrow);
      expect(t.windowStart, _day.isha);
      // Exactly at isha start too.
      expect(_resolve(_day.isha, ramadan: true).kind, CountdownKind.sahriEnd);
      // Outside Ramadan it is still the isha waqt end.
      expect(_resolve(DateTime(2026, 6, 12, 22)).kind, CountdownKind.waqtEnd);
    });

    test('after isha the sahri target follows tomorrow, not today', () {
      CountdownTarget at22({required bool today, required bool tonight}) =>
          resolveCountdownTarget(
            now: DateTime(2026, 6, 12, 22),
            day: _day,
            jamaat: JamaatConfig.none,
            ramadanMode: today,
            ramadanTonight: tonight,
          );
      // Last night of Ramadan (Eid tomorrow): no sahri to count to.
      expect(at22(today: true, tonight: false).kind, CountdownKind.waqtEnd);
      // Eve of 1 Ramadan: tonight's sahri opens the first fast.
      expect(at22(today: false, tonight: true).kind, CountdownKind.sahriEnd);
    });

    test('after isha the safety margin applies to tomorrow\'s sahri', () {
      final day = PrayerDay(
        ishaYesterday: _day.ishaYesterday,
        fajr: _day.fajr,
        sunrise: _day.sunrise,
        dhuhr: _day.dhuhr,
        asr: _day.asr,
        maghrib: _day.maghrib,
        isha: _day.isha,
        fajrTomorrow: _day.fajrTomorrow,
        sahriSafety: const Duration(minutes: 10),
      );
      final t = resolveCountdownTarget(
        now: DateTime(2026, 6, 12, 23, 59),
        day: day,
        jamaat: JamaatConfig.none,
        ramadanMode: true,
      );
      expect(t.kind, CountdownKind.sahriEnd);
      expect(t.at, DateTime(2026, 6, 13, 3, 34));
    });

    test('after isha a future isha jamaat still wins over sahri', () {
      const jamaat = JamaatConfig({
        Prayer.isha: OffsetJamaat(Duration(minutes: 15)),
      });
      final t = _resolve(
        DateTime(2026, 6, 12, 20, 20),
        jamaat: jamaat,
        ramadan: true,
      );
      expect(t.kind, CountdownKind.jamaat);
      expect(t.prayer, Prayer.isha);
      final after = _resolve(
        DateTime(2026, 6, 12, 20, 31),
        jamaat: jamaat,
        ramadan: true,
      );
      expect(after.kind, CountdownKind.sahriEnd);
    });

    test('morning (post-fajr) Ramadan is normal logic', () {
      final t = _resolve(DateTime(2026, 6, 12, 4), ramadan: true);
      expect(t.kind, CountdownKind.waqtEnd);
      expect(t.prayer, Prayer.fajr);
    });
  });

  group('countdownUrgencyFor', () {
    CountdownUrgency urgency(
      CountdownKind kind,
      Duration remaining, {
      bool prayed = false,
      bool forbidden = false,
    }) {
      final now = DateTime(2026, 6, 12, 12);
      return countdownUrgencyFor(
        now: now,
        prayed: prayed,
        forbidden: forbidden,
        target: CountdownTarget(
          kind: kind,
          prayer: Prayer.dhuhr,
          at: now.add(remaining),
          windowStart: now.subtract(const Duration(hours: 1)),
        ),
      );
    }

    test('jamaat ≤10 min is amber, above is calm', () {
      expect(
        urgency(CountdownKind.jamaat, const Duration(minutes: 9)),
        CountdownUrgency.amber,
      );
      expect(
        urgency(CountdownKind.jamaat, const Duration(minutes: 11)),
        CountdownUrgency.calm,
      );
    });

    test('waqt end ≤20 min is urgent, above is calm', () {
      expect(
        urgency(CountdownKind.waqtEnd, const Duration(minutes: 19)),
        CountdownUrgency.urgent,
      );
      expect(
        urgency(CountdownKind.waqtEnd, const Duration(minutes: 21)),
        CountdownUrgency.calm,
      );
    });

    test('waqt start is always calm', () {
      expect(
        urgency(CountdownKind.waqtStart, const Duration(minutes: 1)),
        CountdownUrgency.calm,
      );
    });

    test('a prayed waqt stays calm, even when ending or forbidden', () {
      expect(
        urgency(
          CountdownKind.waqtEnd,
          const Duration(minutes: 5),
          prayed: true,
          forbidden: true,
        ),
        CountdownUrgency.calm,
      );
      expect(
        urgency(CountdownKind.jamaat, const Duration(minutes: 5), prayed: true),
        CountdownUrgency.calm,
      );
    });

    test('a forbidden window is urgent; Ramadan states win', () {
      expect(
        urgency(
          CountdownKind.waqtStart,
          const Duration(hours: 3),
          forbidden: true,
        ),
        CountdownUrgency.urgent,
      );
      expect(
        urgency(
          CountdownKind.iftar,
          const Duration(minutes: 5),
          forbidden: true,
        ),
        CountdownUrgency.iftar,
      );
    });

    test('sahri and iftar carry their own states', () {
      expect(
        urgency(CountdownKind.sahriEnd, const Duration(hours: 2)),
        CountdownUrgency.sahri,
      );
      expect(
        urgency(CountdownKind.iftar, const Duration(minutes: 1)),
        CountdownUrgency.iftar,
      );
    });
  });

  group('CountdownTarget progress', () {
    test('is elapsed fraction of the window, clamped', () {
      final target = CountdownTarget(
        kind: CountdownKind.waqtEnd,
        prayer: Prayer.dhuhr,
        windowStart: DateTime(2026, 6, 12, 12),
        at: DateTime(2026, 6, 12, 14),
      );
      expect(target.progressAt(DateTime(2026, 6, 12, 13)), 0.5);
      expect(target.progressAt(DateTime(2026, 6, 12, 11)), 0);
      expect(target.progressAt(DateTime(2026, 6, 12, 15)), 1);
    });
  });

  group('PrayerDay.activeWaqtAt', () {
    test('maps every moment of the day to the right waqt', () {
      expect(_day.activeWaqtAt(DateTime(2026, 6, 12, 2))?.prayer, Prayer.isha);
      expect(_day.activeWaqtAt(DateTime(2026, 6, 12, 4))?.prayer, Prayer.fajr);
      expect(_day.activeWaqtAt(DateTime(2026, 6, 12, 9)), isNull);
      expect(
        _day.activeWaqtAt(DateTime(2026, 6, 12, 13))?.prayer,
        Prayer.dhuhr,
      );
      expect(_day.activeWaqtAt(DateTime(2026, 6, 12, 17))?.prayer, Prayer.asr);
      expect(
        _day.activeWaqtAt(DateTime(2026, 6, 12, 19))?.prayer,
        Prayer.maghrib,
      );
      expect(_day.activeWaqtAt(DateTime(2026, 6, 12, 22))?.prayer, Prayer.isha);
    });

    test('boundaries: start is inclusive, end exclusive', () {
      expect(_day.activeWaqtAt(_day.fajr)?.prayer, Prayer.fajr);
      expect(_day.activeWaqtAt(_day.sunrise), isNull);
      expect(_day.activeWaqtAt(_day.dhuhr)?.prayer, Prayer.dhuhr);
    });

    test("isha past midnight: before it, yesterday's maghrib is active", () {
      final day = PrayerDay(
        maghribYesterday: DateTime(2026, 6, 11, 21, 20),
        ishaYesterday: DateTime(2026, 6, 12, 0, 30),
        fajr: DateTime(2026, 6, 12, 2, 50),
        sunrise: _day.sunrise,
        dhuhr: _day.dhuhr,
        asr: _day.asr,
        maghrib: _day.maghrib,
        isha: _day.isha,
        fajrTomorrow: _day.fajrTomorrow,
      );
      expect(
        day.activeWaqtAt(DateTime(2026, 6, 12, 0, 10)),
        ActiveWaqt(Prayer.maghrib, day.maghribYesterday!, day.ishaYesterday),
      );
      expect(
        day.activeWaqtAt(day.ishaYesterday),
        ActiveWaqt(Prayer.isha, day.ishaYesterday, day.fajr),
      );
    });
  });

  group('sunset past midnight (Nome, 21 Jun 2026)', () {
    // Yesterday's Asr 21:21 → Maghrib 01:48; today's Fajr 03:04.
    final nome = PrayerDay(
      asrYesterday: DateTime(2026, 6, 20, 21, 21),
      maghribYesterday: DateTime(2026, 6, 21, 1, 48),
      ishaYesterday: DateTime(2026, 6, 21, 3, 4),
      fajr: DateTime(2026, 6, 21, 3, 4),
      sunrise: DateTime(2026, 6, 21, 4, 19),
      dhuhr: DateTime(2026, 6, 21, 15, 5),
      asr: DateTime(2026, 6, 21, 21, 22),
      maghrib: DateTime(2026, 6, 22, 1, 48),
      isha: DateTime(2026, 6, 22, 3, 4),
      fajrTomorrow: DateTime(2026, 6, 22, 3, 4),
    );
    final night = DateTime(2026, 6, 21, 0, 30);

    test("before yesterday's sunset, yesterday's asr is active", () {
      expect(
        nome.activeWaqtAt(night),
        ActiveWaqt(Prayer.asr, nome.asrYesterday!, nome.maghribYesterday!),
      );
      expect(nome.activeWaqtAt(nome.maghribYesterday!)?.prayer, Prayer.maghrib);
    });

    test('countdown runs to the asr waqt end (sunset)', () {
      final t = resolveCountdownTarget(
        now: night,
        day: nome,
        jamaat: JamaatConfig.none,
        ramadanMode: false,
      );
      expect(t.kind, CountdownKind.waqtEnd);
      expect(t.prayer, Prayer.asr);
      expect(t.at, nome.maghribYesterday);
    });

    test('Ramadan: iftar comes before the next sahri', () {
      final t = resolveCountdownTarget(
        now: night,
        day: nome,
        jamaat: JamaatConfig.none,
        ramadanMode: true,
      );
      expect(t.kind, CountdownKind.iftar);
      expect(t.at, nome.maghribYesterday);
      expect(t.windowStart, nome.asrYesterday);
    });
  });

  group('resolveCountdownTarget — jamaat past the waqt end', () {
    // December: Asr 13:35–15:52, a summer fixed Asr jamaat at 17:00 left on.
    final winter = PrayerDay(
      ishaYesterday: DateTime(2026, 12, 14, 17, 40),
      fajr: DateTime(2026, 12, 15, 5, 10),
      sunrise: DateTime(2026, 12, 15, 6, 30),
      dhuhr: DateTime(2026, 12, 15, 11, 55),
      asr: DateTime(2026, 12, 15, 13, 35),
      maghrib: DateTime(2026, 12, 15, 15, 52),
      isha: DateTime(2026, 12, 15, 17, 40),
      fajrTomorrow: DateTime(2026, 12, 16, 5, 11),
    );

    test('a stale fixed jamaat after the waqt ends → waqt-end countdown', () {
      const jamaat = JamaatConfig({Prayer.asr: FixedJamaat(ClockTime(17, 0))});
      final t = resolveCountdownTarget(
        now: DateTime(2026, 12, 15, 15),
        day: winter,
        jamaat: jamaat,
        ramadanMode: false,
      );
      expect(t.kind, CountdownKind.waqtEnd);
      expect(t.at, winter.maghrib);
      // So the last minutes of the waqt still go urgent.
      expect(
        countdownUrgencyFor(now: DateTime(2026, 12, 15, 15, 40), target: t),
        CountdownUrgency.urgent,
      );
    });

    test('invariant: a jamaat target always lies in [start, end)', () {
      final configs = [
        for (final time in const [
          ClockTime(0, 15),
          ClockTime(4, 0),
          ClockTime(6, 0),
          ClockTime(13, 15),
          ClockTime(14, 0),
          ClockTime(17, 0),
          ClockTime(20, 0),
          ClockTime(23, 45),
        ])
          JamaatConfig({
            for (final p in Prayer.values) p: FixedJamaat(time),
          }, time),
        for (final minutes in const [0, 10, 45, 120, 600])
          JamaatConfig({
            for (final p in Prayer.values)
              p: OffsetJamaat(Duration(minutes: minutes)),
          }),
      ];
      var jamaatTargets = 0;
      for (final day in [_day, winter]) {
        final midnight = DateTime(day.fajr.year, day.fajr.month, day.fajr.day);
        for (final config in configs) {
          for (final ramadan in const [false, true]) {
            for (var m = 0; m < 24 * 60; m += 5) {
              final now = midnight.add(Duration(minutes: m));
              final t = resolveCountdownTarget(
                now: now,
                day: day,
                jamaat: config,
                ramadanMode: ramadan,
              );
              if (t.kind != CountdownKind.jamaat) {
                continue;
              }
              jamaatTargets++;
              final active = day.activeWaqtAt(now)!;
              final reason = '$now ${t.prayer} jamaat ${t.at}';
              expect(t.prayer, active.prayer, reason: reason);
              expect(t.at.isBefore(active.start), isFalse, reason: reason);
              expect(t.at.isBefore(active.end), isTrue, reason: reason);
            }
          }
        }
      }
      expect(jamaatTargets, greaterThan(0));
    });
  });
}
