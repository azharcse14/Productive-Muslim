import 'package:flutter_test/flutter_test.dart';
import 'package:productive_muslim/features/prayer_times/domain/entities/prayer_day.dart';
import 'package:productive_muslim/features/prayer_times/domain/entities/special_time.dart';
import 'package:productive_muslim/features/prayer_times/domain/usecases/resolve_special_times.dart';

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

SpecialWindow _window(SpecialTime t) =>
    resolveSpecialWindows(_day).firstWhere((w) => w.time == t);

void main() {
  group('resolveSpecialWindows — shape', () {
    final windows = resolveSpecialWindows(_day);

    test('returns all eight windows once each', () {
      expect(windows.map((w) => w.time).toSet(), SpecialTime.values.toSet());
      expect(windows, hasLength(8));
    });

    test('forbidden group first (3), then nafl (5)', () {
      expect(windows.map((w) => w.kind).toList(), [
        SpecialKind.forbidden,
        SpecialKind.forbidden,
        SpecialKind.forbidden,
        SpecialKind.nafl,
        SpecialKind.nafl,
        SpecialKind.nafl,
        SpecialKind.nafl,
        SpecialKind.nafl,
      ]);
    });

    test('every window has start strictly before end', () {
      for (final w in windows) {
        expect(w.start.isBefore(w.end), isTrue, reason: '${w.time}');
      }
    });
  });

  group('resolveSpecialWindows — forbidden bounds', () {
    test('sunrise window: sunrise → sunrise + 15min', () {
      final w = _window(SpecialTime.forbiddenSunrise);
      expect(w.start, _day.sunrise);
      expect(w.end, _day.sunrise.add(const Duration(minutes: 15)));
    });

    test('zawal window: dhuhr - 6min → dhuhr', () {
      final w = _window(SpecialTime.forbiddenZawal);
      expect(w.start, _day.dhuhr.subtract(const Duration(minutes: 6)));
      expect(w.end, _day.dhuhr);
    });

    test('sunset window: maghrib - 15min → maghrib', () {
      final w = _window(SpecialTime.forbiddenSunset);
      expect(w.start, _day.maghrib.subtract(const Duration(minutes: 15)));
      expect(w.end, _day.maghrib);
    });

    test('uses the sun, not a method-offset sunrise / maghrib', () {
      // e.g. Türkiye: sunrise −7, maghrib +7 around the astronomical times.
      final day = PrayerDay(
        ishaYesterday: _day.ishaYesterday,
        fajr: _day.fajr,
        sunrise: DateTime(2026, 6, 12, 5, 3),
        trueSunrise: DateTime(2026, 6, 12, 5, 10),
        dhuhr: _day.dhuhr,
        asr: _day.asr,
        maghrib: DateTime(2026, 6, 12, 18, 52),
        sunset: DateTime(2026, 6, 12, 18, 45),
        isha: _day.isha,
        fajrTomorrow: _day.fajrTomorrow,
      );
      SpecialWindow w(SpecialTime t) =>
          resolveSpecialWindows(day).firstWhere((w) => w.time == t);
      expect(w(SpecialTime.forbiddenSunrise).end, DateTime(2026, 6, 12, 5, 25));
      expect(
        w(SpecialTime.forbiddenSunset).start,
        DateTime(2026, 6, 12, 18, 30),
      );
      expect(w(SpecialTime.forbiddenSunset).end, DateTime(2026, 6, 12, 18, 45));
    });
  });

  group('resolveSpecialWindows — nafl bounds', () {
    test('ishraq: sunrise+15min → +30min more (sunrise+45min)', () {
      final w = _window(SpecialTime.ishraq);
      expect(w.start, _day.sunrise.add(const Duration(minutes: 15)));
      expect(w.end, _day.sunrise.add(const Duration(minutes: 45)));
    });

    test('duha: end of ishraq → start of zawal', () {
      final w = _window(SpecialTime.duha);
      expect(w.start, _day.sunrise.add(const Duration(minutes: 45)));
      expect(w.end, _day.dhuhr.subtract(const Duration(minutes: 6)));
    });

    test('salatZawal: dhuhr → dhuhr + 15min (after the forbidden zawal)', () {
      final w = _window(SpecialTime.salatZawal);
      expect(w.start, _day.dhuhr);
      expect(w.end, _day.dhuhr.add(const Duration(minutes: 15)));
    });

    test('awwabin: maghrib → isha', () {
      final w = _window(SpecialTime.awwabin);
      expect(w.start, _day.maghrib);
      expect(w.end, _day.isha);
    });

    test('tahajjud: last third of night → next fajr', () {
      final w = _window(SpecialTime.tahajjud);
      final night = _day.fajrTomorrow.difference(_day.maghrib);
      expect(w.start, _day.maghrib.add(night * (2 / 3)));
      expect(w.end, _day.fajrTomorrow);
    });
  });

  group('SpecialWindow.containsAt', () {
    test('start inclusive, end exclusive', () {
      final w = _window(SpecialTime.forbiddenZawal);
      expect(w.containsAt(w.start), isTrue);
      expect(w.containsAt(w.end), isFalse);
      expect(w.containsAt(w.start.add(const Duration(minutes: 1))), isTrue);
      expect(
        w.containsAt(w.start.subtract(const Duration(minutes: 1))),
        isFalse,
      );
    });
  });

  test("pre-fajr tahajjud is the last third of last night", () {
    final day = PrayerDay(
      maghribYesterday: DateTime(2026, 6, 11, 18, 45),
      ishaYesterday: _day.ishaYesterday,
      fajr: _day.fajr,
      sunrise: _day.sunrise,
      dhuhr: _day.dhuhr,
      asr: _day.asr,
      maghrib: _day.maghrib,
      isha: _day.isha,
      fajrTomorrow: _day.fajrTomorrow,
    );
    final w = resolveSpecialWindows(
      day,
      preFajr: true,
    ).firstWhere((w) => w.time == SpecialTime.tahajjud);
    // 18:45 → 03:45 is 9h; the last third starts at 00:45.
    expect(w.start, DateTime(2026, 6, 12, 0, 45));
    expect(w.end, day.fajr);
  });
}
