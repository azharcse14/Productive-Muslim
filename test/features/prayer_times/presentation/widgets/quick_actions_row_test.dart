import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:productive_muslim/core/theme/app_theme.dart';
import 'package:productive_muslim/features/prayer_times/presentation/widgets/quick_actions_row.dart';

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
  });
}
