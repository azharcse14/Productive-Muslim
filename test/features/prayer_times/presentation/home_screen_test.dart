import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:productive_muslim/core/l10n/gen/app_localizations.dart';
import 'package:productive_muslim/core/router/routes.dart';
import 'package:productive_muslim/core/theme/app_theme.dart';
import 'package:productive_muslim/core/utils/result.dart';
import 'package:productive_muslim/features/dua_tasbih/presentation/state/dua_store.dart';
import 'package:productive_muslim/features/dua_tasbih/presentation/state/tasbih_store.dart';
import 'package:productive_muslim/features/hadith/domain/entities/hadith.dart';
import 'package:productive_muslim/features/hadith/domain/repositories/hadith_repository.dart';
import 'package:productive_muslim/features/hadith/presentation/screens/hadith_detail_screen.dart';
import 'package:productive_muslim/features/hadith/presentation/state/hadith_store.dart';
import 'package:productive_muslim/features/hadith/presentation/widgets/hadith_card.dart';
import 'package:productive_muslim/features/muhasaba/presentation/state/muhasaba_store.dart';
import 'package:productive_muslim/features/my_mosque/domain/entities/jamaat_config.dart';
import 'package:productive_muslim/features/my_mosque/domain/entities/mosque_schedule.dart';
import 'package:productive_muslim/features/my_mosque/presentation/state/mosque_store.dart';
import 'package:productive_muslim/features/prayer_times/data/repositories/prayer_day_repository_impl.dart';
import 'package:productive_muslim/features/prayer_times/domain/usecases/get_prayer_day.dart';
import 'package:productive_muslim/features/prayer_times/presentation/screens/home_screen.dart';
import 'package:productive_muslim/features/prayer_times/presentation/state/home_store.dart';
import 'package:productive_muslim/features/prayer_times/presentation/widgets/home_muhasaba_card.dart';
import 'package:productive_muslim/features/prayer_times/presentation/widgets/prayer_table.dart';
import 'package:productive_muslim/features/prayer_times/presentation/widgets/quick_actions_row.dart';
import 'package:productive_muslim/features/prayer_times/presentation/widgets/sahri_iftar_card.dart';
import 'package:productive_muslim/features/quran/presentation/state/quran_store.dart';
import 'package:productive_muslim/features/settings/data/datasources/timezone_clock.dart';
import 'package:productive_muslim/features/settings/domain/entities/app_settings.dart';
import 'package:productive_muslim/features/settings/domain/entities/city.dart';
import 'package:productive_muslim/features/settings/domain/entities/location_config.dart';
import 'package:productive_muslim/features/settings/domain/entities/prayer_params.dart';
import 'package:productive_muslim/features/settings/domain/repositories/settings_repository.dart';
import 'package:productive_muslim/features/settings/domain/repositories/zoned_clock.dart';
import 'package:productive_muslim/features/settings/domain/usecases/get_settings.dart';
import 'package:productive_muslim/features/settings/domain/usecases/save_settings.dart';
import 'package:productive_muslim/features/settings/presentation/state/settings_store.dart';
import 'package:productive_muslim/shared/widgets/countdown_card.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import '../../../helpers/content_fakes.dart';
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

Future<void> _register({
  required bool withLocation,
  DateTime? now,
  HadithStore? hadith,
}) async {
  SharedPreferencesAsyncPlatform.instance =
      InMemorySharedPreferencesAsync.empty();
  TimezoneClock.initialize();
  _clock = _FakeClock(now ?? DateTime(2026, 6, 12, 4)); // inside fajr waqt
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
  final quranStore = await makeQuranStore();
  final duaStore = await makeDuaStore();
  final tasbihStore = await makeTasbihStore();
  GetIt.I
    ..registerSingleton<SettingsStore>(settingsStore)
    ..registerSingleton<MosqueStore>(mosqueStore)
    ..registerSingleton<MuhasabaStore>(muhasabaStore)
    ..registerSingleton<QuranStore>(quranStore)
    ..registerSingleton<DuaStore>(duaStore)
    ..registerSingleton<TasbihStore>(tasbihStore)
    ..registerFactory<HomeStore>(
      () => HomeStore(
        getPrayerDay: GetPrayerDay(PrayerDayRepositoryImpl(_clock)),
        clock: _clock,
        settings: settingsStore,
        mosque: mosqueStore,
      ),
    );
  if (hadith != null) {
    GetIt.I.registerSingleton<HadithStore>(hadith);
  }
}

