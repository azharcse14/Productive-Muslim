import 'package:flutter_test/flutter_test.dart';
import 'package:productive_muslim/core/utils/result.dart';
import 'package:productive_muslim/features/settings/domain/entities/location_config.dart';
import 'package:productive_muslim/features/settings/domain/repositories/location_repository.dart';
import 'package:productive_muslim/features/settings/domain/usecases/get_current_location.dart';

final class _Repo implements LocationRepository {
  _Repo(this.result);

  final Result<GpsLocation> result;
  bool? prompted;

  @override
  Future<void> openSettings({required bool locationService}) async {}

  @override
  Future<Result<GpsLocation>> getCurrentLocation({
    bool requestPermission = true,
  }) async {
    prompted = requestPermission;
    return result;
  }
}

void main() {
  const dhaka = GpsLocation(latitude: 23.7104, longitude: 90.4074);

  group('GetCurrentLocation.movedFrom', () {
    test('returns a fix that moved > 5 km, without prompting', () async {
      // Dhaka → Chattogram (~215 km).
      const ctg = GpsLocation(latitude: 22.3569, longitude: 91.7832);
      final repo = _Repo(const Result.success(ctg));
      expect(await GetCurrentLocation(repo).movedFrom(dhaka), ctg);
      expect(repo.prompted, isFalse);
    });

    test('ignores drift under the threshold', () async {
      // ~1 km north.
      const near = GpsLocation(latitude: 23.7194, longitude: 90.4074);
      final repo = _Repo(const Result.success(near));
      expect(await GetCurrentLocation(repo).movedFrom(dhaka), isNull);
    });

    test(
      'a failed fix (e.g. permission not granted) changes nothing',
      () async {
        final repo = _Repo(const Result.failure(LocationPermissionDenied()));
        expect(await GetCurrentLocation(repo).movedFrom(dhaka), isNull);
      },
    );
  });
}
