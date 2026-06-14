import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:qalbee/core/l10n/gen/app_localizations.dart';
import 'package:qalbee/core/theme/app_theme.dart';
import 'package:qalbee/core/utils/result.dart';
import 'package:qalbee/features/muhasaba/presentation/state/muhasaba_store.dart';
import 'package:qalbee/features/my_mosque/domain/entities/jamaat_config.dart';
import 'package:qalbee/features/my_mosque/presentation/state/mosque_store.dart';
import 'package:qalbee/features/prayer_times/data/repositories/prayer_day_repository_impl.dart';
import 'package:qalbee/features/prayer_times/domain/usecases/get_prayer_day.dart';
import 'package:qalbee/features/prayer_times/presentation/screens/home_screen.dart';
import 'package:qalbee/features/prayer_times/presentation/state/home_store.dart';
import 'package:qalbee/features/settings/data/datasources/timezone_clock.dart';
import 'package:qalbee/features/settings/domain/entities/app_settings.dart';
import 'package:qalbee/features/settings/domain/entities/city.dart';
import 'package:qalbee/features/settings/domain/entities/location_config.dart';
import 'package:qalbee/features/settings/domain/entities/prayer_params.dart';
import 'package:qalbee/features/settings/domain/repositories/settings_repository.dart';
import 'package:qalbee/features/settings/domain/repositories/zoned_clock.dart';
import 'package:qalbee/features/settings/domain/usecases/get_settings.dart';
import 'package:qalbee/features/settings/domain/usecases/save_settings.dart';
import 'package:qalbee/features/settings/presentation/state/settings_store.dart';

import '../../../helpers/mosque_fakes.dart';
import '../../../helpers/muhasaba_fakes.dart';

final class _InMemorySettingsRepo implements SettingsRepository {
  _InMemorySettingsRepo(this.stored);

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

/// Controllable wall clock so countdown ticks are deterministic in tests.
final class _FakeClock implements ZonedClock {
  _FakeClock(this.current);

  DateTime current;
  final _real = TimezoneClock();

  @override
  DateTime nowAt(LocationConfig location) => current;

  @override
  DateTime instantAt(LocationConfig location, DateTime instant) =>
      _real.instantAt(location, instant);

