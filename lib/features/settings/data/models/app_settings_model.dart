import '../../../daily_content/domain/usecases/pick_daily_content.dart';
import '../../domain/entities/app_settings.dart';
import '../../domain/entities/city.dart';
import '../../domain/entities/location_config.dart';
import '../../domain/entities/notification_matrix.dart';
import '../../domain/entities/prayer_params.dart';

/// Hand-written JSON mapping for [AppSettings] (guide §3 — no codegen).
/// Unknown/missing fields fall back to defaults so old payloads survive
/// app upgrades.
abstract final class AppSettingsModel {
  static Map<String, Object?> toMap(AppSettings s) => {
        'location': switch (s.location) {
          null => null,
          GpsLocation(:final latitude, :final longitude, :final resolvedName) =>
            {
              'type': 'gps',
              'lat': latitude,
              'lng': longitude,
              'name': resolvedName,
            },
          ManualCityLocation(:final city) => {
              'type': 'city',
              'name': city.name,
              'country': city.countryCode,
              'lat': city.latitude,
              'lng': city.longitude,
              'tz': city.timezone,
            },
        },
        'prayerParams': {
          'method': s.prayerParams.method.name,
          'madhab': s.prayerParams.madhab.name,
          'highLat': s.prayerParams.highLatitudeRule.name,
          'sahriSafety': s.prayerParams.sahriSafetyMinutes,
          'adjustments': {
            for (final e in s.prayerParams.adjustments.entries)
              e.key.name: e.value,
          },
        },
        'notifications': {
          'modes': {
            for (final e in s.notifications.prayerModes.entries)
              e.key.name: e.value.name,
          },
          'sahriAlert': s.notifications.sahriAlert,
          'sahriLeadMin': s.notifications.sahriLead.inMinutes,
          'iftarAlert': s.notifications.iftarAlert,
          'jamaatReminder': s.notifications.jamaatReminder,
          'jamaatLeadMin': s.notifications.jamaatLead.inMinutes,
          'muhasabaEvening': s.notifications.muhasabaEveningReminder,
          'dailyReminder': s.notifications.dailyReminder,
          'dailyReminderMinute': s.notifications.dailyReminderMinute,
          'dailyReminderKind': s.notifications.dailyReminderKind.name,
        },
        'themeMode': s.themeMode.name,
        'localeCode': s.localeCode,
        'setupComplete': s.setupComplete,
        'hijriOffsetDays': s.hijriOffsetDays,
      };

  static AppSettings fromMap(Map<String, Object?> map) {
    const defaults = AppSettings();
    return AppSettings(
      location: _location(map['location']),
      prayerParams: _prayerParams(map['prayerParams']),
      notifications: _notifications(map['notifications']),
      themeMode: _enumOrDefault(
        AppThemeMode.values,
        map['themeMode'],
        defaults.themeMode,
      ),
      localeCode: map['localeCode'] as String? ?? defaults.localeCode,
      setupComplete:
          map['setupComplete'] as bool? ?? defaults.setupComplete,
      hijriOffsetDays:
          (map['hijriOffsetDays'] as num?)?.toInt() ?? defaults.hijriOffsetDays,
    );
  }

  static LocationConfig? _location(Object? raw) {
    if (raw is! Map) {
      return null;
    }
    final map = raw.cast<String, Object?>();
    final rawLat = map['lat'];
    final rawLng = map['lng'];
    if (rawLat is! num || rawLng is! num) {
      return null;
    }
    final lat = rawLat.toDouble();
    final lng = rawLng.toDouble();
    return switch (map['type']) {
      'gps' => GpsLocation(
          latitude: lat,
          longitude: lng,
          resolvedName: map['name'] as String? ?? '',
        ),
      'city' => ManualCityLocation(
          City(
            name: map['name'] as String? ?? '',
            countryCode: map['country'] as String? ?? '',
            latitude: lat,
            longitude: lng,
            timezone: map['tz'] as String? ?? 'UTC',
          ),
        ),
      _ => null,
    };
  }

  static PrayerParams _prayerParams(Object? raw) {
    const defaults = PrayerParams();
    if (raw is! Map) {
      return defaults;
    }
    final map = raw.cast<String, Object?>();
    final rawAdjustments =
        (map['adjustments'] as Map?)?.cast<String, Object?>() ?? {};
    return PrayerParams(
      method: _enumOrDefault(
        CalculationMethodId.values,
        map['method'],
        defaults.method,
      ),
      madhab: _enumOrDefault(Madhab.values, map['madhab'], defaults.madhab),
      highLatitudeRule: _enumOrDefault(
        HighLatitudeRule.values,
        map['highLat'],
        defaults.highLatitudeRule,
      ),
      adjustments: {
        for (final prayer in Prayer.values)
          if (rawAdjustments[prayer.name] is int)
            prayer: rawAdjustments[prayer.name]! as int,
      },
      sahriSafetyMinutes: (map['sahriSafety'] as num?)?.toInt() ??
          defaults.sahriSafetyMinutes,
    );
  }

  static NotificationMatrix _notifications(Object? raw) {
    const defaults = NotificationMatrix();
    if (raw is! Map) {
      return defaults;
    }
    final map = raw.cast<String, Object?>();
    final rawModes = (map['modes'] as Map?)?.cast<String, Object?>() ?? {};
    return NotificationMatrix(
      prayerModes: {
        for (final prayer in Prayer.values)
          if (rawModes[prayer.name] != null)
            prayer: _enumOrDefault(
              AzanMode.values,
              rawModes[prayer.name],
              AzanMode.azan,
            ),
      },
      sahriAlert: map['sahriAlert'] as bool? ?? defaults.sahriAlert,
      sahriLead: Duration(
        minutes: map['sahriLeadMin'] as int? ?? defaults.sahriLead.inMinutes,
      ),
      iftarAlert: map['iftarAlert'] as bool? ?? defaults.iftarAlert,
      jamaatReminder:
          map['jamaatReminder'] as bool? ?? defaults.jamaatReminder,
      jamaatLead: Duration(
        minutes:
            map['jamaatLeadMin'] as int? ?? defaults.jamaatLead.inMinutes,
      ),
      muhasabaEveningReminder:
          map['muhasabaEvening'] as bool? ?? defaults.muhasabaEveningReminder,
      dailyReminder: map['dailyReminder'] as bool? ?? defaults.dailyReminder,
      dailyReminderMinute:
          map['dailyReminderMinute'] as int? ?? defaults.dailyReminderMinute,
      dailyReminderKind: _enumOrDefault(
        DailyContentKind.values,
        map['dailyReminderKind'],
        defaults.dailyReminderKind,
      ),
    );
  }

  static T _enumOrDefault<T extends Enum>(
    List<T> values,
    Object? name,
    T fallback,
  ) {
    if (name is! String) {
      return fallback;
    }
    for (final v in values) {
      if (v.name == name) {
        return v;
      }
    }
    return fallback;
  }
}
