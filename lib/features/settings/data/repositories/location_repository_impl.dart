import 'dart:math' as math;

import 'package:geolocator/geolocator.dart';

import '../../../../core/utils/result.dart';
import '../../domain/entities/city.dart';
import '../../domain/entities/location_config.dart';
import '../../domain/repositories/location_repository.dart';
import '../datasources/city_asset_data_source.dart';
import '../datasources/geolocator_data_source.dart';

final class LocationRepositoryImpl implements LocationRepository {
  const LocationRepositoryImpl(this._source, {CityAssetDataSource? cities})
    : _cities = cities;

  final DeviceLocationSource _source;

  /// Bundled cities, for naming a fix offline (no geocoder); without it
  /// fixes stay unnamed.
  final CityAssetDataSource? _cities;

  @override
  Future<void> openSettings({required bool locationService}) async {
    if (locationService) {
      await Geolocator.openLocationSettings();
    } else {
      await Geolocator.openAppSettings();
    }
  }

  @override
  Future<Result<GpsLocation>> getCurrentLocation({
    bool requestPermission = true,
  }) async {
    try {
      if (!await _source.isServiceEnabled()) {
        return const Result.failure(LocationServiceDisabled());
      }
      var permission = await _source.checkPermission();
      if (permission == LocationPermission.denied && requestPermission) {
        permission = await _source.requestPermission();
      }
      switch (permission) {
        case LocationPermission.denied:
          return const Result.failure(LocationPermissionDenied());
        case LocationPermission.deniedForever:
          return const Result.failure(LocationPermissionDeniedForever());
        case LocationPermission.whileInUse:
        case LocationPermission.always:
        case LocationPermission.unableToDetermine:
          break;
      }
      final position = await _source.currentPosition();
      return Result.success(
        GpsLocation(
          latitude: position.latitude,
          longitude: position.longitude,
          resolvedName: await _nameOf(position.latitude, position.longitude),
        ),
      );
    } on Object {
      return const Result.failure(LocationUnavailable());
    }
  }

  /// "City, CC" of the nearest bundled city (the format `countryCodeOf`
  /// reads), or '' when none is within [maxKm] or the list won't load.
  Future<String> _nameOf(double lat, double lng, {double maxKm = 50}) async {
    final List<City> cities;
    try {
      cities = await _cities?.loadAll() ?? const [];
    } on Object {
      return '';
    }
    City? best;
    var bestKm = maxKm;
    for (final city in cities) {
      final km = _km(lat, lng, city.latitude, city.longitude);
      if (km <= bestKm) {
        best = city;
        bestKm = km;
      }
    }
    return best == null ? '' : '${best.name}, ${best.countryCode}';
  }

  // ponytail: equirectangular, like GetCurrentLocation — fine within the
  // 50 km radius (ignores the antimeridian); linear scan, once per fix.
  static double _km(double lat1, double lng1, double lat2, double lng2) {
    const rad = math.pi / 180;
    final x = (lng2 - lng1) * rad * math.cos((lat1 + lat2) / 2 * rad);
    final y = (lat2 - lat1) * rad;
    return 6371 * math.sqrt(x * x + y * y);
  }
}
