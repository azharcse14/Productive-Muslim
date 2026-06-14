import '../../../../core/utils/result.dart';
import '../../../settings/domain/entities/location_config.dart';
import '../../../settings/domain/usecases/get_current_location.dart';
import '../external_launcher.dart';
import '../nearby_mosques_url.dart';

/// The external maps app/browser refused to open (no handler installed, or
/// the platform rejected the intent). Location is fine — only the launch
/// failed, so the user can be nudged to install/enable a maps app.
final class MapsLaunchFailed extends Failure {
  const MapsLaunchFailed() : super('Could not open the maps app');
}

/// Opens Google Maps centred on the user's position, searching for nearby
/// mosques.
///
/// Location is resolved cheaply first: if the user already has a chosen
/// location (manual city or a prior GPS fix) we reuse its coordinates and
/// never re-prompt. Only when nothing is set do we ask the device for a live
/// fix — surfacing the same typed [LocationFailure]s as the rest of the app
/// so the caller can route to the picker.
final class OpenNearbyMosques {
  const OpenNearbyMosques({
    required LocationConfig? Function() currentLocation,
    required GetCurrentLocation getCurrentLocation,
    required ExternalLauncher launcher,
  })  : _currentLocation = currentLocation,
        _getCurrentLocation = getCurrentLocation,
        _launcher = launcher;

  final LocationConfig? Function() _currentLocation;
  final GetCurrentLocation _getCurrentLocation;
  final ExternalLauncher _launcher;

  Future<Result<void>> call() async {
    final saved = _currentLocation();
    final double latitude;
    final double longitude;
    if (saved != null) {
      latitude = saved.latitude;
      longitude = saved.longitude;
    } else {
      final fix = await _getCurrentLocation();
      switch (fix) {
        case Success(:final value):
          latitude = value.latitude;
          longitude = value.longitude;
        case FailureResult(:final failure):
          return Result.failure(failure);
      }
    }

    final uri = NearbyMosquesUrl.build(
      latitude: latitude,
      longitude: longitude,
    );
    final opened = await _launcher.launch(uri);
    return opened
        ? const Result.success(null)
        : const Result.failure(MapsLaunchFailed());
  }
}
