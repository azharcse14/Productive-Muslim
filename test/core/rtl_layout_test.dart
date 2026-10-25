import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:productive_muslim/core/l10n/gen/app_localizations.dart';
import 'package:productive_muslim/core/theme/app_theme.dart';
import 'package:productive_muslim/features/daily_content/presentation/widgets/dua_of_day_card.dart';
import 'package:productive_muslim/features/prayer_times/domain/entities/prayer_day.dart';
import 'package:productive_muslim/features/prayer_times/presentation/widgets/daily_ayah_card.dart';
import 'package:productive_muslim/features/prayer_times/presentation/widgets/day_timeline_sheet.dart';

Widget _app(Widget child, TextDirection direction) => MaterialApp(
      theme: AppTheme.light(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Directionality(
        textDirection: direction,
        child: Scaffold(body: child),
      ),
    );

final _day = PrayerDay(
  fajr: DateTime(2026, 6, 14, 4, 5),
  sunrise: DateTime(2026, 6, 14, 5, 20),
  dhuhr: DateTime(2026, 6, 14, 12, 30),
  asr: DateTime(2026, 6, 14, 16, 45),
  maghrib: DateTime(2026, 6, 14, 19, 10),
  isha: DateTime(2026, 6, 14, 20, 40),
  fajrTomorrow: DateTime(2026, 6, 15, 4, 6),
  ishaYesterday: DateTime(2026, 6, 13, 20, 39),
);

const _arabic = 'ٱللَّهُ لَآ إِلَٰهَ إِلَّا هُوَ';

void main() {
  group('Day timeline mirrors in RTL', () {
    for (final direction in TextDirection.values) {
      testWidgets('$direction: label on the start side, time on the end',
          (tester) async {
        await tester.pumpWidget(
          _app(
            DayTimelineSheet(
              day: _day,
              now: DateTime(2026, 6, 14, 9),
              formatTime: (t) => '${t.hour}:${t.minute}',
            ),
            direction,
          ),
        );
        final label = tester.getCenter(find.text('Dhuhr'));
        final time = tester.getCenter(find.text('12:30'));
        expect(
          direction == TextDirection.ltr ? label.dx < time.dx : label.dx > time.dx,
          isTrue,
        );
        // Text hugs the start edge of its expanded slot.
        final labelRect = tester.getRect(find.text('Dhuhr'));
        final slot = tester.getRect(
          find.ancestor(of: find.text('Dhuhr'), matching: find.byType(Expanded)),
        );
        if (direction == TextDirection.ltr) {
          expect(labelRect.left, slot.left);
        } else {
          expect(labelRect.right, slot.right);
        }
      });
    }
  });

  group('Arabic in daily cards is RTL + start-aligned', () {
    for (final direction in TextDirection.values) {
      testWidgets('$direction app direction', (tester) async {
        await tester.pumpWidget(
          _app(
            const Column(
              children: [
                DailyAyahCard(
                  arabic: _arabic,
                  translation: 'Allah',
                  surahName: 'Al-Baqarah',
                  ayahNumber: '255',
                ),
                DuaOfDayCard(
                  arabic: _arabic,
                  translation: 'Allah',
                  reference: 'Ref',
                ),
              ],
            ),
            direction,
          ),
        );
        final texts = tester.widgetList<Text>(find.text(_arabic));
        expect(texts, hasLength(2));
        for (final t in texts) {
          expect(t.textDirection, TextDirection.rtl);
          expect(t.textAlign, TextAlign.start);
        }
      });
    }
  });

  test('lib uses directional layout APIs only', () {
    final banned = RegExp(
      r'Alignment\.(centerLeft|centerRight|topLeft|topRight|bottomLeft|'
      r'bottomRight)\b|TextAlign\.(left|right)\b|'
      r'EdgeInsets\.only\([^)]*\b(left|right):',
    );
    final offenders = <String>[];
    for (final file in Directory('lib').listSync(recursive: true)) {
      if (file is! File ||
          !file.path.endsWith('.dart') ||
          file.path.contains('/gen/')) {
        continue;
      }
      final lines = file.readAsLinesSync();
      final text = lines.join('\n');
      for (final m in banned.allMatches(text)) {
        final line = '\n'.allMatches(text.substring(0, m.start)).length + 1;
        offenders.add('${file.path}:$line ${m[0]}');
      }
    }
    expect(offenders, isEmpty);
  });
}
