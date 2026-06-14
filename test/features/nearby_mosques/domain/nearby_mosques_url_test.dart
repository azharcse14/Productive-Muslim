import 'package:flutter_test/flutter_test.dart';
import 'package:qalbee/features/nearby_mosques/domain/nearby_mosques_url.dart';

void main() {
  group('NearbyMosquesUrl', () {
    test('targets the Google Maps mosque search centred on the coordinate',
        () {
      final uri = NearbyMosquesUrl.build(latitude: 23.7806, longitude: 90.4074);
      expect(uri.scheme, 'https');
      expect(uri.host, 'www.google.com');
      expect(uri.toString(), contains('/maps/search/mosque/'));
      expect(uri.toString(), contains('@23.7806,90.4074,15z'));
    });

    test('uses a dot decimal separator regardless of locale', () {
      final uri = NearbyMosquesUrl.build(latitude: 21.4225, longitude: 39.8262);
      expect(uri.toString(), contains('@21.4225,39.8262'));
      expect(uri.toString(), isNot(contains(',2')));
    });

    test('trims trailing-zero precision and handles negatives', () {
      final uri = NearbyMosquesUrl.build(latitude: -1.5, longitude: 100.0);
      expect(uri.toString(), contains('@-1.5,100,15z'));
    });
  });
}
