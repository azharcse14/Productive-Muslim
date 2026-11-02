import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:productive_muslim/core/l10n/gen/app_localizations.dart';
import 'package:productive_muslim/core/theme/app_theme.dart';
import 'package:productive_muslim/features/prayer_times/domain/entities/prayer_day.dart';
import 'package:productive_muslim/features/prayer_times/domain/entities/special_time.dart';
import 'package:productive_muslim/features/prayer_times/presentation/widgets/day_timeline_sheet.dart';
import 'package:productive_muslim/features/settings/domain/entities/prayer_params.dart';
import 'package:signals_flutter/signals_flutter.dart';

Widget _app(Widget child) => MaterialApp(
  theme: AppTheme.light(),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: child),
);

PrayerDay _sampleDay() => PrayerDay(
  fajr: DateTime(2026, 6, 14, 4, 5),
  sunrise: DateTime(2026, 6, 14, 5, 20),
  dhuhr: DateTime(2026, 6, 14, 12, 30),
  asr: DateTime(2026, 6, 14, 16, 45),
  maghrib: DateTime(2026, 6, 14, 19, 10),
  isha: DateTime(2026, 6, 14, 20, 40),
  fajrTomorrow: DateTime(2026, 6, 15, 4, 6),
  ishaYesterday: DateTime(2026, 6, 13, 20, 39),
);

String _fmt(DateTime t) => '${t.hour}:${t.minute.toString().padLeft(2, '0')}';

