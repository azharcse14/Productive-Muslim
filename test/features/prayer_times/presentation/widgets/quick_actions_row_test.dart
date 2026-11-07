import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:productive_muslim/core/l10n/gen/app_localizations.dart';
import 'package:productive_muslim/core/theme/app_theme.dart';
import 'package:productive_muslim/features/prayer_times/presentation/widgets/quick_actions_row.dart';
import 'package:productive_muslim/shared/extensions/context_ext.dart';

import '../../../../store/store_capture.dart';

Widget _wrap(Widget child) => MaterialApp(
  theme: AppTheme.light(),
  home: Scaffold(body: child),
);

void main() {
  group('QuickActionsRow', () {
    testWidgets('renders every action label', (tester) async {
      await tester.pumpWidget(
        _wrap(
          QuickActionsRow(
            actions: [
              QuickAction(
                icon: Icons.menu_book_outlined,
                label: 'Quran',
                onTap: () {},
              ),
              QuickAction(
                icon: Icons.explore_outlined,
                label: 'Qibla',
                onTap: () {},
              ),
              QuickAction(
                icon: Icons.radio_button_checked,
                label: 'Tasbih',
                onTap: () {},
              ),
              QuickAction(
                icon: Icons.volunteer_activism_outlined,
                label: 'Dua',
                onTap: () {},
              ),
            ],
          ),
        ),
      );
      expect(find.text('Quran'), findsOneWidget);
      expect(find.text('Qibla'), findsOneWidget);
      expect(find.text('Tasbih'), findsOneWidget);
      expect(find.text('Dua'), findsOneWidget);
    });

    testWidgets('tapping an action fires its callback', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _wrap(
          QuickActionsRow(
            actions: [
              QuickAction(
                icon: Icons.explore_outlined,
                label: 'Qibla',
                onTap: () => taps++,
              ),
              QuickAction(
                icon: Icons.menu_book_outlined,
                label: 'Quran',
                onTap: () {},
              ),
            ],
          ),
        ),
      );
      await tester.tap(find.text('Qibla'));
      expect(taps, 1);
    });

    // Home's real labels at 360dp, 2.0× text: a word never breaks inside
    // itself ("ক্যালেন্ডা / র") — one line per word at most, two in all.
    group('360dp 2.0x labels wrap only between words', () {
      setUpAll(loadAppFonts);
      for (final locale in ['en', 'bn']) {
        for (final dir in TextDirection.values) {
          testWidgets('$locale ${dir.name}', (tester) async {
            setView(tester, const Size(360, 640), 1);
            late List<String> labels;
            await tester.pumpWidget(
              MaterialApp(
                theme: AppTheme.light(),
                locale: Locale(locale),
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(
                    context,
                  ).copyWith(textScaler: const TextScaler.linear(2)),
                  child: Directionality(textDirection: dir, child: child!),
                ),
                home: Builder(
                  builder: (context) {
                    final l10n = context.l10n;
                    labels = [
                      l10n.nearbyMosquesLabel,
                      l10n.hadithTitle,
                      l10n.calendarTitle,
                      l10n.ruqyahTitle,
                    ];
                    return Scaffold(
                      body: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: QuickActionsRow(
                          actions: [
                            for (final label in labels)
                              QuickAction(
                                icon: Icons.mosque_outlined,
                                label: label,
                                onTap: () {},
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            );
            expect(tester.takeException(), isNull);
            for (final label in labels) {
              final paragraph = tester.renderObject<RenderParagraph>(
                find.text(label),
              );
              // Line tops of one word (spaces excluded: a space may come
              // from another font with a different top).
              Set<double> tops(int start, int end) => paragraph
                  .getBoxesForSelection(
                    TextSelection(baseOffset: start, extentOffset: end),
                  )
                  .map((box) => box.top)
                  .toSet();
              final allTops = <double>{};
              var start = 0;
              for (final word in label.split(' ')) {
                final wordTops = tops(start, start + word.length);
                expect(wordTops, hasLength(1), reason: '"$word" breaks');
                allTops.addAll(wordTops);
                start += word.length + 1;
              }
              expect(allTops.length, lessThanOrEqualTo(2), reason: label);
            }
          });
        }
      }
    });
  });
}
