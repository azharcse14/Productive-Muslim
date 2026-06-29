import 'package:flutter_test/flutter_test.dart';
import 'package:productive_muslim/core/utils/result.dart';
import 'package:productive_muslim/features/prayer_times/data/repositories/prayer_day_repository_impl.dart';
import 'package:productive_muslim/features/prayer_times/domain/usecases/get_prayer_day.dart';
import 'package:productive_muslim/features/ramadan/domain/usecases/ramadan_utils.dart';
import 'package:productive_muslim/features/ramadan/presentation/state/ramadan_store.dart';
import 'package:productive_muslim/features/settings/data/datasources/timezone_clock.dart';
import 'package:productive_muslim/features/settings/domain/entities/app_settings.dart';
import 'package:productive_muslim/features/settings/domain/entities/city.dart';
import 'package:productive_muslim/features/settings/domain/entities/location_config.dart';
import 'package:productive_muslim/features/settings/domain/repositories/settings_repository.dart';
import 'package:productive_muslim/features/settings/domain/usecases/get_settings.dart';
import 'package:productive_muslim/features/settings/domain/usecases/save_settings.dart';
import 'package:productive_muslim/features/settings/presentation/state/settings_store.dart';

final class _Repo implements SettingsRepository {
  _Repo(this.stored);

  AppSettings stored;

  @override
  Future<Result<AppSettings>> load() async => Result.success(stored);

  @override
  Future<Result<void>> save(AppSettings settings) async {
    stored = settings;
    return const Result.success(null);
  }
}

const _dhaka = ManualCityLocation(
  City(
    name: 'Dhaka',
    countryCode: 'BD',
    latitude: 23.7104,
    longitude: 90.4074,
    timezone: 'Asia/Dhaka',
  ),
);

void main() {
  setUpAll(TimezoneClock.initialize);

  Future<RamadanStore> make({bool withLocation = true}) async {
    final settings = SettingsStore(
      GetSettings(_Repo(AppSettings(location: withLocation ? _dhaka : null))),
      SaveSettings(_Repo(const AppSettings())),
    );
    await settings.load();
    final store = RamadanStore(
      GetPrayerDay(PrayerDayRepositoryImpl(TimezoneClock())),
      settings,
      // 2026-03-01 is inside Ramadan 1447 (1 Ramadan = 18 Feb 2026).
      now: () => DateTime(2026, 3, 1, 10),
    );
    store.load();
    return store;
  }

  group('RamadanStore (fixed clock: 1 Mar 2026, Ramadan 1447)', () {
    test('detects Ramadan and the roza day', () async {
      final store = await make();
      expect(store.isRamadan.value, isTrue);
      expect(store.rozaDay.value, 12); // 18 Feb + 11 days
    });

    test('month rows cover the whole Ramadan with sahri < iftar', () async {
      final store = await make();
      final rows = store.monthRows.value;
      expect(rows.length, RamadanUtils.ramadanLength(1447));
      for (final row in rows) {
        expect(row.$2.isBefore(row.$3), isTrue);
      }
    });

    test('no location → empty rows', () async {
      final store = await make(withLocation: false);
      expect(store.monthRows.value, isEmpty);
    });
  });
}
