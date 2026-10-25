import 'package:flutter_test/flutter_test.dart';
import 'package:productive_muslim/features/settings/domain/entities/city.dart';
import 'package:productive_muslim/features/settings/domain/entities/location_config.dart';
import 'package:productive_muslim/features/settings/domain/entities/prayer_params.dart';
import 'package:productive_muslim/features/settings/domain/usecases/regional_defaults.dart';

void main() {
  group('defaultMadhabFor', () {
    test('Hanafi-majority regions default to Hanafi', () {
      for (final cc in [
        'BD', 'PK', 'IN', 'AF', 'TR', 'UZ', 'TJ', 'KZ', 'KG', 'TM', //
        'BA', 'AL', 'XK', 'MK',
      ]) {
        expect(defaultMadhabFor(cc), Madhab.hanafi, reason: cc);
      }
    });

    test('everywhere else uses the standard Asr', () {
      for (final cc in ['SA', 'EG', 'MY', 'ID', 'GB', 'US', 'NG', '']) {
        expect(defaultMadhabFor(cc), Madhab.shafi, reason: cc);
      }
    });
  });

  test('suggestedMethodFor keeps the existing regional mapping', () {
    expect(suggestedMethodFor('BD'), CalculationMethodId.karachi);
    expect(suggestedMethodFor('SA'), CalculationMethodId.ummAlQura);
    expect(suggestedMethodFor('GB'), CalculationMethodId.moonsightingCommittee);
    expect(suggestedMethodFor('XX'), CalculationMethodId.muslimWorldLeague);
  });

  test('countryCodeOf reads the display name suffix', () {
    const dhaka = ManualCityLocation(
      City(
        name: 'Dhaka',
        countryCode: 'BD',
        latitude: 23.7,
        longitude: 90.4,
        timezone: 'Asia/Dhaka',
      ),
    );
    expect(countryCodeOf(dhaka), 'BD');
    expect(countryCodeOf(null), '');
  });
}
