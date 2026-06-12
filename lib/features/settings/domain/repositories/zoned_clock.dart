import '../entities/location_config.dart';

/// Wall-clock authority per location (guide §5 timezone correctness):
/// device GPS → device-local time; manual city → that city's IANA zone.
abstract interface class ZonedClock {
  /// Current wall-clock time at [location].
  DateTime nowAt(LocationConfig location);

  /// Converts an absolute [instant] (UTC) to the wall clock at [location].
  DateTime instantAt(LocationConfig location, DateTime instant);

  /// Inverse of [instantAt]: the UTC instant at which the wall clock at
  /// [location] reads [wall]. Needed to schedule OS alarms at foreign-city
  /// moments.
  DateTime utcInstantOf(LocationConfig location, DateTime wall);
}
