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
}
