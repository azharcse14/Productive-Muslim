/// A selectable world city from the bundled GeoNames-derived asset.
final class City {
  const City({
    required this.name,
    required this.countryCode,
    required this.latitude,
    required this.longitude,
    required this.timezone,
    this.nameBn,
  });

  final String name;

  /// ISO 3166-1 alpha-2, e.g. "BD".
  final String countryCode;
  final double latitude;
  final double longitude;

  /// IANA id, e.g. "Asia/Dhaka" — REQUIRED for correct wall-clock times
  /// of manually selected cities (guide §5).
  final String timezone;

  /// Bengali name for BD places, used for search and as a subtitle.
  /// Not persisted and not part of equality, so saved cities still match.
  final String? nameBn;

  @override
  bool operator ==(Object other) =>
      other is City &&
      other.name == name &&
      other.countryCode == countryCode &&
      other.latitude == latitude &&
      other.longitude == longitude &&
      other.timezone == timezone;

  @override
  int get hashCode =>
      Object.hash(name, countryCode, latitude, longitude, timezone);

  @override
  String toString() => 'City($name, $countryCode)';
}
