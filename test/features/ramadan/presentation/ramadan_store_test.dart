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

  Future<RamadanStore> make({
    bool withLocation = true,
    int hijriOffset = 0,
    DateTime? now,
  }) async {
    final settings = SettingsStore(
      GetSettings(
        _Repo(
          AppSettings(
            location: withLocation ? _dhaka : null,
            hijriOffsetDays: hijriOffset,
          ),
        ),
      ),
      SaveSettings(_Repo(const AppSettings())),
    );
    await settings.load();
    final store = RamadanStore(
      GetPrayerDay(PrayerDayRepositoryImpl(TimezoneClock())),
      settings,
      // 2026-03-01 is inside Ramadan 1447 (1 Ramadan = 18 Feb 2026).
      now: () => now ?? DateTime(2026, 3, 1, 10),
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

  group('RamadanStore with a Hijri offset', () {
    test('offset shifts the roza day', () async {
      expect((await make(hijriOffset: -1)).rozaDay.value, 11);
      expect((await make(hijriOffset: 1)).rozaDay.value, 13);
      expect((await make(hijriOffset: 2)).rozaDay.value, 14);
    });

    test('offset −1: tabular 1 Ramadan is still Sha\'ban', () async {
      final store =
          await make(hijriOffset: -1, now: DateTime(2026, 2, 18, 10));
      expect(store.isRamadan.value, isFalse);
      expect(store.rozaDay.value, isNull);
      expect(store.nextRamadan.value, (1447, 1));
    });

    test('offset +1: Ramadan starts a day before the tabular date', () async {
      final store = await make(hijriOffset: 1, now: DateTime(2026, 2, 17, 10));
      expect(store.isRamadan.value, isTrue);
      expect(store.rozaDay.value, 1);
    });

    test('month table follows the offset', () async {
      final store = await make(hijriOffset: -1);
      expect(store.monthRows.value.first.$1, DateTime(2026, 2, 19));
    });
  });
}
