import 'package:flutter_test/flutter_test.dart';
import 'package:productive_muslim/features/settings/data/models/app_settings_model.dart';
import 'package:productive_muslim/features/settings/domain/entities/app_settings.dart';
import 'package:productive_muslim/features/settings/domain/entities/city.dart';
import 'package:productive_muslim/features/settings/domain/entities/location_config.dart';
import 'package:productive_muslim/features/settings/domain/entities/notification_matrix.dart';
import 'package:productive_muslim/features/settings/domain/entities/prayer_params.dart';

void main() {
  group('AppSettingsModel', () {
    test('round-trips a fully populated settings object', () {
      const settings = AppSettings(
        location: ManualCityLocation(
          City(
            name: 'Dhaka',
            countryCode: 'BD',
            latitude: 23.7104,
            longitude: 90.4074,
            timezone: 'Asia/Dhaka',
          ),
        ),
        prayerParams: PrayerParams(
          method: CalculationMethodId.ummAlQura,
          madhab: Madhab.shafi,
          highLatitudeRule: HighLatitudeRule.twilightAngle,
          adjustments: {Prayer.fajr: 2, Prayer.isha: -3},
          sahriSafetyMinutes: 5,
        ),
        notifications: NotificationMatrix(
          prayerModes: {Prayer.fajr: AzanMode.beep, Prayer.isha: AzanMode.off},
          sahriAlert: false,
          sahriLead: Duration(minutes: 45),
          jamaatReminder: true,
          jamaatLead: Duration(minutes: 10),
          muhasabaEveningReminder: true,
        ),
        themeMode: AppThemeMode.dark,
        localeCode: 'bn',
        setupComplete: true,
        hijriOffsetDays: -1,
        showAchievements: true,
      );

      final restored =
          AppSettingsModel.fromMap(AppSettingsModel.toMap(settings));
      expect(restored, settings);
    });

    test('round-trips a GPS location', () {
      const settings = AppSettings(
        location: GpsLocation(
          latitude: 21.4225,
          longitude: 39.8262,
          resolvedName: 'Makkah',
        ),
      );
      final restored =
          AppSettingsModel.fromMap(AppSettingsModel.toMap(settings));
      expect(restored.location, settings.location);
    });

    test('empty map yields pure defaults', () {
      expect(AppSettingsModel.fromMap(const {}), const AppSettings());
    });

    test('unknown enum names fall back to defaults (forward compat)', () {
      final restored = AppSettingsModel.fromMap(const {
        'themeMode': 'sepia',
        'prayerParams': {'method': 'someFutureMethod', 'madhab': 'zahiri'},
      });
      expect(restored.themeMode, AppThemeMode.system);
      expect(restored.prayerParams.method, CalculationMethodId.karachi);
      expect(restored.prayerParams.madhab, Madhab.hanafi);
    });

    test('corrupt location payload becomes null, not a crash', () {
      final restored = AppSettingsModel.fromMap(const {
        'location': {'type': 'city', 'lat': 'not-a-number'},
      });
      expect(restored.location, isNull);
    });

    test('missing hijriOffsetDays → 0; out-of-range values are clamped', () {
      expect(AppSettingsModel.fromMap(const {}).hijriOffsetDays, 0);
      expect(
        AppSettingsModel.fromMap(const {'hijriOffsetDays': 5}).hijriOffsetDays,
        2,
      );
      expect(
        AppSettingsModel.fromMap(const {'hijriOffsetDays': -9})
            .hijriOffsetDays,
        -2,
      );
      expect(const AppSettings(hijriOffsetDays: 1).hijriOffsetDays, 1);
    });

    test('showAchievements defaults to off', () {
      expect(AppSettingsModel.fromMap(const {}).showAchievements, isFalse);
    });

    test('missing sahriSafety → 0; out-of-range values are clamped', () {
      int read(Object? v) => AppSettingsModel.fromMap({
            'prayerParams': {'sahriSafety': v},
          }).prayerParams.sahriSafetyMinutes;
      expect(AppSettingsModel.fromMap(const {}).prayerParams.sahriSafetyMinutes,
          0);
      expect(read(null), 0);
      expect(read(7), 7);
      expect(read(25), 10);
      expect(read(-3), 0);
    });
  });
}