  @override
  DateTime utcInstantOf(LocationConfig location, DateTime wall) =>
      _real.utcInstantOf(location, wall);
}

late _FakeClock _clock;
late InMemoryMuhasabaRepository _muhasabaRepo;

Future<void> _register({required bool withLocation}) async {
  TimezoneClock.initialize();
  _clock = _FakeClock(DateTime(2026, 6, 12, 4)); // inside fajr waqt
  final settingsRepo = _InMemorySettingsRepo(
    AppSettings(location: withLocation ? _dhaka : null),
  );
  final settingsStore =
      SettingsStore(GetSettings(settingsRepo), SaveSettings(settingsRepo));
  await settingsStore.load();
  final (mosqueStore, _) = await makeMosqueStore();
  final (muhasabaStore, muhasabaRepo) =
      await makeMuhasabaStore(now: () => _clock.current);
  _muhasabaRepo = muhasabaRepo;
  GetIt.I
    ..registerSingleton<SettingsStore>(settingsStore)
    ..registerSingleton<MosqueStore>(mosqueStore)
    ..registerSingleton<MuhasabaStore>(muhasabaStore)
    ..registerFactory<HomeStore>(
      () => HomeStore(
        getPrayerDay: GetPrayerDay(PrayerDayRepositoryImpl(_clock)),
        clock: _clock,
        settings: settingsStore,
        mosque: mosqueStore,
      ),
    );
}

Widget _app() => MaterialApp(
      theme: AppTheme.light(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const HomeScreen(),
    );

void main() {
  tearDown(() => GetIt.I.reset());

  group('HomeScreen', () {
    testWidgets('without a location shows the setup empty state',
        (tester) async {
      await _register(withLocation: false);
      await tester.pumpWidget(_app());
      await tester.pump();
      expect(find.text('Where are you?'), findsOneWidget);
      expect(find.text('Set location'), findsOneWidget);
    });

    testWidgets('with a location renders header, table and meal row',
        (tester) async {
      await _register(withLocation: true);
      await tester.pumpWidget(_app());
      await tester.pump();
      expect(find.text('Dhaka, BD'), findsOneWidget);
      expect(find.text('Fajr'), findsOneWidget);
      expect(find.text('Dhuhr'), findsOneWidget);
      expect(find.text('Asr'), findsOneWidget);
      expect(find.text('Maghrib'), findsOneWidget);
      expect(find.text('Isha'), findsOneWidget);
      // Sunrise was removed from the table (still in the countdown footer).
      expect(find.text('Sunrise'), findsNothing);
      expect(find.text('Sahri ends'), findsOneWidget);
      expect(find.text('Iftar'), findsOneWidget);
      // Unconfigured jamaat shows the quiet affordance on all 5 rows.
      expect(find.text('Set jamaat'), findsNWidgets(5));
    });

    testWidgets('countdown numeral ticks with the clock', (tester) async {
      await _register(withLocation: true);
      await tester.pumpWidget(_app());
      await tester.pump();
      final numeral = find.textContaining(RegExp(r'^\d{2}:\d{2}:\d{2}$'));
      expect(numeral, findsOneWidget);
      final before = tester.widget<Text>(numeral).data;
      _clock.current = _clock.current.add(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));
      final after = tester.widget<Text>(numeral).data;
      expect(after, isNot(before));
    });

    testWidgets('countdown shows fajr ending at sunrise (calm waqt-end)',
        (tester) async {
      await _register(withLocation: true);
      await tester.pumpWidget(_app());
      await tester.pump();
      expect(find.text('FAJR ENDS IN'), findsOneWidget);
    });

    testWidgets('hijri date appears in the header line', (tester) async {
      await _register(withLocation: true);
      await tester.pumpWidget(_app());
      await tester.pump();
      // 12 Jun 2026 ≈ Dhul-Hijjah 1447 in the tabular calendar.
      expect(find.textContaining('Dhul-Hijjah'), findsOneWidget);
    });

    testWidgets('prayer check writes a salah entry to muhasaba',
        (tester) async {
      await _register(withLocation: true);
      await tester.pumpWidget(_app());
      await tester.pump();
      // The check circles are the only circular InkWells in the table.
      final checks = find.byWidgetPredicate(
        (w) => w is InkWell && w.customBorder is CircleBorder,
      );
      expect(checks, findsNWidgets(5));
      await tester.tap(checks.first);
      await tester.pump();
      expect(_muhasabaRepo.entries_[('salah_fajr', 20260612)], 1);
      // Tapping again toggles off.
      await tester.tap(checks.first);
      await tester.pump();
      expect(
        _muhasabaRepo.entries_.containsKey(('salah_fajr', 20260612)),
        isFalse,
      );
    });

    testWidgets(
        'configured jamaat shows in the table and drives a jamaat countdown',
        (tester) async {
      await _register(withLocation: true);
      final mosque = GetIt.I<MosqueStore>();
      final profile = await mosque.addProfile('Home');
      // Fajr waqt at 04:00; jamaat at 04:30 → countdown targets jamaat.
      await mosque.setEntry(
        profile.id,
        Prayer.fajr,
        const FixedJamaat(ClockTime(4, 30)),
      );
      await tester.pumpWidget(_app());
      await tester.pump();
      expect(find.text('JAMAAT IN'), findsOneWidget);
      // Fajr row shows the jamaat time instead of "Set jamaat".
      expect(find.text('Set jamaat'), findsNWidgets(3)); // dhuhr/asr/isha
      // Maghrib got the default +5 offset from addProfile.
      expect(find.textContaining('4:30'), findsWidgets);
    });
  });
}
