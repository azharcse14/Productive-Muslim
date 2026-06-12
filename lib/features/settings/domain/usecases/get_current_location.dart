import '../../../../core/utils/result.dart';
import '../entities/location_config.dart';
import '../repositories/location_repository.dart';

final class GetCurrentLocation {
  const GetCurrentLocation(this._repository);

  final LocationRepository _repository;

  Future<Result<GpsLocation>> call() => _repository.getCurrentLocation();
}
