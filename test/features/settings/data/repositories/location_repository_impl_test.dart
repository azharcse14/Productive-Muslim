import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:productive_muslim/features/settings/data/datasources/geolocator_data_source.dart';
import 'package:productive_muslim/features/settings/data/repositories/location_repository_impl.dart';
import 'package:productive_muslim/features/settings/domain/repositories/location_repository.dart';

final class _FakeSource implements DeviceLocationSource {
  _FakeSource({
    this.serviceEnabled = true,
    this.permission = LocationPermission.whileInUse,
    this.permissionAfterRequest,
    this.position,
  });

  final bool serviceEnabled;
  final LocationPermission permission;
  final LocationPermission? permissionAfterRequest;
  final Position? position;
  bool requested = false;

  @override
  Future<bool> isServiceEnabled() async => serviceEnabled;

  @override
  Future<LocationPermission> checkPermission() async => permission;

  @override
  Future<LocationPermission> requestPermission() async {
    requested = true;
    return permissionAfterRequest ?? permission;
  }

  @override
  Future<Position> currentPosition() async =>
      position ?? (throw StateError('no position'));
}

Position _position(double lat, double lng) => Position(
  latitude: lat,
  longitude: lng,
  timestamp: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
  accuracy: 10,
  altitude: 0,
  altitudeAccuracy: 0,
  heading: 0,
  headingAccuracy: 0,
  speed: 0,
  speedAccuracy: 0,
);

void main() {
  group('LocationRepositoryImpl', () {
    test('service disabled → LocationServiceDisabled', () async {
      final repo = LocationRepositoryImpl(_FakeSource(serviceEnabled: false));
      final result = await repo.getCurrentLocation();
      expect(
        result.fold((_) => null, (f) => f),
        isA<LocationServiceDisabled>(),
      );
    });

    test('denied then denied again → LocationPermissionDenied', () async {
      final repo = LocationRepositoryImpl(
        _FakeSource(
          permission: LocationPermission.denied,
          permissionAfterRequest: LocationPermission.denied,
        ),
      );
      final result = await repo.getCurrentLocation();
      expect(
        result.fold((_) => null, (f) => f),
        isA<LocationPermissionDenied>(),
      );
    });

    test('denied forever → LocationPermissionDeniedForever', () async {
      final repo = LocationRepositoryImpl(
        _FakeSource(permission: LocationPermission.deniedForever),
      );
      final result = await repo.getCurrentLocation();
      expect(
        result.fold((_) => null, (f) => f),
        isA<LocationPermissionDeniedForever>(),
      );
    });

    test('denied then granted on request → success', () async {
      final source = _FakeSource(
        permission: LocationPermission.denied,
        permissionAfterRequest: LocationPermission.whileInUse,
        position: _position(23.7, 90.4),
      );
      final repo = LocationRepositoryImpl(source);
      final result = await repo.getCurrentLocation();
      expect(source.requested, isTrue);
      expect(result.valueOrNull?.latitude, 23.7);
    });

    test('requestPermission: false never prompts', () async {
      final source = _FakeSource(
        permission: LocationPermission.denied,
        permissionAfterRequest: LocationPermission.whileInUse,
        position: _position(23.7, 90.4),
      );
      final result = await LocationRepositoryImpl(
        source,
      ).getCurrentLocation(requestPermission: false);
      expect(source.requested, isFalse);
      expect(
        result.fold((_) => null, (f) => f),
        isA<LocationPermissionDenied>(),
      );
    });

    test('granted → returns GpsLocation with coordinates', () async {
      final repo = LocationRepositoryImpl(
        _FakeSource(position: _position(21.4225, 39.8262)),
      );
      final result = await repo.getCurrentLocation();
      final location = result.valueOrNull!;
      expect(location.latitude, 21.4225);
      expect(location.longitude, 39.8262);
    });

    test('position lookup throwing → LocationUnavailable', () async {
      final repo = LocationRepositoryImpl(_FakeSource());
      final result = await repo.getCurrentLocation();
      expect(result.fold((_) => null, (f) => f), isA<LocationUnavailable>());
    });
  });
}
