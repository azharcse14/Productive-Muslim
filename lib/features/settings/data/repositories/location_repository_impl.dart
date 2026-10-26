import 'package:geolocator/geolocator.dart';

import '../../../../core/utils/result.dart';
import '../../domain/entities/location_config.dart';
import '../../domain/repositories/location_repository.dart';
import '../datasources/geolocator_data_source.dart';

final class LocationRepositoryImpl implements LocationRepository {
  const LocationRepositoryImpl(this._source);

  final DeviceLocationSource _source;

  @override
  Future<void> openSettings({required bool locationService}) async {
    if (locationService) {
      await Geolocator.openLocationSettings();
    } else {
      await Geolocator.openAppSettings();
    }
  }

  @override
  Future<Result<GpsLocation>> getCurrentLocation() async {
    try {
      if (!await _source.isServiceEnabled()) {
        return const Result.failure(LocationServiceDisabled());
      }
      var permission = await _source.checkPermission();
      if (permission == LocationPermission.denied) {
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
        ),
      );
    } on Object {
      return const Result.failure(LocationUnavailable());
    }
  }
}
