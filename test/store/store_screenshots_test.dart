/// Store screenshots of the key screens, pumped with fakes (fixed clock,
/// Dhaka) and the real bundled content. Skipped by default (see
/// dart_test.yaml); run: flutter test --tags store --run-skipped test/store
@Tags(['store'])
library;

import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:productive_muslim/core/settings/settings_store.dart';
import 'package:productive_muslim/features/dua_tasbih/data/dua_asset_data_source.dart';
import 'package:productive_muslim/features/dua_tasbih/data/dua_repository_impl.dart';
import 'package:productive_muslim/features/dua_tasbih/presentation/screens/dua_screen.dart';
import 'package:productive_muslim/features/dua_tasbih/presentation/screens/tasbih_screen.dart';
import 'package:productive_muslim/features/dua_tasbih/presentation/state/dua_favorites_store.dart';
import 'package:productive_muslim/features/dua_tasbih/presentation/state/dua_store.dart';
import 'package:productive_muslim/features/dua_tasbih/presentation/state/tasbih_store.dart';
import 'package:productive_muslim/features/keep_awake/domain/screen_wake.dart';
import 'package:productive_muslim/features/muhasaba/data/database/muhasaba_database.dart';
import 'package:productive_muslim/features/muhasaba/data/repositories/muhasaba_repository_impl.dart';
import 'package:productive_muslim/features/muhasaba/domain/entities/daily_entry.dart';
import 'package:productive_muslim/features/muhasaba/domain/entities/tracker_item.dart';
import 'package:productive_muslim/features/muhasaba/domain/repositories/muhasaba_repository.dart';
import 'package:productive_muslim/features/muhasaba/presentation/screens/muhasaba_screen.dart';
import 'package:productive_muslim/features/muhasaba/presentation/state/muhasaba_store.dart';
import 'package:productive_muslim/features/my_mosque/domain/entities/jamaat_config.dart';
import 'package:productive_muslim/features/my_mosque/domain/entities/mosque_profile.dart';
import 'package:productive_muslim/features/my_mosque/domain/entities/mosque_state.dart';
import 'package:productive_muslim/features/my_mosque/presentation/state/mosque_store.dart';
import 'package:productive_muslim/features/prayer_times/data/repositories/prayer_day_repository_impl.dart';
import 'package:productive_muslim/features/prayer_times/domain/usecases/get_prayer_day.dart';
import 'package:productive_muslim/features/prayer_times/presentation/screens/home_screen.dart';
import 'package:productive_muslim/features/prayer_times/presentation/state/home_store.dart';
import 'package:productive_muslim/features/prophets/data/prophet_repository_impl.dart';
import 'package:productive_muslim/features/prophets/presentation/screens/prophets_screen.dart';
import 'package:productive_muslim/features/prophets/presentation/state/prophets_store.dart';
import 'package:productive_muslim/features/qibla/domain/repositories/compass_sensor_source.dart';
import 'package:productive_muslim/features/qibla/presentation/screens/qibla_screen.dart';
import 'package:productive_muslim/features/qibla/presentation/state/qibla_store.dart';
import 'package:productive_muslim/features/quran/data/datasources/quran_database.dart';
import 'package:productive_muslim/features/quran/data/repositories/quran_repository_impl.dart';
import 'package:productive_muslim/features/quran/presentation/screens/quran_reader_screen.dart';
import 'package:productive_muslim/features/quran/presentation/state/quran_store.dart';
import 'package:productive_muslim/features/settings/data/datasources/timezone_clock.dart';
import 'package:productive_muslim/features/settings/domain/entities/app_settings.dart';
import 'package:productive_muslim/features/settings/domain/entities/city.dart';
import 'package:productive_muslim/features/settings/domain/entities/location_config.dart';
import 'package:productive_muslim/features/settings/domain/entities/prayer_params.dart';
import 'package:productive_muslim/features/settings/domain/repositories/zoned_clock.dart';
import 'package:productive_muslim/features/share/domain/share_sheet.dart';
import 'package:productive_muslim/features/stories/data/story_asset_data_source.dart';
import 'package:productive_muslim/features/stories/data/story_repository_impl.dart';
import 'package:productive_muslim/shared/widgets/q_bottom_nav.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import '../helpers/content_fakes.dart';
import '../helpers/mosque_fakes.dart';
import '../helpers/screen_wake_fake.dart';
import '../helpers/settings_fakes.dart';
import '../helpers/share_sheet_fake.dart';
import 'store_capture.dart';

/// Thursday 5 Nov 2026, 15:44 in Dhaka: Asr has begun, jamaat at 16:00.
final _now = DateTime(2026, 11, 5, 15, 44, 12);

