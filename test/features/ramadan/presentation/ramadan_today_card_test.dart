import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:productive_muslim/core/l10n/gen/app_localizations.dart';
import 'package:productive_muslim/core/settings/settings_store.dart';
import 'package:productive_muslim/core/theme/app_theme.dart';
import 'package:productive_muslim/core/utils/hijri_date.dart';
import 'package:productive_muslim/core/utils/result.dart';
import 'package:productive_muslim/features/prayer_times/data/repositories/prayer_day_repository_impl.dart';
import 'package:productive_muslim/features/prayer_times/domain/usecases/get_prayer_day.dart';
import 'package:productive_muslim/features/ramadan/presentation/screens/ramadan_screen.dart';
import 'package:productive_muslim/features/ramadan/presentation/state/eid_announcement_store.dart';
import 'package:productive_muslim/features/settings/data/datasources/timezone_clock.dart';
import 'package:productive_muslim/features/settings/domain/entities/app_settings.dart';
import 'package:productive_muslim/features/settings/domain/entities/city.dart';
import 'package:productive_muslim/features/settings/domain/entities/location_config.dart';
import 'package:productive_muslim/features/settings/domain/repositories/settings_repository.dart';
import 'package:productive_muslim/features/settings/domain/repositories/zoned_clock.dart';
import 'package:productive_muslim/features/settings/domain/usecases/get_settings.dart';
import 'package:productive_muslim/features/settings/domain/usecases/save_settings.dart';

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

final class _Clock implements ZonedClock {
  DateTime now = DateTime(2026, 3, 1, 3);
  final _real = TimezoneClock();

  // Floating wall time, like TimezoneClock.
  @override
  DateTime nowAt(LocationConfig location) => DateTime.utc(
    now.year,
    now.month,
    now.day,
    now.hour,
    now.minute,
    now.second,
  );

  @override
  DateTime instantAt(LocationConfig location, DateTime instant) =>
      _real.instantAt(location, instant);

  @override
  DateTime utcInstantOf(LocationConfig location, DateTime wall) =>
      _real.utcInstantOf(location, wall);
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
  late _Clock clock;
  late EidAnnouncementStore eid;
  late Set<int> savedYears;
  final getPrayerDay = GetPrayerDay(PrayerDayRepositoryImpl(TimezoneClock()));

  setUp(() async {
    settings = SettingsStore(
      GetSettings(_Repo(const AppSettings(location: _dhaka))),
      SaveSettings(_Repo(const AppSettings())),
    );
    await settings.load();
    clock = _Clock();
    savedYears = {};
    eid = EidAnnouncementStore(
      read: () async => savedYears,
      write: (year, {required ended}) async =>
          ended ? savedYears.add(year) : savedYears.remove(year),
    );
    HijriDate.shortRamadanYears = () => eid.years.value;
    GetIt.I
      ..registerSingleton(eid)
      ..registerSingleton<SettingsStore>(settings)
      ..registerSingleton<ZonedClock>(clock)
      ..registerSingleton(getPrayerDay);
  });

  tearDown(() {
    HijriDate.shortRamadanYears = () => const {};
    return GetIt.I.reset();
  });

  String hms(Duration d) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(d.inHours)}:${two(d.inMinutes % 60)}:${two(d.inSeconds % 60)}';
  }

  testWidgets('today card counts to sahri, then iftar, then next sahri', (
    tester,
  ) async {
    // 1 Mar 2026 is inside Ramadan 1447.
    DateTime sahriOf(int day) => getPrayerDay(
      location: _dhaka,
      params: settings.prayerParams.value,
      date: DateTime(2026, 3, day),
    ).valueOrNull!.sahriEnd;
    final iftar = getPrayerDay(
      location: _dhaka,
      params: settings.prayerParams.value,
      date: DateTime(2026, 3),
    ).valueOrNull!.iftar;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const RamadanScreen(),
      ),
    );
    await tester.pump();
    expect(
      find.text(
        'Sahri ends in ${hms(sahriOf(1).difference(clock.nowAt(_dhaka)))}',
      ),
      findsOneWidget,
    );

    clock.now = DateTime(2026, 3, 1, 12);
    await tester.pump(const Duration(seconds: 1));
    expect(
      find.text('Iftar in ${hms(iftar.difference(clock.nowAt(_dhaka)))}'),
      findsOneWidget,
    );

    clock.now = DateTime(2026, 3, 1, 21);
    await tester.pump(const Duration(seconds: 1));
    expect(
      find.text(
        'Sahri ends in ${hms(sahriOf(2).difference(clock.nowAt(_dhaka)))}',
      ),
      findsOneWidget,
    );

    // Unmount so the screen's timers are cancelled.
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('eve of 1 Ramadan: from Maghrib, counts to the first sahri', (
    tester,
  ) async {
    final firstSahri = getPrayerDay(
      location: _dhaka,
      params: settings.prayerParams.value,
      date: DateTime(2026, 2, 18),
    ).valueOrNull!.sahriEnd;
    clock.now = DateTime(2026, 2, 17, 12);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const RamadanScreen(),
      ),
    );
    await tester.pump();
    expect(find.textContaining('Sahri ends in'), findsNothing);

    clock.now = DateTime(2026, 2, 17, 21);
    await tester.pump(const Duration(seconds: 1));
    expect(
      find.text(
        'Sahri ends in ${hms(firstSahri.difference(clock.nowAt(_dhaka)))}',
      ),
      findsOneWidget,
    );
    expect(find.text('Sahri ends tomorrow'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('Eid announced: offered on 29 Ramadan, makes the 30th Eid, '
      'undoable', (tester) async {
    // Tabular dates (no override yet): 30 Ramadan doesn't exist once set.
    DateTime noon(int day) => const HijriDate(
      1447,
      9,
      1,
    ).toGregorian().add(Duration(days: day - 1, hours: 12));
    Future<void> pumpAt(int ramadanDay) async {
      clock.now = noon(ramadanDay);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const RamadanScreen(),
        ),
      );
      await tester.pump();
    }

    const announce = 'Eid announced — Ramadan ended after 29 days';

    // Not offered before the 29th.
    await pumpAt(28);
    expect(find.text(announce), findsNothing);

    await pumpAt(29);
    expect(find.text('Day 29 of 30'), findsOneWidget);
    await tester.tap(find.text(announce));
    await tester.pump();
    expect(savedYears, {1447});
    expect(find.text('Day 29 of 29'), findsOneWidget);
    expect(find.text('Undo'), findsOneWidget);

    // The tabular 30th is now Eid: no roza counter, undo still offered.
    await pumpAt(30);
    expect(find.textContaining('of 30'), findsNothing);
    expect(find.text('Undo'), findsOneWidget);
    await tester.tap(find.text('Undo'));
    await tester.pump();
    expect(savedYears, isEmpty);
    expect(find.text('Day 30 of 30'), findsOneWidget);
    // On the 30th itself the copy asks about today, not "the 30th".
    expect(find.text(announce), findsNothing);
    expect(find.textContaining('Did Ramadan end yesterday'), findsOneWidget);
    await tester.tap(find.text('Mark today as Eid al-Fitr'));
    await tester.pump();
    expect(savedYears, {1447});
    expect(find.textContaining('of 30'), findsNothing);
    expect(find.text('Undo'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
  });
}
