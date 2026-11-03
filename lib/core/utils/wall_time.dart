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
}
