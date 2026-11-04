import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:productive_muslim/core/l10n/gen/app_localizations.dart';
import 'package:productive_muslim/core/settings/setting_labels.dart';
import 'package:productive_muslim/features/settings/domain/entities/location_config.dart';

void main() {
  final en = lookupAppLocalizations(const Locale('en'));
  final bn = lookupAppLocalizations(const Locale('bn'));
  const gps = GpsLocation(
    latitude: 23.7,
    longitude: 90.4,
    resolvedName: 'Dhaka, BD',
  );

  test('a geocoded name is translated in Bangla, kept in English', () {
    expect(locationLabel(gps, bn), 'ঢাকা, বাংলাদেশ');
    expect(locationLabel(gps, en), 'Dhaka, BD');
    const usa = GpsLocation(
      latitude: 0,
      longitude: 0,
      resolvedName: 'Pasadena, USA',
    );
    expect(locationLabel(usa, bn), 'Pasadena, USA', reason: 'whole words');
  });

  test('null is "not set"; an unnamed fix is "current location"', () {
    expect(locationLabel(null, bn), bn.settingLocationNotSet);
    expect(
      locationLabel(const GpsLocation(latitude: 0, longitude: 0), bn),
      bn.locationCurrent,
    );
  });
}
