import '../../prayer_times/domain/entities/prayer_day.dart';
import '../../settings/domain/entities/prayer_params.dart';

/// The next upcoming prayer relative to [now], resolved purely from a
/// [PrayerDay]. Used to feed the home-screen widget. When every waqt for
/// the civil day has already started, the next is tomorrow's Fajr
/// (`PrayerDay.fajrTomorrow`) and [tomorrow] is true.
final class NextPrayer {
  const NextPrayer({
    required this.prayer,
    required this.at,
    required this.tomorrow,
  });

  final Prayer prayer;
  final DateTime at;
  final bool tomorrow;

  @override
  bool operator ==(Object other) =>
      other is NextPrayer &&
      other.prayer == prayer &&
      other.at == at &&
      other.tomorrow == tomorrow;

  @override
  int get hashCode => Object.hash(prayer, at, tomorrow);
}

/// First prayer whose waqt starts strictly after [now]; rolls over to
/// tomorrow's Fajr once Isha has begun.
NextPrayer resolveNextPrayer(PrayerDay day, DateTime now) {
  for (final prayer in Prayer.values) {
    final start = day.startOf(prayer);
    if (start.isAfter(now)) {
      return NextPrayer(prayer: prayer, at: start, tomorrow: false);
    }
  }
  return NextPrayer(
    prayer: Prayer.fajr,
    at: day.fajrTomorrow,
    tomorrow: true,
  );
}
