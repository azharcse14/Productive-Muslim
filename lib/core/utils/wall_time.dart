/// Location wall-clock times are "floating" `DateTime.utc` values: their
/// fields read the clock at the location and no zone arithmetic is ever
/// applied to them (see `ZonedClock`). Only `ZonedClock.utcInstantOf` turns
/// one into a real instant.
extension WallTime on DateTime {
  /// This calendar day + [days] at [hour]:[minute], on the same kind of
  /// clock as this (floating UTC or device-local), so the result compares
  /// correctly with this and with its siblings.
  DateTime wallDay(int days, [int hour = 0, int minute = 0]) => isUtc
      ? DateTime.utc(year, month, day + days, hour, minute)
      : DateTime(year, month, day + days, hour, minute);

  /// These fields as a floating wall time (a device-local value's fields
  /// are its wall clock; a UTC one is returned as is).
  DateTime get floating => isUtc
      ? this
      : DateTime.utc(
          year,
          month,
          day,
          hour,
          minute,
          second,
          millisecond,
          microsecond,
        );
}

/// The device clock as a floating wall time — "now" before a location is
/// set, on the same kind of clock as every location wall time.
DateTime floatingNow() => DateTime.now().floating;

/// The real instant of the location's "now" [wall]: [deviceUtc] when the
/// location clock read [wall] at it (this resolves the fall-back hour,
/// where [instantOf] can only guess which of the two readings is meant),
/// else [instantOf] of [wall] (a clock pinned in tests).
DateTime nowInstant(
  DateTime wall, {
  required DateTime deviceUtc,
  required DateTime Function(DateTime wall) instantOf,
  required DateTime Function(DateTime instant) wallOf,
}) => wallOf(deviceUtc).difference(wall).abs() < const Duration(seconds: 2)
    ? deviceUtc
    : instantOf(wall);
