import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:productive_muslim/core/l10n/gen/app_localizations.dart';
import 'package:productive_muslim/core/theme/app_theme.dart';
import 'package:productive_muslim/core/utils/result.dart';
import 'package:productive_muslim/features/prayer_times/data/repositories/prayer_day_repository_impl.dart';
import 'package:productive_muslim/features/prayer_times/domain/usecases/get_prayer_day.dart';
import 'package:productive_muslim/features/ramadan/presentation/screens/ramadan_screen.dart';
import 'package:productive_muslim/features/settings/data/datasources/timezone_clock.dart';
import 'package:productive_muslim/features/settings/domain/entities/app_settings.dart';
import 'package:productive_muslim/features/settings/domain/entities/city.dart';
import 'package:productive_muslim/features/settings/domain/entities/location_config.dart';
import 'package:productive_muslim/features/settings/domain/repositories/settings_repository.dart';
import 'package:productive_muslim/features/settings/domain/repositories/zoned_clock.dart';
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

final class _Clock implements ZonedClock {
  DateTime now = DateTime(2026, 3, 1, 3);
  final _real = TimezoneClock();

  @override
  DateTime nowAt(LocationConfig location) => now;

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
  final getPrayerDay = GetPrayerDay(PrayerDayRepositoryImpl(TimezoneClock()));

  setUp(() async {
    settings = SettingsStore(
      GetSettings(_Repo(const AppSettings(location: _dhaka))),
      SaveSettings(_Repo(const AppSettings())),
    );
    await settings.load();
    clock = _Clock();
    GetIt.I
      ..registerSingleton<SettingsStore>(settings)
      ..registerSingleton<ZonedClock>(clock)
      ..registerSingleton(getPrayerDay);
  });

  tearDown(() => GetIt.I.reset());

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
      find.text('Sahri ends in ${hms(sahriOf(1).difference(clock.now))}'),
      findsOneWidget,
    );

    clock.now = DateTime(2026, 3, 1, 12);
    await tester.pump(const Duration(seconds: 1));
    expect(
      find.text('Iftar in ${hms(iftar.difference(clock.now))}'),
      findsOneWidget,
    );

    clock.now = DateTime(2026, 3, 1, 21);
    await tester.pump(const Duration(seconds: 1));
    expect(
      find.text('Sahri ends in ${hms(sahriOf(2).difference(clock.now))}'),
      findsOneWidget,
    );

    // Unmount so the screen's timers are cancelled.
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
