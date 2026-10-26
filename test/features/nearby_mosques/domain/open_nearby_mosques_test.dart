import 'package:flutter_test/flutter_test.dart';
import 'package:productive_muslim/core/utils/result.dart';
import 'package:productive_muslim/features/nearby_mosques/domain/external_launcher.dart';
import 'package:productive_muslim/features/nearby_mosques/domain/usecases/open_nearby_mosques.dart';
import 'package:productive_muslim/features/settings/domain/entities/location_config.dart';
import 'package:productive_muslim/features/settings/domain/repositories/location_repository.dart';
import 'package:productive_muslim/features/settings/domain/usecases/get_current_location.dart';

final class _FakeLauncher implements ExternalLauncher {
  _FakeLauncher({this.result = true});

  final bool result;
  Uri? launched;

  @override
  Future<bool> launch(Uri uri) async {
    launched = uri;
    return result;
  }
}

final class _FakeLocationRepository implements LocationRepository {
  _FakeLocationRepository(this._result);

  final Result<GpsLocation> _result;
  bool called = false;

  @override
  Future<void> openSettings({required bool locationService}) async {}

  @override
  Future<Result<GpsLocation>> getCurrentLocation() async {
    called = true;
    return _result;
  }
}

void main() {
  group('OpenNearbyMosques', () {
    test('reuses the saved location and never asks for a GPS fix', () async {
      final repo = _FakeLocationRepository(
        const Result.failure(LocationUnavailable()),
      );
      final launcher = _FakeLauncher();
      final usecase = OpenNearbyMosques(
        currentLocation: () =>
            const GpsLocation(latitude: 23.78, longitude: 90.41),
        getCurrentLocation: GetCurrentLocation(repo),
        launcher: launcher,
      );

      final result = await usecase();

      expect(result.isSuccess, isTrue);
      expect(repo.called, isFalse, reason: 'saved location short-circuits GPS');
      expect(launcher.launched.toString(), contains('@23.78,90.41'));
    });

    test('falls back to a live GPS fix when no location is saved', () async {
      final repo = _FakeLocationRepository(
        const Result.success(GpsLocation(latitude: 21.42, longitude: 39.82)),
      );
      final launcher = _FakeLauncher();
      final usecase = OpenNearbyMosques(
        currentLocation: () => null,
        getCurrentLocation: GetCurrentLocation(repo),
        launcher: launcher,
      );

      final result = await usecase();

      expect(result.isSuccess, isTrue);
      expect(repo.called, isTrue);
      expect(launcher.launched.toString(), contains('@21.42,39.82'));
    });

    test('propagates the location failure when GPS cannot resolve', () async {
      final repo = _FakeLocationRepository(
        const Result.failure(LocationPermissionDenied()),
      );
      final launcher = _FakeLauncher();
      final usecase = OpenNearbyMosques(
        currentLocation: () => null,
        getCurrentLocation: GetCurrentLocation(repo),
        launcher: launcher,
      );

      final result = await usecase();

      expect(
        result.fold((_) => null, (f) => f),
        isA<LocationPermissionDenied>(),
      );
      expect(launcher.launched, isNull, reason: 'no fix → nothing launched');
    });

    test('reports MapsLaunchFailed when the launcher is rejected', () async {
      final repo = _FakeLocationRepository(
        const Result.failure(LocationUnavailable()),
      );
      final launcher = _FakeLauncher(result: false);
      final usecase = OpenNearbyMosques(
        currentLocation: () =>
            const GpsLocation(latitude: 1, longitude: 2),
        getCurrentLocation: GetCurrentLocation(repo),
        launcher: launcher,
      );

      final result = await usecase();

      expect(
        result.fold((_) => null, (f) => f),
        isA<MapsLaunchFailed>(),
      );
    });
  });
}
