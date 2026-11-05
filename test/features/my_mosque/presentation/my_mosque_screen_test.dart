import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:productive_muslim/core/l10n/gen/app_localizations.dart';
import 'package:productive_muslim/core/theme/app_theme.dart';
import 'package:productive_muslim/core/utils/wall_time.dart';
import 'package:productive_muslim/features/my_mosque/domain/entities/jamaat_config.dart';
import 'package:productive_muslim/features/my_mosque/domain/entities/mosque_profile.dart';
import 'package:productive_muslim/features/my_mosque/domain/entities/mosque_schedule.dart';
import 'package:productive_muslim/features/my_mosque/domain/entities/mosque_state.dart';
import 'package:productive_muslim/features/my_mosque/domain/usecases/get_mosque_state.dart';
import 'package:productive_muslim/features/my_mosque/domain/usecases/resolve_active_mosque.dart';
import 'package:productive_muslim/features/my_mosque/domain/usecases/save_mosque_state.dart';
import 'package:productive_muslim/features/my_mosque/presentation/screens/my_mosque_screen.dart';
import 'package:productive_muslim/features/my_mosque/presentation/state/mosque_store.dart';
import 'package:productive_muslim/features/my_mosque/presentation/widgets/mosque_schedule_section.dart';
import 'package:productive_muslim/features/my_mosque/presentation/widgets/prayer_jamaat_card.dart';
import 'package:productive_muslim/features/prayer_times/data/repositories/prayer_day_repository_impl.dart';
import 'package:productive_muslim/features/prayer_times/domain/usecases/get_prayer_day.dart';
import 'package:productive_muslim/features/prayer_times/presentation/state/home_store.dart';
import 'package:productive_muslim/features/settings/data/datasources/timezone_clock.dart';
import 'package:productive_muslim/features/settings/domain/entities/app_settings.dart';
import 'package:productive_muslim/features/settings/domain/entities/city.dart';
import 'package:productive_muslim/features/settings/domain/entities/location_config.dart';
import 'package:productive_muslim/features/settings/domain/entities/prayer_params.dart';
import 'package:productive_muslim/features/settings/domain/repositories/zoned_clock.dart';

import '../../../helpers/home_store_fakes.dart';
import '../../../helpers/layout_matrix.dart';
import '../../../helpers/mosque_fakes.dart';
import '../../../helpers/settings_fakes.dart';

Widget _app() => MaterialApp(
  theme: AppTheme.light(),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: const MyMosqueScreen(),
);

const _winter = MosqueSeason(
  mosqueId: 'b',
  start: (month: 11, day: 1),
  end: (month: 2, day: 28),
);

const _dhaka = ManualCityLocation(
  City(
    name: 'Dhaka',
    countryCode: 'BD',
    latitude: 23.7104,
    longitude: 90.4074,
    timezone: 'Asia/Dhaka',
  ),
);

/// The location's wall clock pinned to [now]; conversions are real.
final class _FixedClock implements ZonedClock {
  _FixedClock(this.now);

  final DateTime now;
  final _real = TimezoneClock();

  @override
  DateTime nowAt(LocationConfig location) => now.floating;

  @override
  DateTime instantAt(LocationConfig location, DateTime instant) =>
      _real.instantAt(location, instant);

  @override
  DateTime utcInstantOf(LocationConfig location, DateTime wall) =>
      _real.utcInstantOf(location, wall);
}

