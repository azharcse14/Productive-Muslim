import 'city.dart';

/// Where prayer times are computed for. Two modes (design §4.2/§12):
/// device GPS, or a manually chosen city from the bundled DB.
sealed class LocationConfig {
  const LocationConfig();

  double get latitude;
  double get longitude;

  /// Display name for the Home header.
  String get displayName;
}

/// Device location. Wall-clock times may use the device's local zone
/// (`toLocal()`), per guide §5.
final class GpsLocation extends LocationConfig {
  const GpsLocation({
    required this.latitude,
    required this.longitude,
    this.resolvedName = '',
  });

  @override
  final double latitude;
  @override
  final double longitude;

  /// Reverse-geocoded label, may be empty if unresolved.
  final String resolvedName;

  @override
  String get displayName => resolvedName;

  @override
  bool operator ==(Object other) =>
      other is GpsLocation &&
      other.latitude == latitude &&
      other.longitude == longitude &&
      other.resolvedName == resolvedName;

  @override
  int get hashCode => Object.hash(latitude, longitude, resolvedName);
}

/// Manually selected city. Times MUST be converted through the city's
/// IANA timezone — never the device zone (guide §5).
final class ManualCityLocation extends LocationConfig {
  const ManualCityLocation(this.city);

  final City city;

  @override
  double get latitude => city.latitude;
  @override
  double get longitude => city.longitude;
  @override
  String get displayName => '${city.name}, ${city.countryCode}';

  @override
  bool operator ==(Object other) =>
      other is ManualCityLocation && other.city == city;

  @override
  int get hashCode => city.hashCode;
}
