import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:productive_muslim/core/l10n/gen/app_localizations.dart';
import 'package:productive_muslim/core/theme/app_theme.dart';
import 'package:productive_muslim/features/prayer_times/domain/entities/prayer_day.dart';
import 'package:productive_muslim/features/prayer_times/presentation/widgets/prayer_table.dart';
import 'package:productive_muslim/features/settings/domain/entities/prayer_params.dart';

final _day = PrayerDay(
  ishaYesterday: DateTime(2026, 6, 11, 20, 15),
  fajr: DateTime(2026, 6, 12, 3, 45),
  sunrise: DateTime(2026, 6, 12, 5, 10),
  dhuhr: DateTime(2026, 6, 12, 12),
  asr: DateTime(2026, 6, 12, 16, 30),
  maghrib: DateTime(2026, 6, 12, 18, 45),
  isha: DateTime(2026, 6, 12, 20, 15),
  fajrTomorrow: DateTime(2026, 6, 13, 3, 45),
);

void main() {
  late List<Prayer> toggled;
  late List<Prayer> rowTaps;
  late List<Prayer> lockedTaps;

  Future<void> pump(WidgetTester tester, {bool dense = false}) async {
    toggled = [];
    rowTaps = [];
    lockedTaps = [];
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: PrayerTable(
            day: _day,
            activePrayer: Prayer.dhuhr,
            jamaatTimes: const {},
            formatTime: (t) => '${t.hour}:${t.minute}',
            dense: dense,
            locked: const {Prayer.maghrib, Prayer.isha},
            onTogglePrayed: toggled.add,
            onLockedTap: lockedTaps.add,
            onPrayerTap: rowTaps.add,
          ),
        ),
      ),
    );
  }

  for (final dense in [false, true]) {
    testWidgets('check and locked icon have ≥48dp targets (dense: $dense)', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pump(tester, dense: dense);
      final check = find.bySemanticsLabel('Mark Asr as prayed');
      expect(check, findsOneWidget);
      expect(tester.getSize(check).width, greaterThanOrEqualTo(48));
      expect(tester.getSize(check).height, greaterThanOrEqualTo(48));
      final lock = find.bySemanticsLabel("Isha: its time hasn't started yet");
      expect(lock, findsOneWidget);
      expect(tester.getSize(lock).width, greaterThanOrEqualTo(48));
      expect(tester.getSize(lock).height, greaterThanOrEqualTo(48));
      // Its own node: the row's label no longer swallows the check.
      expect(tester.getSemantics(check).label, 'Mark Asr as prayed');
      handle.dispose();
    });
  }

  testWidgets('a tap near the edge of the check hits the check, not the row', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pump(tester);
    final box = tester.getRect(find.bySemanticsLabel('Mark Asr as prayed'));
    // 20dp from centre: outside the 26dp visual, inside the 48dp target.
    await tester.tapAt(box.center.translate(-20, 0));
    expect(toggled, [Prayer.asr]);
    expect(rowTaps, isEmpty);
    await tester.tapAt(
      tester
          .getRect(find.bySemanticsLabel("Isha: its time hasn't started yet"))
          .center
          .translate(0, 20),
    );
    expect(lockedTaps, [Prayer.isha]);
    expect(rowTaps, isEmpty);
    handle.dispose();
  });

  testWidgets('an untracked prayer shows no check', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: PrayerTable(
            day: _day,
            activePrayer: Prayer.dhuhr,
            jamaatTimes: const {},
            formatTime: (t) => '${t.hour}:${t.minute}',
            untracked: const {Prayer.asr},
            onTogglePrayed: (_) {},
          ),
        ),
      ),
    );
    expect(find.bySemanticsLabel('Mark Asr as prayed'), findsNothing);
    expect(find.bySemanticsLabel('Mark Dhuhr as prayed'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('foot CTA reads "Edit jamaat" once any jamaat is set', (
    tester,
  ) async {
    Widget table(Map<Prayer, DateTime> jamaat) => MaterialApp(
      theme: AppTheme.light(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: PrayerTable(
          day: _day,
          activePrayer: null,
          jamaatTimes: jamaat,
          formatTime: (t) => '${t.hour}:${t.minute}',
          onSetJamaat: () {},
        ),
      ),
    );
    await tester.pumpWidget(table(const {}));
    expect(find.text('Set jamaat time'), findsOneWidget);
    await tester.pumpWidget(table({Prayer.fajr: DateTime(2026, 6, 12, 4)}));
    expect(find.text('Edit jamaat'), findsOneWidget);
    expect(find.text('Set jamaat time'), findsNothing);
  });

  testWidgets('dense rows keep a 48dp minimum height', (tester) async {
    await pump(tester, dense: true);
    final row = find.ancestor(
      of: find.text('Fajr'),
      matching: find.byType(GestureDetector),
    );
    expect(tester.getSize(row.first).height, greaterThanOrEqualTo(48));
  });

  testWidgets('a long Bangla name at large text stays on one line', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('bn'),
        theme: AppTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: Scaffold(
            body: PrayerTable(
              day: _day,
              activePrayer: null,
              jamaatTimes: const {},
              formatTime: (t) => '',
            ),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    final name = tester.renderObject<RenderParagraph>(find.text('মাগরিব'));
    final lines = name
        .getBoxesForSelection(
          const TextSelection(baseOffset: 0, extentOffset: 'মাগরিব'.length),
        )
        .map((box) => box.top)
        .toSet();
    expect(lines, hasLength(1));
  });

  testWidgets('labels are localized (bn)', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('bn'),
        theme: AppTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: PrayerTable(
            day: _day,
            activePrayer: null,
            jamaatTimes: const {},
            formatTime: (t) => '',
            onTogglePrayed: (_) {},
          ),
        ),
      ),
    );
    expect(
      find.bySemanticsLabel(RegExp('পড়া হয়েছে হিসেবে চিহ্নিত করুন')),
      findsNWidgets(5),
    );
    handle.dispose();
  });
}
