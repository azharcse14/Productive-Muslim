import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../../domain/entities/location_config.dart';
import '../../domain/repositories/zoned_clock.dart';

/// timezone-package implementation of [ZonedClock] (guide §5):
/// GPS → device local; manual city → the city's IANA zone. Either way the
/// wall time comes back as a floating `DateTime.utc`, so a city time that
/// doesn't exist on the device clock (its spring-forward hour) or exists
/// twice (fall-back) survives unchanged.
final class TimezoneClock implements ZonedClock {
  /// Idempotent; call once from the composition root.
  static void initialize() => tzdata.initializeTimeZones();

  @override
  DateTime nowAt(LocationConfig location) =>
      instantAt(location, DateTime.now().toUtc());

  @override
  DateTime instantAt(LocationConfig location, DateTime instant) {
    final utc = instant.toUtc();
    final DateTime wall = switch (location) {
      GpsLocation() => utc.toLocal(),
      ManualCityLocation(:final city) => tz.TZDateTime.from(
        utc,
        tz.getLocation(city.timezone),
      ),
    };
    return DateTime.utc(
      wall.year,
      wall.month,
      wall.day,
      wall.hour,
      wall.minute,
      wall.second,
      wall.millisecond,
    );
  }

  @override
  DateTime utcInstantOf(LocationConfig location, DateTime wall) =>
      switch (location) {
        // Fields only: [wall] may be floating UTC or device-local.
        GpsLocation() => DateTime(
          wall.year,
          wall.month,
          wall.day,
          wall.hour,
          wall.minute,
          wall.second,
        ).toUtc(),
        ManualCityLocation(:final city) => tz.TZDateTime(
          tz.getLocation(city.timezone),
          wall.year,
          wall.month,
          wall.day,
          wall.hour,
          wall.minute,
          wall.second,
        ).toUtc(),
      };
}
