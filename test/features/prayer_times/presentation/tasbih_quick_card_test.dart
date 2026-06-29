import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:productive_muslim/core/l10n/gen/app_localizations.dart';
import 'package:productive_muslim/core/theme/app_theme.dart';
import 'package:productive_muslim/features/prayer_times/presentation/widgets/tasbih_quick_card.dart';

Widget _app(Widget child) => MaterialApp(
      theme: AppTheme.light(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    );

void main() {
  testWidgets('renders title, hint and count', (tester) async {
    await tester.pumpWidget(
      _app(
        TasbihQuickCard(
          count: 5,
          target: 33,
          onTap: () {},
        ),
      ),
    );

    expect(find.text('Tasbih'), findsOneWidget);
    expect(find.text('Tap to count'), findsOneWidget);
    expect(find.text('5'), findsOneWidget);
    expect(find.text('5 / 33'), findsOneWidget);
  });

  testWidgets('tapping the counter ring fires onTap', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      _app(
        TasbihQuickCard(
          count: 5,
          target: 33,
          onTap: () => taps++,
        ),
      ),
    );

    await tester.tap(find.text('5'));
    await tester.pump();

    expect(taps, 1);
  });

  testWidgets('reset icon shows and fires only when onReset provided',
      (tester) async {
    var resets = 0;

    await tester.pumpWidget(
      _app(
        TasbihQuickCard(
          count: 5,
          target: 33,
          onTap: () {},
        ),
      ),
    );
    expect(find.byIcon(Icons.refresh), findsNothing);

    await tester.pumpWidget(
      _app(
        TasbihQuickCard(
          count: 5,
          target: 33,
          onTap: () {},
          onReset: () => resets++,
        ),
      ),
    );
    expect(find.byIcon(Icons.refresh), findsOneWidget);

    await tester.tap(find.byIcon(Icons.refresh));
    await tester.pump();
    expect(resets, 1);
  });

  testWidgets('chevron shows and fires only when onOpen provided',
      (tester) async {
    var opens = 0;

    await tester.pumpWidget(
      _app(
        TasbihQuickCard(
          count: 5,
          target: 33,
          onTap: () {},
        ),
      ),
    );
    expect(find.byIcon(Icons.chevron_right), findsNothing);

    await tester.pumpWidget(
      _app(
        TasbihQuickCard(
          count: 5,
          target: 33,
          onTap: () {},
          onOpen: () => opens++,
        ),
      ),
    );
    expect(find.byIcon(Icons.chevron_right), findsOneWidget);

    await tester.tap(find.byIcon(Icons.chevron_right));
    await tester.pump();
    expect(opens, 1);
  });
}
