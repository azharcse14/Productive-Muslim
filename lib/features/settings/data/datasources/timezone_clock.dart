import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../../domain/entities/location_config.dart';
import '../../domain/repositories/zoned_clock.dart';

/// timezone-package implementation of [ZonedClock] (guide §5):
/// GPS → device local; manual city → the city's IANA zone.
final class TimezoneClock implements ZonedClock {
  /// Idempotent; call once from the composition root.
  static void initialize() => tzdata.initializeTimeZones();

  @override
  DateTime nowAt(LocationConfig location) =>
      instantAt(location, DateTime.now().toUtc());

  @override
  DateTime instantAt(LocationConfig location, DateTime instant) {
    final utc = instant.isUtc ? instant : instant.toUtc();
    return switch (location) {
      GpsLocation() => utc.toLocal(),
      ManualCityLocation(:final city) => _toZone(utc, city.timezone),
    };
  }

  DateTime _toZone(DateTime utc, String ianaId) {
    final zoned = tz.TZDateTime.from(utc, tz.getLocation(ianaId));
    // Re-wrap as a plain DateTime carrying the wall-clock values, so
    // domain code never depends on the timezone package's types.
    return DateTime(
      zoned.year,
      zoned.month,
      zoned.day,
      zoned.hour,
      zoned.minute,
      zoned.second,
      zoned.millisecond,
    );
  }
}
