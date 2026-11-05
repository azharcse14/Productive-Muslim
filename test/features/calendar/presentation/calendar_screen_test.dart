import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:productive_muslim/core/l10n/gen/app_localizations.dart';
import 'package:productive_muslim/core/settings/settings_store.dart';
import 'package:productive_muslim/core/theme/app_theme.dart';
import 'package:productive_muslim/features/calendar/presentation/screens/calendar_screen.dart';
import 'package:productive_muslim/features/prayer_times/data/repositories/prayer_day_repository_impl.dart';
import 'package:productive_muslim/features/prayer_times/domain/usecases/get_prayer_day.dart';
import 'package:productive_muslim/features/settings/data/datasources/timezone_clock.dart';
import 'package:productive_muslim/features/settings/domain/repositories/zoned_clock.dart';

import '../../../helpers/settings_fakes.dart';

void main() {
  group('hijriSpanLabel', () {
    String label(DateTime month, {int offset = 0}) =>
        hijriSpanLabel(month, offsetDays: offset, nameOf: (m) => 'M$m');

    test('a 31-day month touching three Hijri months names all three', () {
      // Tabular: 1 Dec 2035 = 30 Ramadan, 31 Dec = 1 Dhul-Qadah 1457.
      expect(label(DateTime(2035, 12)), 'M9 – M10 – M11 1457');
    });

    test('two months, and a Hijri year boundary', () {
      expect(label(DateTime(2026, 3)), 'M9 – M10 1447');
      // Muharram 1448 starts mid-June 2026.
      expect(label(DateTime(2026, 6)), 'M12 1447 – M1 1448');
    });
  });

  setUpAll(TimezoneClock.initialize);
  tearDown(GetIt.I.reset);

  late SettingsStore settings;
  late AppLocalizations l10n;

  Future<void> pump(WidgetTester tester) async {
    // A small phone: the day cells must still be 48dp targets.
    tester.view
      ..physicalSize = const Size(360, 1400)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    settings = await makeSettingsStore(); // no location
    final clock = TimezoneClock();
    GetIt.I
      ..registerSingleton<SettingsStore>(settings)
      ..registerSingleton<ZonedClock>(clock)
      ..registerSingleton<GetPrayerDay>(
        GetPrayerDay(PrayerDayRepositoryImpl(clock)),
      );
    l10n = await AppLocalizations.delegate.load(const Locale('en'));
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const CalendarScreen(),
      ),
    );
  }

  final today = DateTime.now();
  Finder dayCell(int day) => find.byKey(ValueKey('calendar-day-$day'));

  testWidgets('day cells are at least 48dp wide on a 360dp phone', (
    tester,
  ) async {
    await pump(tester);
    expect(tester.getSize(dayCell(1)).width, greaterThanOrEqualTo(48));
  });

  testWidgets('today is announced as "Today", not as selected', (tester) async {
    await pump(tester);
    final node = tester.getSemantics(dayCell(today.day));
    expect(node.label, endsWith(', ${l10n.todayTab}'));
    expect(node.getSemanticsData().flagsCollection.isSelected, isNot(true));
  });

  testWidgets('day sheet without a location says how to get times', (
    tester,
  ) async {
    await pump(tester);
    await tester.tap(dayCell(1));
    await tester.pumpAndSettle();
    expect(find.text(l10n.calendarSetLocationHint), findsOneWidget);
  });

  testWidgets('a horizontal swipe changes the month', (tester) async {
    await pump(tester);
    String label(DateTime m) => DateFormat.yMMMM('en').format(m);
    expect(find.text(label(today)), findsOneWidget);
    await tester.fling(find.byType(GridView), const Offset(-250, 0), 1000);
    await tester.pumpAndSettle();
    expect(
      find.text(label(DateTime(today.year, today.month + 1))),
      findsOneWidget,
    );
    await tester.fling(find.byType(GridView), const Offset(250, 0), 1000);
    await tester.pumpAndSettle();
    expect(find.text(label(today)), findsOneWidget);
  });

  testWidgets('Hijri date can be adjusted in place, link always shown', (
    tester,
  ) async {
    await pump(tester);
    await tester.tap(find.text(l10n.hijriAdjustLink));
    await tester.pumpAndSettle();
    await tester.tap(
      find.bySemanticsLabel(l10n.a11yIncrease(l10n.settingHijriOffset)),
    );
    await tester.pumpAndSettle();
    expect(settings.hijriOffsetDays.value, 1);

    Navigator.of(tester.element(find.text(l10n.settingHijriOffsetSub))).pop();
    await tester.pumpAndSettle();
    expect(find.textContaining(l10n.hijriAdjustChange), findsOneWidget);
  });
}