void main() {
  setUpAll(TimezoneClock.initialize);

  late InMemoryMosqueRepository repo;

  Future<void> register([MosqueState initial = const MosqueState()]) async {
    final (store, r) = await makeMosqueStore(initial);
    repo = r;
    GetIt.I.registerSingleton<MosqueStore>(store);
  }

  tearDown(() => GetIt.I.reset());

  group('MyMosqueScreen', () {
    testWidgets('empty state offers adding a profile', (tester) async {
      await register();
      await tester.pumpWidget(_app());
      expect(find.text('Add profile'), findsOneWidget);
    });

    testWidgets('unreadable storage offers a retry, not the add state', (
      tester,
    ) async {
      final repo = InMemoryMosqueRepository()..failLoad = true;
      final store = MosqueStore(GetMosqueState(repo), SaveMosqueState(repo));
      await store.load();
      GetIt.I.registerSingleton<MosqueStore>(store);
      await tester.pumpWidget(_app());
      expect(find.text('Add profile'), findsNothing);
      repo.failLoad = false;
      await tester.tap(find.text('Try again'));
      await tester.pump();
      expect(find.text('Add profile'), findsOneWidget);
    });

    testWidgets('add-profile dialog creates and activates a profile', (
      tester,
    ) async {
      // Tall surface so the Maghrib card is laid out.
      tester.view.physicalSize = const Size(1200, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await register();
      await tester.pumpWidget(_app());
      await tester.tap(find.text('Add profile'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Home Mosque');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(repo.stored.profiles.single.name, 'Home Mosque');
      expect(repo.stored.activeId, repo.stored.profiles.single.id);
      // Per-prayer cards now visible; Maghrib default offset shown.
      expect(find.text('Maghrib'), findsOneWidget);
      expect(find.textContaining('5 min after waqt starts'), findsOneWidget);
    });

    testWidgets('renders all five prayer cards with mode segments', (
      tester,
    ) async {
      // Tall surface so the schedule section + all five cards fit at once.
      tester.view.physicalSize = const Size(1200, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await register(
        const MosqueState(
          profiles: [MosqueProfile(id: 'a', name: 'Home')],
          activeId: 'a',
        ),
      );
      await tester.pumpWidget(_app());
      for (final p in ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha']) {
        expect(find.text(p), findsOneWidget);
      }
      expect(find.text('None'), findsNWidgets(5));
      expect(find.text('Offset'), findsNWidgets(5));
      expect(find.text('Fixed'), findsNWidgets(5));
      expect(find.byType(MosqueScheduleSection), findsOneWidget);
      expect(find.byType(PrayerJamaatCard), findsNWidgets(5));
    });

    testWidgets('choosing Offset persists a default 15-minute entry', (
      tester,
    ) async {
      await register(
        const MosqueState(
          profiles: [MosqueProfile(id: 'a', name: 'Home')],
          activeId: 'a',
        ),
      );
      await tester.pumpWidget(_app());
      await tester.tap(find.text('Offset').first); // fajr row
      await tester.pump();
      expect(
        repo.stored.profiles.single.entries[Prayer.fajr],
        const OffsetJamaat(Duration(minutes: 15)),
      );
    });

    testWidgets('choosing None clears the jamaat with an undo', (tester) async {
      await register(
        const MosqueState(
          profiles: [
            MosqueProfile(
              id: 'a',
              name: 'Home',
              entries: {Prayer.fajr: OffsetJamaat(Duration(minutes: 20))},
            ),
          ],
          activeId: 'a',
        ),
      );
      await tester.pumpWidget(_app());
      await tester.tap(find.text('None').first); // fajr row
      await tester.pump();
      expect(
        repo.stored.profiles.single.entries[Prayer.fajr],
        const NoJamaat(),
      );
      expect(find.text('Fajr jamaat removed'), findsOneWidget);
      await tester.pump(const Duration(seconds: 1)); // snackbar in
      await tester.tap(find.text('Undo'));
      await tester.pump();
      expect(
        repo.stored.profiles.single.entries[Prayer.fajr],
        const OffsetJamaat(Duration(minutes: 20)),
      );
    });

    testWidgets('mode segments and the minute value name their prayer', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await register(
        const MosqueState(
          profiles: [
            MosqueProfile(
              id: 'a',
              name: 'Home',
              entries: {Prayer.asr: OffsetJamaat(Duration(minutes: 10))},
            ),
          ],
          activeId: 'a',
        ),
      );
      await tester.pumpWidget(_app());
      expect(find.bySemanticsLabel('Fajr: None'), findsOneWidget);
      expect(find.bySemanticsLabel('Asr Jamaat: 10 min'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('jamaat card: Maghrib offset defaults to +5, steps by 5', (
      tester,
    ) async {
      JamaatEntry? changed;
      Widget card(JamaatEntry entry) => MaterialApp(
        theme: AppTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: PrayerJamaatCard(
            prayer: Prayer.maghrib,
            entry: entry,
            formatTime: (t) => '${t.hour}:${t.minute}',
            onChanged: (e) => changed = e,
            onPickTime: () {},
            preview: '→ 6:55 PM today',
            warning: 'Outside today',
          ),
        ),
      );
      await tester.pumpWidget(card(const NoJamaat()));
      await tester.tap(find.text('Offset'));
      expect(changed, const OffsetJamaat(Duration(minutes: 5)));

      await tester.pumpWidget(card(const OffsetJamaat(Duration(minutes: 5))));
      expect(find.text('→ 6:55 PM today'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.add));
      expect(changed, const OffsetJamaat(Duration(minutes: 10)));
      expect(find.text('Outside today'), findsOneWidget);
    });

    testWidgets('profile switcher chips change the active profile', (
      tester,
    ) async {
      await register(
        const MosqueState(
          profiles: [
            MosqueProfile(id: 'a', name: 'HomeM'),
            MosqueProfile(id: 'b', name: 'WorkM'),
          ],
          activeId: 'a',
        ),
      );
      await tester.pumpWidget(_app());
      await tester.tap(find.text('WorkM'));
      await tester.pump();
      expect(repo.stored.activeId, 'b');
    });

    testWidgets('choosing Fixed opens the picker; cancel saves nothing', (
      tester,
    ) async {
      await register(
        const MosqueState(
          profiles: [MosqueProfile(id: 'a', name: 'Home')],
          activeId: 'a',
        ),
      );
      await tester.pumpWidget(_app());
      await tester.tap(find.text('Fixed').first); // fajr row
      await tester.pumpAndSettle();
      expect(find.byType(TimePickerDialog), findsOneWidget);
      expect(repo.saves, 0);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(repo.saves, 0);
      expect(repo.stored.profiles.single.entries[Prayer.fajr], isNull);
    });

    testWidgets('adds, edits and removes a seasonal rule', (tester) async {
      tester.view.physicalSize = const Size(1200, 3200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await register(
        const MosqueState(
          profiles: [
            MosqueProfile(id: 'a', name: 'Summer'),
            MosqueProfile(id: 'b', name: 'Winter'),
          ],
          activeId: 'a',
          mode: ScheduleMode.auto,
          defaultId: 'a',
        ),
      );
      await tester.pumpWidget(_app());
      expect(find.textContaining('Active now:'), findsOneWidget);

      await tester.tap(find.text('Add season'));
      await tester.pumpAndSettle();
      // On the default mosque, so adding switches nothing until edited.
      expect(repo.stored.seasons, const [
        MosqueSeason(
          mosqueId: 'a',
          start: (month: 11, day: 1),
          end: (month: 2, day: 29),
        ),
      ]);

      // End month Feb → Mar keeps day 29.
      await tester.tap(find.text('Feb'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Mar').last);
      await tester.pumpAndSettle();
      expect(repo.stored.seasons.single.end, (month: 3, day: 29));

      await tester.tap(find.byTooltip('Delete').last);
      await tester.pump();
      expect(repo.stored.seasons, isEmpty);
      expect(find.text('Season removed'), findsOneWidget);
      await tester.pump(const Duration(seconds: 1)); // snackbar in
      await tester.tap(find.text('Undo'));
      await tester.pump();
      expect(repo.stored.seasons.single.end, (month: 3, day: 29));
    });

    testWidgets("clearing the Jumu'ah time offers an undo", (tester) async {
      tester.view.physicalSize = const Size(1200, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await register(
        const MosqueState(
          profiles: [
            MosqueProfile(id: 'a', name: 'Home', jumuah: ClockTime(13, 30)),
          ],
          activeId: 'a',
        ),
      );
      await tester.pumpWidget(_app());
      await tester.tap(find.byTooltip("Remove Jumu'ah time"));
      await tester.pump();
      expect(repo.stored.profiles.single.jumuah, isNull);
      await tester.pump(const Duration(seconds: 1)); // snackbar in
      await tester.tap(find.text('Undo'));
      await tester.pump();
      expect(repo.stored.profiles.single.jumuah, const ClockTime(13, 30));
    });

    testWidgets('says which mosque is active now and why', (tester) async {
      Future<void> pumpAt(DateTime now, {String? defaultId = 'a'}) {
        final state = MosqueState(
          profiles: const [
            MosqueProfile(id: 'a', name: 'Summer'),
            MosqueProfile(id: 'b', name: 'Winter'),
          ],
          mode: ScheduleMode.auto,
          defaultId: defaultId,
          seasons: const [_winter],
        );
        return tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light(),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: SingleChildScrollView(
                child: MosqueScheduleSection(
                  state: state,
                  formatTime: (t) => '$t',
                  onModeChanged: (_) {},
                  onAddRule: () {},
                  onRemoveRule: (_) {},
                  onRuleChanged: (_, _) {},
                  onDefaultChanged: (_) {},
                  onPickRuleTime: (_, {required isStart}) {},
                  resolution: resolveActiveMosque(state, now),
                  onAddSeason: () {},
                  onSeasonChanged: (_, _) {},
                ),
              ),
            ),
          ),
        );
      }

      await pumpAt(DateTime(2026, 12, 1, 10));
      expect(
        find.text('Active now: Winter (season Nov 1 – Feb 28)'),
        findsOneWidget,
      );
      await pumpAt(DateTime(2026, 6, 1, 10));
      expect(find.text('Active now: Summer (default mosque)'), findsOneWidget);
      await pumpAt(DateTime(2026, 6, 1, 10), defaultId: null);
      expect(
        find.text('Active now: Summer (no rule, season or default applies)'),
        findsOneWidget,
      );
    });

    testHomeWidgets('"active now" follows the location clock, not the device', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 3200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await register(
        const MosqueState(
          profiles: [
            MosqueProfile(id: 'a', name: 'Summer'),
            MosqueProfile(id: 'b', name: 'Winter'),
          ],
          activeId: 'a',
          mode: ScheduleMode.auto,
          defaultId: 'a',
          // Only the location's date (Jul 4), whatever the device date.
          seasons: [
            MosqueSeason(
              mosqueId: 'b',
              start: (month: 7, day: 4),
              end: (month: 7, day: 4),
            ),
          ],
        ),
      );
      final settings = await makeSettingsStore(
        const AppSettings(location: _dhaka),
      );
      final clock = _FixedClock(DateTime(2026, 7, 4, 10));
      GetIt.I.registerLazySingleton<HomeStore>(
        () => HomeStore(
          getPrayerDay: GetPrayerDay(PrayerDayRepositoryImpl(clock)),
          clock: clock,
          settings: settings,
          mosque: GetIt.I<MosqueStore>(),
        ),
      );
      await tester.pumpWidget(_app());
      expect(
        find.text('Active now: Winter (season Jul 4 – Jul 4)'),
        findsOneWidget,
      );
    });

    testWidgets('long-pressing a profile chip renames it', (tester) async {
      await register(
        const MosqueState(
          profiles: [MosqueProfile(id: 'a', name: 'HomeM')],
          activeId: 'a',
        ),
      );
      await tester.pumpWidget(_app());
      await tester.longPress(find.text('HomeM'));
      await tester.pumpAndSettle();
      expect(find.text('Rename mosque'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'Masjid');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(repo.stored.profiles.single.name, 'Masjid');
    });

    testWidgets('keyboard Done in the name dialog saves like Save', (
      tester,
    ) async {
      await register();
      await tester.pumpWidget(_app());
      await tester.tap(find.text('Add profile'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), ' Masjid ');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(repo.stored.profiles.single.name, 'Masjid');
    });
  });

  layoutMatrix(
    'MyMosqueScreen empty',
    arrange: (_) => register(),
    screen: () => const MyMosqueScreen(),
  );
  layoutMatrix(
    'MyMosqueScreen with profiles',
    arrange: (_) => register(
      const MosqueState(
        profiles: [
          MosqueProfile(
            id: 'a',
            name: 'Baitul Mukarram National Mosque',
            entries: {
              Prayer.fajr: FixedJamaat(ClockTime(5, 20)),
              Prayer.maghrib: OffsetJamaat(Duration(minutes: 5)),
            },
            jumuah: ClockTime(13, 30),
          ),
          MosqueProfile(id: 'b', name: 'Home'),
        ],
        activeId: 'a',
      ),
    ),
    screen: () => const MyMosqueScreen(),
  );
}