const _dhaka = ManualCityLocation(
  City(
    name: 'Dhaka',
    countryCode: 'BD',
    latitude: 23.7104,
    longitude: 90.4074,
    timezone: 'Asia/Dhaka',
  ),
);

/// Store sizes: physical pixels and device pixel ratio. Play renders a
/// 411dp-wide phone (Pixel class); the App Store ones are iPhone 3× sizes.
const _devices = {
  'play': (Size(1080, 1920), 2.625),
  'appstore_6.7': (Size(1290, 2796), 3.0),
  'appstore_6.5': (Size(1242, 2688), 3.0),
};

final class _FixedClock implements ZonedClock {
  final _real = TimezoneClock();

  @override
  DateTime nowAt(LocationConfig location) => DateTime.utc(
    _now.year,
    _now.month,
    _now.day,
    _now.hour,
    _now.minute,
    _now.second,
  );

  @override
  DateTime instantAt(LocationConfig location, DateTime instant) =>
      _real.instantAt(location, instant);

  @override
  DateTime utcInstantOf(LocationConfig location, DateTime wall) =>
      _real.utcInstantOf(location, wall);
}

final class _NoSensors implements CompassSensorSource {
  @override
  Stream<SensorVectors> vectors() => const Stream.empty();
}

const _mosque = MosqueState(
  profiles: [
    MosqueProfile(
      id: 'baitul',
      name: 'Baitul Mukarram',
      entries: {
        Prayer.fajr: FixedJamaat(ClockTime(5, 20)),
        Prayer.dhuhr: FixedJamaat(ClockTime(13, 15)),
        Prayer.asr: FixedJamaat(ClockTime(16, 0)),
        Prayer.maghrib: OffsetJamaat(Duration(minutes: 5)),
        Prayer.isha: FixedJamaat(ClockTime(19, 45)),
      },
      jumuah: ClockTime(13, 30),
    ),
  ],
  activeId: 'baitul',
);

/// Four weeks of a steady-but-human Muhasaba history, plus today so far.
Future<MuhasabaRepository> _muhasabaHistory() async {
  final repo = MuhasabaRepositoryImpl(
    MuhasabaDatabase(NativeDatabase.memory()),
    clock: () => DateTime(2026),
  );
  await repo.seedDefaults();
  final items = DefaultTrackers.items();
  for (var back = 27; back >= 0; back--) {
    final day = DateTime(_now.year, _now.month, _now.day - back);
    for (final (i, item) in items.indexed) {
      // Deterministic pseudo-random 0..9 per (day, item).
      final r = ((back * 31 + i * 17) * 2654435761 >> 8) % 10;
      final value = switch (item.id) {
        'salah_fajr' || 'salah_dhuhr' when back == 0 => 1,
        'salah_asr' || 'salah_maghrib' || 'salah_isha' when back == 0 => 0,
        _ when item.id.startsWith('salah_') => r < 9 ? 1 : 0,
        'quran' => r < 8 ? 10 + r * 3 : 4,
        'azkar' => r < 7 ? 100 : 33,
        'tahajjud' => r < 4 ? 1 : 0,
        'roza' =>
          day.weekday == DateTime.monday || day.weekday == DateTime.thursday
              ? 1
              : 0,
        _ => r < 6 ? 1 : 0,
      };
      if (value > 0) {
        await repo.setEntry(
          DailyEntry(itemId: item.id, date: day, value: value),
        );
      }
    }
  }
  return repo;
}

