import 'package:flutter_test/flutter_test.dart';
import 'package:productive_muslim/core/utils/result.dart';
import 'package:productive_muslim/features/prayer_times/data/repositories/prayer_day_repository_impl.dart';
import 'package:productive_muslim/features/prayer_times/domain/entities/prayer_day.dart';
import 'package:productive_muslim/features/prayer_times/domain/repositories/prayer_day_repository.dart';
import 'package:productive_muslim/features/prayer_times/domain/usecases/get_prayer_day.dart';
import 'package:productive_muslim/features/ramadan/domain/usecases/ramadan_utils.dart';
import 'package:productive_muslim/features/ramadan/presentation/state/ramadan_store.dart';
import 'package:productive_muslim/features/settings/data/datasources/timezone_clock.dart';
import 'package:productive_muslim/features/settings/domain/entities/app_settings.dart';
import 'package:productive_muslim/features/settings/domain/entities/city.dart';
import 'package:productive_muslim/features/settings/domain/entities/location_config.dart';
import 'package:productive_muslim/features/settings/domain/entities/prayer_params.dart';
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

/// Real prayer times, except [failOn] fails (as an extreme-latitude
/// day can).
final class _FailingOn implements PrayerDayRepository {
  _FailingOn(this.failOn);

  final DateTime failOn;
  final _real = PrayerDayRepositoryImpl(TimezoneClock());

  @override
  Result<PrayerDay> prayerDay({
    required LocationConfig location,
    required PrayerParams params,
    required DateTime date,
  }) => date == failOn
      ? const Result.failure(UnexpectedFailure('no times'))
      : _real.prayerDay(location: location, params: params, date: date);
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

  late SettingsStore settings;

  Future<RamadanStore> make({
    bool withLocation = true,
    int hijriOffset = 0,
    DateTime? now,
  }) async {
    settings = SettingsStore(
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
      for (final (i, row) in rows.indexed) {
        expect(row.$4, i + 1);
        expect(row.$2.isBefore(row.$3), isTrue);
      }
    });

    test('no location → empty rows', () async {
      final store = await make(withLocation: false);
      expect(store.monthRows.value, isEmpty);
    });

    test('rows appear once a location is set later', () async {
      final store = await make(withLocation: false);
      expect(store.monthRows.value, isEmpty);
      await settings.setLocation(_dhaka);
      expect(store.monthRows.value.length, RamadanUtils.ramadanLength(1447));
    });
  });

  testWidgets('follows the day past midnight while open', (tester) async {
    var clock = DateTime(2026, 3, 1, 23, 59, 30);
    settings = SettingsStore(
      GetSettings(_Repo(const AppSettings(location: _dhaka))),
      SaveSettings(_Repo(const AppSettings())),
    );
    await settings.load();
    final store = RamadanStore(
      GetPrayerDay(PrayerDayRepositoryImpl(TimezoneClock())),
      settings,
      now: () => clock,
    );
    expect(store.rozaDay.value, 12);
    clock = DateTime(2026, 3, 2, 0, 0, 30);
    await tester.pump(const Duration(minutes: 1));
    expect(store.today.value, DateTime(2026, 3, 2));
    expect(store.rozaDay.value, 13);
    store.dispose();
  });

  test('re-reads the day on a location change, not just the tick', () async {
    // Device clock is New York 20:00; the manual city's wall clock is
    // already the next morning once it's selected.
    var clock = DateTime(2026, 3, 1, 20);
    settings = SettingsStore(
      GetSettings(_Repo(const AppSettings())),
      SaveSettings(_Repo(const AppSettings())),
    );
    await settings.load();
    final store = RamadanStore(
      GetPrayerDay(PrayerDayRepositoryImpl(TimezoneClock())),
      settings,
      now: () => clock,
    );
    addTearDown(store.dispose);
    expect(store.rozaDay.value, 12);
    clock = DateTime(2026, 3, 2, 7);
    await settings.setLocation(_dhaka);
    expect(store.today.value, DateTime(2026, 3, 2));
    expect(store.rozaDay.value, 13);
  });

  test('rowAfter: no row when the next day failed to compute', () async {
    settings = SettingsStore(
      GetSettings(_Repo(const AppSettings(location: _dhaka))),
      SaveSettings(_Repo(const AppSettings())),
    );
    await settings.load();
    final store = RamadanStore(
      GetPrayerDay(_FailingOn(DateTime(2026, 3, 3))),
      settings,
      now: () => DateTime(2026, 3, 2, 20),
    );
    addTearDown(store.dispose);
    expect(store.rowAfter(DateTime(2026, 3, 2)), isNull);
    expect(store.rowAfter(DateTime(2026, 3, 3))?.$4, 15);
    final last = store.monthRows.value.last.$1;
    expect(store.rowAfter(last), isNull);
  });

  group('RamadanStore with a Hijri offset', () {
    test('offset shifts the roza day', () async {
      expect((await make(hijriOffset: -1)).rozaDay.value, 11);
      expect((await make(hijriOffset: 1)).rozaDay.value, 13);
      expect((await make(hijriOffset: 2)).rozaDay.value, 14);
    });

    test('offset −1: tabular 1 Ramadan is still Sha\'ban', () async {
      final store = await make(hijriOffset: -1, now: DateTime(2026, 2, 18, 10));
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
