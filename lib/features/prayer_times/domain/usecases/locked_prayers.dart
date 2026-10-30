import '../../../settings/domain/entities/prayer_params.dart';
import '../entities/prayer_day.dart';

/// Prayers of [date]'s prayer day whose waqt hasn't begun at [now], so they
/// can't be marked prayed ahead of time. Yesterday is checked too (its isha
/// can start after midnight); older days lock nothing, so back-filling stays
/// open. [dayOn] computes a prayer day; null (no location, failure) locks
/// nothing.
Set<Prayer> lockedPrayersOn({
  required DateTime date,
  required DateTime now,
  required PrayerDay? Function(DateTime date) dayOn,
}) {
  final d = DateTime(date.year, date.month, date.day);
  if (d.isBefore(DateTime(now.year, now.month, now.day - 1))) {
    return const {};
  }
  final day = dayOn(d);
  if (day == null) {
    return const {};
  }
  return {
    for (final prayer in Prayer.values)
      if (now.isBefore(day.startOf(prayer))) prayer,
  };
}
