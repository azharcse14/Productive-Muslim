import '../../../settings/domain/entities/prayer_params.dart';

/// The waqt the clock is currently inside.
final class ActiveWaqt {
  const ActiveWaqt(this.prayer, this.start, this.end);

  final Prayer prayer;
  final DateTime start;
  final DateTime end;

  @override
  bool operator ==(Object other) =>
      other is ActiveWaqt &&
      other.prayer == prayer &&
      other.start == start &&
      other.end == end;

  @override
  int get hashCode => Object.hash(prayer, start, end);
}

/// One civil day of prayer times, all in the LOCATION's wall clock
/// (guide §5). Sahri end = Fajr start minus [sahriSafety]; Iftar = Maghrib.
final class PrayerDay {
  const PrayerDay({
    required this.fajr,
    required this.sunrise,
    required this.dhuhr,
    required this.asr,
    required this.maghrib,
    required this.isha,
    required this.fajrTomorrow,
    required this.ishaYesterday,
    this.sahriSafety = Duration.zero,
  });

  final DateTime fajr;
  final DateTime sunrise;
  final DateTime dhuhr;
  final DateTime asr;
  final DateTime maghrib;
  final DateTime isha;

  /// Isha's end (and tomorrow's sahri anchor).
  final DateTime fajrTomorrow;

  /// Start of the overnight isha waqt that may still be running pre-fajr.
  final DateTime ishaYesterday;

  /// Ihtiyat margin before Fajr (the user's sahri safety setting).
  final Duration sahriSafety;

  DateTime get sahriEnd => fajr.subtract(sahriSafety);
  DateTime get iftar => maghrib;

  DateTime startOf(Prayer prayer) => switch (prayer) {
        Prayer.fajr => fajr,
        Prayer.dhuhr => dhuhr,
        Prayer.asr => asr,
        Prayer.maghrib => maghrib,
        Prayer.isha => isha,
      };

  /// A waqt ends where the next begins; Fajr ends at sunrise and Isha at
  /// tomorrow's Fajr.
  DateTime endOf(Prayer prayer) => switch (prayer) {
        Prayer.fajr => sunrise,
        Prayer.dhuhr => asr,
        Prayer.asr => maghrib,
        Prayer.maghrib => isha,
        Prayer.isha => fajrTomorrow,
      };

  /// The waqt containing [now], or null in the sunrise→dhuhr gap.
  /// Pre-fajr, the overnight isha waqt is still active.
  ActiveWaqt? activeWaqtAt(DateTime now) {
    if (now.isBefore(fajr)) {
      return ActiveWaqt(Prayer.isha, ishaYesterday, fajr);
    }
    if (now.isBefore(sunrise)) {
      return ActiveWaqt(Prayer.fajr, fajr, sunrise);
    }
    if (now.isBefore(dhuhr)) {
      return null; // forbidden window — next waqt is dhuhr
    }
    if (now.isBefore(asr)) {
      return ActiveWaqt(Prayer.dhuhr, dhuhr, asr);
    }
    if (now.isBefore(maghrib)) {
      return ActiveWaqt(Prayer.asr, asr, maghrib);
    }
    if (now.isBefore(isha)) {
      return ActiveWaqt(Prayer.maghrib, maghrib, isha);
    }
    return ActiveWaqt(Prayer.isha, isha, fajrTomorrow);
  }
}