/// Registers every store the six screens resolve, over fakes and the real
/// bundled content. Loads run outside the fake-async zone (asset decoding
/// of large JSON goes through an isolate).
Future<void> _register(WidgetTester tester, String locale) async {
  SharedPreferencesAsyncPlatform.instance =
      InMemorySharedPreferencesAsync.empty();
  TimezoneClock.initialize();
  await tester.runAsync(() async {
    final settings = await makeSettingsStore(
      AppSettings(location: _dhaka, localeCode: locale, setupComplete: true),
    );
    final (mosque, _) = await makeMosqueStore(_mosque);
    final muhasaba = MuhasabaStore(
      await _muhasabaHistory(),
      now: () => _now,
      statsDebounce: Duration.zero,
    );
    await muhasaba.load();

    final dir = await Directory.systemTemp.createTemp('store_quran');
    final db = File('${dir.path}/quran.db');
    await File('assets/data/quran.db').copy(db.path);
    final quran = QuranStore(
      QuranRepositoryImpl(QuranDatabase(NativeDatabase(db))),
      SharedPreferencesAsync(),
    );
    await quran.load();

    final dua = DuaStore(DuaRepositoryImpl(DuaAssetDataSource(rootBundle)));
    await dua.load();
    final favorites = DuaFavoritesStore(SharedPreferencesAsync());
    await favorites.load();
    final tasbih = await makeTasbihStore();
    final prophets = ProphetsStore(
      ProphetRepositoryImpl(rootBundle),
      StoryRepositoryImpl(StoryAssetDataSource(rootBundle)),
    );
    await prophets.load();

    GetIt.I
      ..registerSingleton<SettingsStore>(settings)
      ..registerSingleton<MosqueStore>(mosque)
      ..registerSingleton<MuhasabaStore>(muhasaba)
      ..registerSingleton<QuranStore>(quran)
      ..registerSingleton<DuaStore>(dua)
      ..registerSingleton<DuaFavoritesStore>(favorites)
      ..registerSingleton<TasbihStore>(tasbih)
      ..registerSingleton<ProphetsStore>(prophets)
      ..registerSingleton<ScreenWake>(FakeScreenWake())
      ..registerSingleton<ShareSheet>(FakeShareSheet())
      ..registerLazySingleton<QiblaStore>(
        () => QiblaStore(
          sensors: _NoSensors(),
          settings: settings,
          firstEventTimeout: const Duration(days: 1),
          now: () => _now,
        ),
      )
      ..registerLazySingleton<HomeStore>(
        () => HomeStore(
          getPrayerDay: GetPrayerDay(PrayerDayRepositoryImpl(_FixedClock())),
          clock: _FixedClock(),
          settings: settings,
          mosque: mosque,
        ),
      );
  });
}

Widget _tab(int index, Widget screen) =>
    QBottomNavScaffold(body: screen, currentIndex: index, onSelect: (_) {});

/// name → (screen, prepare-before-capture).
final Map<String, (Widget, Future<void> Function(WidgetTester))> _screens = {
  'home': (_tab(0, const HomeScreen()), (_) async {}),
  'quran_reader': (const QuranReaderScreen(surahId: 1), (_) async {}),
  'qibla': (
    const QiblaScreen(),
    (_) async {
      // As if the phone just turned onto the qibla (aligned is set by
      // sensor events, which this fake never sends).
      final store = GetIt.I<QiblaStore>();
      store.heading.value = store.bearing.value! - 1;
      store.aligned.value = true;
    },
  ),
  'muhasaba_dashboard': (
    _tab(2, const MuhasabaScreen()),
    (tester) async {
      await tester.tap(find.text('Dashboard'));
      await _settle(tester);
      await tester.tap(find.text('Month'));
    },
  ),
  'dua': (_tab(3, const DuaScreen()), (_) async {}),
  'tasbih': (
    const TasbihScreen(),
    (_) async {
      final store = GetIt.I<TasbihStore>();
      for (var i = 0; i < 21; i++) {
        store.tap();
      }
    },
  ),
  'prophets': (const ProphetsScreen(), (_) async {}),
};

Future<void> _settle(WidgetTester tester) async {
  // Home's countdown ticks forever, so pumpAndSettle never returns.
  for (var i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  // Drift / asset futures resolve outside fake time.
  await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  await tester.pump();
}

Future<void> _capture(
  WidgetTester tester, {
  required String name,
  required String device,
  String locale = 'en',
  bool dark = false,
}) async {
  final (screen, prepare) = _screens[name]!;
  final (size, dpr) = _devices[device]!;
  setView(tester, size, dpr);
  await _register(tester, locale);
  await tester.pumpWidget(storeApp(screen, locale: locale, dark: dark));
  await _settle(tester);
  await prepare(tester);
  await _settle(tester);
  final variant = '${dark ? 'dark' : 'light'}_$locale';
  await writeCapture(tester, 'store/screenshots/$device/${variant}_$name.png');
  await tester.pumpWidget(const SizedBox());
  if (GetIt.I.checkLazySingletonInstanceExists<HomeStore>()) {
    GetIt.I<HomeStore>().stop();
  }
  await GetIt.I.reset();
}

void main() {
  setUpAll(loadAppFonts);

  for (final device in _devices.keys) {
    for (final name in _screens.keys) {
      storeShot('$device $name light en', (tester) async {
        await _capture(tester, name: name, device: device);
      });
    }
    storeShot('$device home light bn', (tester) async {
      await _capture(tester, name: 'home', device: device, locale: 'bn');
    });
    storeShot('$device home dark en', (tester) async {
      await _capture(tester, name: 'home', device: device, dark: true);
    });
  }
}
