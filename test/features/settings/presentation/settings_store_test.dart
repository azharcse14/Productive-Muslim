import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_test/flutter_test.dart';
import 'package:productive_muslim/core/utils/result.dart';
import 'package:productive_muslim/features/settings/domain/entities/app_settings.dart';
import 'package:productive_muslim/features/settings/domain/entities/city.dart';
import 'package:productive_muslim/features/settings/domain/entities/location_config.dart';
import 'package:productive_muslim/features/settings/domain/entities/prayer_params.dart';
import 'package:productive_muslim/features/settings/domain/repositories/settings_repository.dart';
import 'package:productive_muslim/features/settings/domain/usecases/get_settings.dart';
import 'package:productive_muslim/features/settings/domain/usecases/save_settings.dart';
import 'package:productive_muslim/features/settings/presentation/state/settings_store.dart';

final class _InMemoryRepo implements SettingsRepository {
  AppSettings stored = const AppSettings();
  int saves = 0;
  bool failLoad = false;

  @override
  Future<Result<AppSettings>> load() async => failLoad
      ? const Result.failure(UnexpectedFailure('boom'))
      : Result.success(stored);

  @override
  Future<Result<void>> save(AppSettings settings) async {
    stored = settings;
    saves++;
    return const Result.success(null);
  }
}

(SettingsStore, _InMemoryRepo) _make() {
  final repo = _InMemoryRepo();
  return (SettingsStore(GetSettings(repo), SaveSettings(repo)), repo);
}

void main() {
  group('SettingsStore', () {
    test('a failed read blocks saves so stored data survives', () async {
      final (store, repo) = _make();
      repo
        ..stored = const AppSettings(localeCode: 'bn', setupComplete: true)
        ..failLoad = true;
      await store.load();
      expect(store.settings.value.setupComplete, isFalse);

      await store.setThemeMode(AppThemeMode.dark);
      expect(repo.saves, 0);
      expect(store.settings.value.themeMode, AppThemeMode.dark);
      expect(repo.stored.localeCode, 'bn');

      // Storage recovers: the next update re-reads instead of clobbering.
      repo.failLoad = false;
      await store.setThemeMode(AppThemeMode.light);
      expect(repo.saves, 0);
      expect(store.settings.value.localeCode, 'bn');
      expect(store.settings.value.setupComplete, isTrue);

      await store.setThemeMode(AppThemeMode.light);
      expect(repo.saves, 1);
      expect(repo.stored.localeCode, 'bn');
    });

    test('load pulls persisted settings into the signal', () async {
      final (store, repo) = _make();
      repo.stored = const AppSettings(localeCode: 'bn');
      await store.load();
      expect(store.settings.value.localeCode, 'bn');
      expect(store.loaded.value, isTrue);
    });

    test('themeMode derives Flutter ThemeMode', () async {
      final (store, _) = _make();
      await store.setThemeMode(AppThemeMode.dark);
      expect(store.themeMode.value, ThemeMode.dark);
      await store.setThemeMode(AppThemeMode.system);
      expect(store.themeMode.value, ThemeMode.system);
    });

    test('every update persists', () async {
      final (store, repo) = _make();
      await store.setLocale('bn');
      await store.setMadhab(Madhab.shafi);
      await store.setMethod(CalculationMethodId.ummAlQura);
      expect(repo.saves, 3);
      expect(repo.stored.localeCode, 'bn');
      expect(repo.stored.prayerParams.madhab, Madhab.shafi);
      expect(repo.stored.prayerParams.method, CalculationMethodId.ummAlQura);
    });

    test('setAdjustment merges per-prayer offsets', () async {
      final (store, repo) = _make();
      await store.setAdjustment(Prayer.fajr, 2);
      await store.setAdjustment(Prayer.isha, -3);
      expect(repo.stored.prayerParams.adjustmentFor(Prayer.fajr), 2);
      expect(repo.stored.prayerParams.adjustmentFor(Prayer.isha), -3);
      expect(repo.stored.prayerParams.adjustmentFor(Prayer.asr), 0);
    });

    test('setLocation updates the derived location', () async {
      final (store, _) = _make();
      const city = City(
        name: 'Dhaka',
        countryCode: 'BD',
        latitude: 23.7,
        longitude: 90.4,
        timezone: 'Asia/Dhaka',
      );
      await store.setLocation(const ManualCityLocation(city));
      expect(store.location.value?.displayName, 'Dhaka, BD');
    });

    test('failed load keeps defaults and still marks loaded', () async {
      final repo = _FailingRepo();
      final store = SettingsStore(GetSettings(repo), SaveSettings(repo));
      await store.load();
      expect(store.settings.value, const AppSettings());
      expect(store.loaded.value, isTrue);
    });
  });
}

final class _FailingRepo implements SettingsRepository {
  @override
  Future<Result<AppSettings>> load() async =>
      const Result.failure(UnexpectedFailure('disk error'));

  @override
  Future<Result<void>> save(AppSettings settings) async =>
      const Result.success(null);
}
