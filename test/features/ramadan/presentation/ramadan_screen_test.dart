import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:productive_muslim/core/l10n/gen/app_localizations.dart';
import 'package:productive_muslim/core/theme/app_theme.dart';
import 'package:productive_muslim/features/prayer_times/data/repositories/prayer_day_repository_impl.dart';
import 'package:productive_muslim/features/prayer_times/domain/usecases/get_prayer_day.dart';
import 'package:productive_muslim/features/ramadan/domain/repositories/fast_log.dart';
import 'package:productive_muslim/features/ramadan/domain/usecases/ramadan_utils.dart';
import 'package:productive_muslim/features/ramadan/presentation/screens/ramadan_screen.dart';
import 'package:productive_muslim/features/ramadan/presentation/state/eid_announcement_store.dart';
import 'package:productive_muslim/features/settings/data/datasources/timezone_clock.dart';
import 'package:productive_muslim/features/settings/domain/entities/app_settings.dart';
import 'package:productive_muslim/features/settings/domain/entities/city.dart';
import 'package:productive_muslim/features/settings/domain/entities/location_config.dart';
import 'package:productive_muslim/features/settings/domain/repositories/zoned_clock.dart';
import 'package:productive_muslim/features/settings/presentation/state/settings_store.dart';
import 'package:productive_muslim/features/share/domain/share_sheet.dart';

import '../../../helpers/settings_fakes.dart';
import '../../../helpers/share_sheet_fake.dart';

const _dhaka = ManualCityLocation(
  City(
    name: 'Dhaka',
    countryCode: 'BD',
    latitude: 23.7104,
    longitude: 90.4074,
    timezone: 'Asia/Dhaka',
  ),
);

/// Real conversions, but "now" is pinned.
final class _FixedClock implements ZonedClock {
  _FixedClock(this.now);

  final DateTime now;
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

void main() {
  setUpAll(TimezoneClock.initialize);
  tearDown(GetIt.I.reset);

  // 1 Mar 2026 is roza 12 of Ramadan 1447; 22:00 is after iftar.
  final evening = DateTime(2026, 3, 1, 22);

  late SettingsStore settings;
  late AppLocalizations l10n;
  late FakeShareSheet share;

  Future<void> pump(WidgetTester tester, DateTime now) async {
    tester.view
      ..physicalSize = const Size(800, 4000)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    settings = await makeSettingsStore(const AppSettings(location: _dhaka));
    final clock = _FixedClock(now);
    GetIt.I
      ..registerSingleton(
        EidAnnouncementStore(
          read: () async => const {},
          write: (_, {required ended}) async {},
        ),
      )
      ..registerSingleton<SettingsStore>(settings)
      ..registerSingleton<ZonedClock>(clock)
      ..registerSingleton<GetPrayerDay>(
        GetPrayerDay(PrayerDayRepositoryImpl(clock)),
      )
      ..registerSingleton<IsDayFasted>(
        (day) => !day.isBefore(DateTime(2026, 2, 18)),
      )
      ..registerSingleton<ShareSheet>(share = FakeShareSheet());
    l10n = await AppLocalizations.delegate.load(const Locale('en'));
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

  // Stops the screen's tickers.
  Future<void> unmount(WidgetTester tester) =>
      tester.pumpWidget(const SizedBox());

  String time(DateTime t) => DateFormat.jm('en').format(t);

  testWidgets('after iftar, today shows tomorrow\'s sahri, relabelled', (
    tester,
  ) async {
    await pump(tester, evening);
    final tomorrow = GetIt.I<GetPrayerDay>()(
      location: _dhaka,
      params: settings.prayerParams.value,
      date: DateTime(2026, 3, 2),
    ).valueOrNull!;
    final card = find.ancestor(
      of: find.text(l10n.sahriEndsTomorrow),
      matching: find.byType(Column),
    );
    expect(card, findsWidgets);
    expect(
      find.descendant(
        of: card.first,
        matching: find.text(time(tomorrow.sahriEnd)),
      ),
      findsOneWidget,
    );
    await unmount(tester);
  });

  testWidgets('before iftar, today\'s sahri keeps its plain label', (
    tester,
  ) async {
    await pump(tester, DateTime(2026, 3, 1, 12));
    expect(find.text(l10n.sahriEndsTomorrow), findsNothing);
    await unmount(tester);
  });

  testWidgets('counter shows days left; table has Day/Date captions', (
    tester,
  ) async {
    await pump(tester, evening);
    final left = RamadanUtils.ramadanLength(1447) - 12;
    expect(find.text(l10n.ramadanDaysLeft(left)), findsOneWidget);
    expect(find.text(l10n.ramadanColDay), findsOneWidget);
    expect(find.text(l10n.ramadanColDate), findsOneWidget);
    expect(find.text(l10n.hijriAdjustLink), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('each table row reads as one sentence; today says so', (
    tester,
  ) async {
    await pump(tester, evening);
    expect(
      find.bySemanticsLabel(RegExp(r'^Roza 12, March 1, Sahri ends .*Today$')),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel(
        RegExp(r'^Roza 13, March 2, Sahri ends .*, Iftar .*M$'),
      ),
      findsOneWidget,
    );
    await unmount(tester);
  });

  testWidgets('share progress hands a PNG of the card to the share sheet', (
    tester,
  ) async {
    await pump(tester, evening);
    await tester.tap(find.text(l10n.ramadanShareProgress));
    // toImage/toByteData finish on the real event loop.
    for (var i = 0; i < 50 && share.images.isEmpty; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump();
    }
    final (png, text) = share.images.single;
    // PNG signature, and the 4:5 1080×1350 header (IHDR width/height).
    expect(png.sublist(0, 4), [0x89, 0x50, 0x4E, 0x47]);
    final ihdr = ByteData.sublistView(png, 16, 24);
    expect((ihdr.getUint32(0), ihdr.getUint32(4)), (1080, 1350));
    expect(
      text,
      l10n.ramadanShareText(
        l10n.rozaDayOf(12, RamadanUtils.ramadanLength(1447)),
      ),
    );
    // The off-screen card is gone again.
    expect(find.text(l10n.ramadanShareHeading.toUpperCase()), findsNothing);
    await unmount(tester);
  });
}
