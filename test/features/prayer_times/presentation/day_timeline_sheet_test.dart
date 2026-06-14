import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qalbee/core/l10n/gen/app_localizations.dart';
import 'package:qalbee/core/theme/app_theme.dart';
import 'package:qalbee/features/prayer_times/domain/entities/prayer_day.dart';
import 'package:qalbee/features/prayer_times/presentation/widgets/day_timeline_sheet.dart';
import 'package:qalbee/features/settings/domain/entities/prayer_params.dart';

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

  testWidgets('renders the start time for each prayer via the formatter',
      (tester) async {
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
          activePrayer: Prayer.dhuhr,
        ),
      ),
    );

    expect(find.text('Now'), findsOneWidget);
  });

  testWidgets('shows no Now badge when activePrayer is null', (tester) async {
    await tester.pumpWidget(
      _app(
        DayTimelineSheet(
          day: _sampleDay(),
          now: DateTime(2026, 6, 14, 13),
          formatTime: _fmt,
        ),
      ),
    );

    expect(find.text('Now'), findsNothing);
  });
}
