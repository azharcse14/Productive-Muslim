import '../entities/prayer_day.dart';
import '../entities/special_time.dart';

/// How long the sun's edge takes to clear the horizon at sunrise / before
/// sunset — the makruh windows around them (~the height of a spear).
const _horizonWindow = Duration(minutes: 15);

/// The zawal (istiwa) window just before the sun passes the meridian.
const _zawalWindow = Duration(minutes: 6);

/// How long the brief Ishraq window lasts before Duha (Chasht) begins.
const _ishraqWindow = Duration(minutes: 30);

/// The Salat al-Zawal window right after the sun declines into Dhuhr.
const _salatZawalWindow = Duration(minutes: 15);

/// The three forbidden (makruh taḥrīmī) windows and the nafl windows for
/// [day], derived purely from its sun/prayer times. A pure function with
/// exhaustive tests (guide §5). Ordered for top-to-bottom display:
/// forbidden first, then nafl. [preFajr]: the clock is before today's
/// Fajr, so Tahajjud is the night still running (yesterday's Maghrib →
/// Fajr), not tonight's.
List<SpecialWindow> resolveSpecialWindows(
  PrayerDay day, {
  bool preFajr = false,
}) {
  final sunriseEnd = day.sunrise.add(_horizonWindow);
  final ishraqEnd = sunriseEnd.add(_ishraqWindow);
  final zawalStart = day.dhuhr.subtract(_zawalWindow);
  final sunsetStart = day.maghrib.subtract(_horizonWindow);

  // Tahajjud: the last third of the night, sunset (Maghrib) → next Fajr.
  final (nightStart, nightEnd) = switch (day.maghribYesterday) {
    final m? when preFajr => (m, day.fajr),
    _ => (day.maghrib, day.fajrTomorrow),
  };
  final night = nightEnd.difference(nightStart);
  final tahajjudStart = nightStart.add(night * (2 / 3));

  return [
    SpecialWindow(
      time: SpecialTime.forbiddenSunrise,
      kind: SpecialKind.forbidden,
      start: day.sunrise,
      end: sunriseEnd,
    ),
    SpecialWindow(
      time: SpecialTime.forbiddenZawal,
      kind: SpecialKind.forbidden,
      start: zawalStart,
      end: day.dhuhr,
    ),
    SpecialWindow(
      time: SpecialTime.forbiddenSunset,
      kind: SpecialKind.forbidden,
      start: sunsetStart,
      end: day.maghrib,
    ),
    SpecialWindow(
      time: SpecialTime.ishraq,
      kind: SpecialKind.nafl,
      start: sunriseEnd,
      end: ishraqEnd,
    ),
    SpecialWindow(
      time: SpecialTime.duha,
      kind: SpecialKind.nafl,
      start: ishraqEnd,
      end: zawalStart,
    ),
    SpecialWindow(
      time: SpecialTime.salatZawal,
      kind: SpecialKind.nafl,
      start: day.dhuhr,
      end: day.dhuhr.add(_salatZawalWindow),
    ),
    SpecialWindow(
      time: SpecialTime.awwabin,
      kind: SpecialKind.nafl,
      start: day.maghrib,
      end: day.isha,
    ),
    SpecialWindow(
      time: SpecialTime.tahajjud,
      kind: SpecialKind.nafl,
      start: tahajjudStart,
      end: nightEnd,
    ),
  ];
}