final class _OneHadithRepo implements HadithRepository {
  @override
  Future<Result<List<Hadith>>> all() async => const Result.success([
        Hadith(
          id: 'h42',
          topic: 'intention',
          grade: 'sahih',
          arabic: '',
          en: 'Actions are judged by intentions.',
          bn: '',
          narrator: 'Umar',
          reference: 'Bukhari 1',
        ),
      ]);
}

/// Tall viewport so the whole (lazy) home list is laid out at once.
void _tall(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 5000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
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
      // With no jamaat configured, each of the 5 rows shows an em-dash
      // placeholder and the table carries a single "Set jamaat" CTA at its foot.
      expect(find.text('—'), findsNWidgets(5));
      expect(find.text('Set jamaat time'), findsOneWidget);
      // The meal row sits below the fold now (cards were added above it).
      await tester.scrollUntilVisible(
        find.text('Sahri ends'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Sahri ends'), findsOneWidget);
      expect(find.text('Iftar'), findsOneWidget);
    });

    testWidgets('shows the forbidden and nafl times card', (tester) async {
      await _register(withLocation: true);
      await tester.pumpWidget(_app());
      await tester.pump();
      // The card sits below the fold, so scroll it into view first.
      await tester.scrollUntilVisible(
        find.text('Forbidden times'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Forbidden times'), findsOneWidget);
      expect(find.text('Nafl times'), findsOneWidget);
      expect(find.text('After sunrise'), findsOneWidget);
      expect(find.text('Ishraq'), findsOneWidget);
      expect(find.text('Tahajjud'), findsOneWidget);
    });

    testWidgets('shows the minimal muhasaba track card', (tester) async {
      await _register(withLocation: true);
      await tester.pumpWidget(_app());
      await tester.pump();
      // The card sits below the fold (quick actions + hero are above it).
      await tester.scrollUntilVisible(
        find.text('Muhasaba'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      // Title + completion ring + done/total count, all in one compact card.
      expect(find.text('Muhasaba'), findsOneWidget);
      expect(find.text('0%'), findsOneWidget);
      // 10 seeded default trackers, none done yet.
      expect(find.text('0/10 done'), findsOneWidget);
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
      // Checkable circles center an AnimatedContainer in a 48dp hit box;
      // locked ones center a clock icon. At 4am only Fajr's waqt has started,
      // so it's the lone checkable one; the later prayers are locked.
      final checks = find.byWidgetPredicate(
        (w) =>
            w is InkWell &&
            w.customBorder is CircleBorder &&
            w.child is Center &&
            (w.child! as Center).child is AnimatedContainer,
      );
      expect(checks, findsOneWidget);
      expect(find.byIcon(Icons.schedule), findsNWidgets(4));
      // Tapping a locked prayer explains why with a toast.
      await tester.tap(find.byIcon(Icons.schedule).first);
      await tester.pump();
      expect(find.text("This prayer's time hasn't started yet"),
          findsOneWidget);
      await tester.tap(checks.first);
      await tester.pump();
      expect(_muhasabaRepo.entries_[('salah_fajr', 20260612)], 1);
      // The summary card's count reflects the new done item live; it sits below
      // the fold now, so scroll it into view to confirm.
      await tester.scrollUntilVisible(
        find.text('1/10 done'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('1/10 done'), findsOneWidget);
      // Scroll back up to the table and tap again to toggle off.
      await tester.scrollUntilVisible(
        checks,
        -300,
        scrollable: find.byType(Scrollable).first,
      );
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
      // Fajr + Maghrib have a jamaat time; the other 3 rows (dhuhr/asr/isha)
      // show the em-dash placeholder. The "Set jamaat" CTA stays at the foot.
      expect(find.text('—'), findsNWidgets(3));
      expect(find.text('Set jamaat time'), findsOneWidget);
      // Maghrib got the default +5 offset from addProfile.
      expect(find.textContaining('4:30'), findsWidgets);
    });

    testWidgets('auto schedule shows the scheduled mosque with an Auto badge',
        (tester) async {
      await _register(withLocation: true);
      final mosque = GetIt.I<MosqueStore>();
      final office = await mosque.addProfile('Office');
      final home = await mosque.addProfile('Home');
      await mosque.setMode(ScheduleMode.auto);
      // An all-day rule makes Office the scheduled mosque right now.
      await mosque.addRule(
        MosqueRule(
          mosqueId: office.id,
          start: const ClockTime(0, 0),
          end: const ClockTime(0, 0),
        ),
      );
      await mosque.setDefaultMosque(home.id);
      await tester.pumpWidget(_app());
      await tester.pump();
      // The table's mosque strip names the scheduled mosque with an Auto chip.
      expect(find.text('Office'), findsOneWidget);
      expect(find.text('Auto'), findsOneWidget);
    });

    testWidgets('qibla is not a quick action (header + countdown chip only)',
        (tester) async {
      await _register(withLocation: true);
      await tester.pumpWidget(_app());
      await tester.pump();
      final row = tester.widget<QuickActionsRow>(find.byType(QuickActionsRow));
      expect(row.actions, hasLength(4));
      expect(row.actions.map((a) => a.label), isNot(contains('Qibla')));
    });

    testWidgets('outside Ramadan, sahri & iftar sits right under the table',
        (tester) async {
      _tall(tester);
      await _register(withLocation: true); // 12 Jun 2026: Dhul-Hijjah
      await tester.pumpWidget(_app());
      await tester.pump();
      final table = tester.getRect(find.byType(PrayerTable));
      final meal = tester.getRect(find.byType(SahriIftarCard));
      final muhasaba = tester.getRect(find.byType(HomeMuhasabaCard));
      expect(meal.top, greaterThan(table.bottom));
      expect(meal.bottom, lessThan(muhasaba.top));
    });

    testWidgets('in Ramadan, sahri & iftar sits right under the countdown',
        (tester) async {
      _tall(tester);
      // 20 Feb 2026, 10:00 = 3 Ramadan 1447 (tabular).
      await _register(withLocation: true, now: DateTime(2026, 2, 20, 10));
      await tester.pumpWidget(_app());
      await tester.pump();
      final countdown = tester.getRect(find.byType(CountdownCard));
      final meal = tester.getRect(find.byType(SahriIftarCard));
      final actions = tester.getRect(find.byType(QuickActionsRow));
      expect(meal.top, greaterThan(countdown.bottom));
      expect(meal.bottom, lessThan(actions.top));
    });

    testWidgets('hadith of the day opens that hadith', (tester) async {
      _tall(tester);
      final hadith = HadithStore(_OneHadithRepo());
      await _register(withLocation: true, hadith: hadith);
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            name: Routes.hadith.name,
            path: Routes.hadith.path,
            builder: (context, state) => const SizedBox(),
            routes: [
              GoRoute(
                name: Routes.hadithItem.name,
                path: Routes.hadithItem.path,
                builder: (context, state) =>
                    HadithDetailScreen(id: state.pathParameters['id']!),
              ),
            ],
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        MaterialApp.router(
          theme: AppTheme.light(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      );
      // The home ticks every second, so it never settles; pump instead.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.byType(HadithCard));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.byType(HadithDetailScreen), findsOneWidget);
      expect(router.state.uri.path, '/hadith/item/h42');
      expect(find.text('Intention & sincerity'), findsOneWidget);
      expect(find.text('Actions are judged by intentions.'), findsOneWidget);
    });
  });
}
