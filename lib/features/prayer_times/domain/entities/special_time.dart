/// A special daily time window surfaced on the home screen: either a
/// forbidden (makruh taḥrīmī) window in which all salah is prohibited, or
/// a recommended nafl window.
enum SpecialKind { forbidden, nafl }

/// The named special windows. Order is presentation order within a kind.
enum SpecialTime {
  /// Just after sunrise until the sun has fully risen.
  forbiddenSunrise,

  /// The sun at its zenith (istiwa) until it passes the meridian (Dhuhr).
  forbiddenZawal,

  /// The sun yellowing before sunset until Maghrib.
  forbiddenSunset,

  /// Ishraq — two rak'ahs shortly after sunrise.
  ishraq,

  /// Duha (Chasht) — the forenoon prayer, mid-morning until before zawal.
  duha,

  /// Salat al-Zawal — right after the sun declines past its zenith,
  /// just before the Dhuhr fard.
  salatZawal,

  /// Awwabin — voluntary salah after Maghrib until Isha.
  awwabin,

  /// Tahajjud — the last third of the night until Fajr.
  tahajjud,
}

/// A named time window with concrete wall-clock bounds, in the location's
/// local time (matching [PrayerDay]).
final class SpecialWindow {
  const SpecialWindow({
    required this.time,
    required this.kind,
    required this.start,
    required this.end,
  });

  final SpecialTime time;
  final SpecialKind kind;
  final DateTime start;
  final DateTime end;

  /// Whether [now] falls inside this window (start inclusive, end exclusive).
  bool containsAt(DateTime now) => !now.isBefore(start) && now.isBefore(end);

  @override
  bool operator ==(Object other) =>
      other is SpecialWindow &&
      other.time == time &&
      other.kind == kind &&
      other.start == start &&
      other.end == end;

  @override
  int get hashCode => Object.hash(time, kind, start, end);
}
