import '../../../../core/utils/result.dart';
import '../entities/location_config.dart';

/// Device-location failures. Every one of these has a designed fallback
/// path to the manual city picker — never a dead end (design brief §3).
sealed class LocationFailure extends Failure {
  const LocationFailure(super.message);
}

final class LocationServiceDisabled extends LocationFailure {
  const LocationServiceDisabled() : super('Location services are off');
}

final class LocationPermissionDenied extends LocationFailure {
  const LocationPermissionDenied() : super('Location permission denied');
}

/// "Don't ask again" — OS dialog can no longer be shown; route the user
/// to app settings or the manual picker.
final class LocationPermissionDeniedForever extends LocationFailure {
  const LocationPermissionDeniedForever()
    : super('Location permission permanently denied');
}

final class LocationUnavailable extends LocationFailure {
  const LocationUnavailable() : super('Could not determine location');
}

/// Device GPS access.
abstract interface class LocationRepository {
  /// Requests permission if needed (unless [requestPermission] is false —
  /// background refreshes must never prompt), then resolves the current
  /// position.
  Future<Result<GpsLocation>> getCurrentLocation({
    bool requestPermission = true,
  });

  /// Opens the system page that fixes a GPS failure: location services
  /// when they're off, otherwise this app's permission page.
  Future<void> openSettings({required bool locationService});
}
