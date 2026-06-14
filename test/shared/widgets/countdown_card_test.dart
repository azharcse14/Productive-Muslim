import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qalbee/core/theme/app_theme.dart';
import 'package:qalbee/core/theme/qalbee_colors.dart';
import 'package:qalbee/shared/widgets/countdown_card.dart';

Widget _wrap(Widget child, {bool dark = false}) => MaterialApp(
      theme: dark ? AppTheme.dark() : AppTheme.light(),
      home: Scaffold(body: Center(child: child)),
    );

CountdownCard _card(CountdownState state) => CountdownCard(
      state: state,
      eyebrow: 'Asr ends in',
      big: '01:24:36',
      sub: 'Jamaat at 5:15 pm',
      progress: 0.42,
    );

AnimatedContainer _container(WidgetTester tester) =>
    tester.widget<AnimatedContainer>(
      find.descendant(
        of: find.byType(CountdownCard),
        matching: find.byType(AnimatedContainer),
      ),
    );

Color _bgOf(WidgetTester tester) =>
    (_container(tester).decoration! as BoxDecoration).color!;

LinearGradient? _gradientOf(WidgetTester tester) =>
    (_container(tester).decoration! as BoxDecoration).gradient as LinearGradient?;

Color? _flatColorOf(WidgetTester tester) =>
    (_container(tester).decoration! as BoxDecoration).color;

void main() {
  group('CountdownCard', () {
    testWidgets('renders eyebrow (uppercased), numeral, and sub',
        (tester) async {
      await tester.pumpWidget(_wrap(_card(CountdownState.calm)));
      expect(find.text('ASR ENDS IN'), findsOneWidget);
      expect(find.text('01:24:36'), findsOneWidget);
      expect(find.text('Jamaat at 5:15 pm'), findsOneWidget);
    });

    testWidgets('calm state uses a brand sky gradient ending in surface',
        (tester) async {
      await tester.pumpWidget(_wrap(_card(CountdownState.calm)));
      final gradient = _gradientOf(tester);
      expect(gradient, isNotNull);
      // The wash always resolves back to the surface at the bottom so the
      // dark numeral stays readable; no flat colour when a gradient is set.
      expect(gradient!.colors.last, QalbeeColors.light.surface);
      expect(_flatColorOf(tester), isNull);
    });

    testWidgets('the sky phase shifts the calm gradient top tint',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          const CountdownCard(
            state: CountdownState.calm,
            skyPhase: SkyPhase.dawn,
            eyebrow: 'a',
            big: 'b',
            sub: 'c',
            progress: 0.1,
          ),
        ),
      );
      final dawnTint = _gradientOf(tester)!.colors.first;
      await tester.pumpWidget(
        _wrap(
          const CountdownCard(
            state: CountdownState.calm,
            skyPhase: SkyPhase.evening,
            eyebrow: 'a',
            big: 'b',
            sub: 'c',
            progress: 0.1,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(_gradientOf(tester)!.colors.first, isNot(dawnTint));
    });

    testWidgets('a semantic state keeps a flat colour (no gradient)',
        (tester) async {
      await tester.pumpWidget(_wrap(_card(CountdownState.amber)));
      expect(_gradientOf(tester), isNull);
      expect(_flatColorOf(tester), QalbeeColors.light.warnSoft);
    });

    testWidgets('amber state uses warn-soft background', (tester) async {
      await tester.pumpWidget(_wrap(_card(CountdownState.amber)));
      expect(_bgOf(tester), QalbeeColors.light.warnSoft);
    });

    testWidgets('urgent state uses urgent-soft background', (tester) async {
      await tester.pumpWidget(_wrap(_card(CountdownState.urgent)));
      expect(_bgOf(tester), QalbeeColors.light.urgentSoft);
    });

    testWidgets('sahri state uses primary background', (tester) async {
      await tester.pumpWidget(_wrap(_card(CountdownState.sahri)));
      expect(_bgOf(tester), QalbeeColors.light.primary);
    });

    testWidgets('iftar state uses accent-soft background', (tester) async {
      await tester.pumpWidget(_wrap(_card(CountdownState.iftar)));
      expect(_bgOf(tester), QalbeeColors.light.accentSoft);
    });

    testWidgets('dark theme resolves dark tokens', (tester) async {
      await tester.pumpWidget(_wrap(_card(CountdownState.calm), dark: true));
      expect(_gradientOf(tester)!.colors.last, QalbeeColors.dark.surface);
    });

    testWidgets('progress is clamped to 0..1', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const CountdownCard(
            state: CountdownState.calm,
            eyebrow: 'x',
            big: 'y',
            sub: 'z',
            progress: 1.7,
          ),
        ),
      );
      final fraction = tester.widget<FractionallySizedBox>(
        find.byType(FractionallySizedBox),
      );
      expect(fraction.widthFactor, 1);
    });

    testWidgets('progress fill is anchored to the start (left-to-right)',
        (tester) async {
      await tester.pumpWidget(_wrap(_card(CountdownState.calm)));
      final fraction = tester.widget<FractionallySizedBox>(
        find.byType(FractionallySizedBox),
      );
      expect(fraction.alignment, AlignmentDirectional.centerStart);
    });
  });
}
