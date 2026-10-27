import 'package:geolocator/geolocator.dart';

/// Seam over the geolocator plugin so the repository (and tests) never
/// touch static plugin calls directly.
abstract interface class DeviceLocationSource {
  Future<bool> isServiceEnabled();
  Future<LocationPermission> checkPermission();
  Future<LocationPermission> requestPermission();
  Future<Position> currentPosition();
}

final class GeolocatorDataSource implements DeviceLocationSource {
  const GeolocatorDataSource();

  @override
  Future<bool> isServiceEnabled() => Geolocator.isLocationServiceEnabled();

  @override
  Future<LocationPermission> checkPermission() =>
      Geolocator.checkPermission();

  @override
  Future<LocationPermission> requestPermission() =>
      Geolocator.requestPermission();

  @override
  Future<Position> currentPosition() => Geolocator.getCurrentPosition(
        // Indoors with no fix the call otherwise never completes.
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 20),
        ),
      );
}
