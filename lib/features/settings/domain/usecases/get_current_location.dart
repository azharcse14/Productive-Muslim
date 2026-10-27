import 'dart:math' as math;

import '../../../../core/utils/result.dart';
import '../entities/location_config.dart';
import '../repositories/location_repository.dart';

final class GetCurrentLocation {
  const GetCurrentLocation(this._repository);

  final LocationRepository _repository;

  Future<Result<GpsLocation>> call() => _repository.getCurrentLocation();

  /// Background re-fix of a saved GPS location (app resume after travel).
  /// Never prompts for permission. Returns the new fix only when it is more
  /// than [minKm] from [saved]; GPS drift isn't worth recomputing for.
  Future<GpsLocation?> movedFrom(GpsLocation saved, {double minKm = 5}) async {
    final fix = (await _repository.getCurrentLocation(
      requestPermission: false,
    )).valueOrNull;
    return fix != null && _km(saved, fix) > minKm ? fix : null;
  }

  // ponytail: equirectangular approximation — accurate at the few-km scale
  // this threshold needs; use haversine if it ever compares long distances.
  static double _km(GpsLocation a, GpsLocation b) {
    const rad = math.pi / 180;
    final x =
        (b.longitude - a.longitude) *
        rad *
        math.cos((a.latitude + b.latitude) / 2 * rad);
    final y = (b.latitude - a.latitude) * rad;
    return 6371 * math.sqrt(x * x + y * y);
  }

  Future<void> openSettings({required bool locationService}) =>
      _repository.openSettings(locationService: locationService);
}