void main() {
  testWidgets('renders the title and all five prayer labels', (tester) async {
    await tester.pumpWidget(
      _app(
        DayTimelineSheet(
          day: _sampleDay(),
          now: DateTime(2026, 6, 14, 13),
          formatTime: _fmt,
        ),
      ),
    );

    expect(find.text("Today's timeline"), findsOneWidget);
    expect(find.text('Fajr'), findsOneWidget);
    expect(find.text('Dhuhr'), findsOneWidget);
    expect(find.text('Asr'), findsOneWidget);
    expect(find.text('Maghrib'), findsOneWidget);
    expect(find.text('Isha'), findsOneWidget);
  });

  testWidgets('renders the start time for each prayer via the formatter', (
    tester,
  ) async {
    final day = _sampleDay();
    await tester.pumpWidget(
      _app(
        DayTimelineSheet(
          day: day,
          now: DateTime(2026, 6, 14, 13),
          formatTime: _fmt,
        ),
      ),
    );

    expect(find.text(_fmt(day.startOf(Prayer.fajr))), findsOneWidget);
    expect(find.text(_fmt(day.startOf(Prayer.dhuhr))), findsOneWidget);
    expect(find.text(_fmt(day.startOf(Prayer.asr))), findsOneWidget);
    expect(find.text(_fmt(day.startOf(Prayer.maghrib))), findsOneWidget);
    expect(find.text(_fmt(day.startOf(Prayer.isha))), findsOneWidget);
  });

  testWidgets('shows a single Now badge for the active prayer', (tester) async {
    await tester.pumpWidget(
      _app(
        DayTimelineSheet(
          day: _sampleDay(),
          now: DateTime(2026, 6, 14, 13),
          formatTime: _fmt,
        ),
      ),
    );

    expect(find.text('Now'), findsOneWidget);
  });

  testWidgets('adds sunrise, forbidden windows and a now marker in order', (
    tester,
  ) async {
    final day = _sampleDay();
    await tester.pumpWidget(
      _app(
        DayTimelineSheet(
          day: day,
          now: DateTime(2026, 6, 14, 13),
          formatTime: _fmt,
          forbidden: [
            SpecialWindow(
              time: SpecialTime.forbiddenZawal,
              kind: SpecialKind.forbidden,
              start: DateTime(2026, 6, 14, 12, 24),
              end: day.dhuhr,
            ),
          ],
        ),
      ),
    );

    expect(find.text('Sunrise'), findsOneWidget);
    expect(find.text('12:24 – 12:30'), findsOneWidget);
    double y(String text) => tester.getTopLeft(find.text(text)).dy;
    expect(y('Sunrise'), lessThan(y('Dhuhr')));
    expect(y('Midday (zawal)'), lessThan(y('Dhuhr')));
    expect(y('Dhuhr'), lessThan(y('Now')));
    expect(y('Now'), lessThan(y('Asr')));
  });

  // The active row's label is drawn in ink, the others in ink2.
  Color? labelColor(WidgetTester tester, String label) =>
      tester.widget<Text>(find.text(label)).style?.color;

  testWidgets('the highlight follows the clock across a waqt boundary', (
    tester,
  ) async {
    var now = DateTime(2026, 6, 14, 16, 44);
    late StateSetter setNow;
    await tester.pumpWidget(
      _app(
        StatefulBuilder(
          builder: (context, setState) {
            setNow = setState;
            return DayTimelineSheet(
              day: _sampleDay(),
              now: now,
              formatTime: _fmt,
            );
          },
        ),
      ),
    );
    final active = labelColor(tester, 'Dhuhr');
    expect(labelColor(tester, 'Asr'), isNot(active));

    setNow(() => now = DateTime(2026, 6, 14, 16, 46));
    await tester.pump();
    expect(labelColor(tester, 'Asr'), active);
    expect(labelColor(tester, 'Dhuhr'), isNot(active));
  });

  testWidgets("after midnight, tonight's Isha is not highlighted", (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        DayTimelineSheet(
          day: _sampleDay(),
          now: DateTime(2026, 6, 14, 2), // yesterday's Isha still running
          formatTime: _fmt,
        ),
      ),
    );
    expect(labelColor(tester, 'Isha'), labelColor(tester, 'Fajr'));
  });

  testWidgets('"Sahri ends" shows only in Ramadan', (tester) async {
    final base = _sampleDay();
    // The repository always adds a minute of margin, so sahri != fajr.
    final day = PrayerDay(
      fajr: base.fajr,
      sunrise: base.sunrise,
      dhuhr: base.dhuhr,
      asr: base.asr,
      maghrib: base.maghrib,
      isha: base.isha,
      fajrTomorrow: base.fajrTomorrow,
      ishaYesterday: base.ishaYesterday,
      sahriSafety: const Duration(minutes: 1),
    );
    Widget sheet({required bool ramadan}) => _app(
      DayTimelineSheet(
        day: day,
        now: DateTime(2026, 6, 14, 13),
        formatTime: _fmt,
        ramadan: ramadan,
      ),
    );
    await tester.pumpWidget(sheet(ramadan: false));
    expect(find.text('Sahri ends'), findsNothing);
    await tester.pumpWidget(sheet(ramadan: true));
    expect(find.text('Sahri ends'), findsOneWidget);
  });

  testWidgets('an open sheet follows the live day past midnight', (
    tester,
  ) async {
    final today = _sampleDay();
    final tomorrow = PrayerDay(
      fajr: DateTime(2026, 6, 15, 4, 6),
      sunrise: DateTime(2026, 6, 15, 5, 21),
      dhuhr: DateTime(2026, 6, 15, 12, 31),
      asr: DateTime(2026, 6, 15, 16, 46),
      maghrib: DateTime(2026, 6, 15, 19, 11),
      isha: DateTime(2026, 6, 15, 20, 41),
      fajrTomorrow: DateTime(2026, 6, 16, 4, 7),
      ishaYesterday: today.isha,
    );
    final day = signal(today);
    final now = signal(DateTime(2026, 6, 14, 23, 59));
    await tester.pumpWidget(
      _app(
        Builder(
          builder: (context) => TextButton(
            onPressed: () => showDayTimelineSheet(
              context,
              sheet: () => DayTimelineSheet(
                day: day.value,
                now: now.value,
                formatTime: _fmt,
              ),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('12:30'), findsOneWidget);

    now.value = DateTime(2026, 6, 15, 0, 1);
    day.value = tomorrow;
    await tester.pump();
    expect(find.text('12:30'), findsNothing);
    expect(find.text('12:31'), findsOneWidget);
  });
}
