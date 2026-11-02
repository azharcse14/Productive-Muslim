import 'package:flutter_test/flutter_test.dart';
import 'package:productive_muslim/core/utils/result.dart';
import 'package:productive_muslim/features/nearby_mosques/domain/external_launcher.dart';
import 'package:productive_muslim/features/nearby_mosques/domain/usecases/open_nearby_mosques.dart';
import 'package:productive_muslim/features/settings/domain/entities/location_config.dart';
import 'package:productive_muslim/features/settings/domain/repositories/location_repository.dart';
import 'package:productive_muslim/features/settings/domain/usecases/get_current_location.dart';

final class _FakeLauncher implements ExternalLauncher {
  _FakeLauncher({this.result = true, this.geo = true});

  final bool result;

  /// Whether a `geo:` URI is accepted (false: no maps app, e.g. iOS).
  final bool geo;
  Uri? launched;
  int launches = 0;

  @override
  Future<bool> launch(Uri uri) async {
    launches++;
    launched = uri;
    return result && (geo || uri.scheme != 'geo');
  }
}

final class _FakeLocationRepository implements LocationRepository {
  _FakeLocationRepository(this._result);

  final Result<GpsLocation> _result;
  bool called = false;

  @override
  Future<void> openSettings({required bool locationService}) async {}

  @override
  Future<Result<GpsLocation>> getCurrentLocation({
    bool requestPermission = true,
  }) async {
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
      expect(launcher.launched.toString(), 'geo:23.78,90.41?q=mosque');
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
      expect(launcher.launched.toString(), 'geo:21.42,39.82?q=mosque');
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
        currentLocation: () => const GpsLocation(latitude: 1, longitude: 2),
        getCurrentLocation: GetCurrentLocation(repo),
        launcher: launcher,
      );

      final result = await usecase();

      expect(result.fold((_) => null, (f) => f), isA<MapsLaunchFailed>());
    });

    test('falls back to the web URL when no app takes geo:', () async {
      final launcher = _FakeLauncher(geo: false);
      final usecase = OpenNearbyMosques(
        currentLocation: () => const GpsLocation(latitude: 1, longitude: 2),
        getCurrentLocation: GetCurrentLocation(
          _FakeLocationRepository(const Result.failure(LocationUnavailable())),
        ),
        launcher: launcher,
      );

      final result = await usecase();

      expect(result.isSuccess, isTrue);
      expect(launcher.launches, 2);
      expect(launcher.launched!.scheme, 'https');
      expect(launcher.launched.toString(), contains('@1,2,15z'));
    });

    test('a repeat call while one is in flight joins it', () async {
      final launcher = _FakeLauncher();
      final usecase = OpenNearbyMosques(
        currentLocation: () => const GpsLocation(latitude: 1, longitude: 2),
        getCurrentLocation: GetCurrentLocation(
          _FakeLocationRepository(const Result.failure(LocationUnavailable())),
        ),
        launcher: launcher,
      );

      await Future.wait([usecase(), usecase()]);
      expect(launcher.launches, 1);

      await usecase();
      expect(launcher.launches, 2);
    });
  });
}
