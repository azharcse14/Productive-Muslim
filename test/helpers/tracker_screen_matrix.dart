import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:productive_muslim/core/l10n/gen/app_localizations.dart';
import 'package:productive_muslim/core/theme/app_theme.dart';

import '../store/store_capture.dart' show loadAppFonts;

bool _fontsLoaded = false;

/// Automated "manual QA" pass (REVIEW_FIX_PLAN): pumps [screen] on a 360×640
/// dp view at 1.0x and 2.0x text, light and dark, en and bn, LTR and RTL
/// (no Arabic locale yet, so RTL is forced with [Directionality]). Each case
/// fails on any layout exception (RenderFlex overflow…) and on the a11y tap
/// target / label / text contrast guidelines, at the top of the screen and
/// again after scrolling its main list to the end.
///
/// [setUpCase] runs inside the test before pumping (seed stores there);
/// [afterPump] drives the screen into the state under test (tab, dialog…).
/// [knownSmallTarget] exempts tap-target nodes owned by code outside the
/// caller's scope (a shared widget) — name the follow-up where it's used.
void screenMatrix(
  String name,
  Widget Function() screen, {
  Future<void> Function()? setUpCase,
  Future<void> Function(WidgetTester tester)? afterPump,
  bool Function(SemanticsData data)? knownSmallTarget,
}) {
  for (final dark in [false, true]) {
    for (final locale in ['en', 'bn']) {
      for (final rtl in [false, true]) {
        for (final scale in [1.0, 2.0]) {
          final label =
              '$name · 360dp · ${dark ? 'dark' : 'light'} · $locale · '
              '${rtl ? 'rtl' : 'ltr'} · ${scale}x';
          testWidgets(label, (tester) async {
            if (!_fontsLoaded) {
              await tester.runAsync(loadAppFonts);
              _fontsLoaded = true;
            }
            tester.view
              ..physicalSize = const Size(360, 640)
              ..devicePixelRatio = 1;
            addTearDown(tester.view.reset);
            final semantics = tester.ensureSemantics();
            await setUpCase?.call();
            await tester.pumpWidget(
              MaterialApp(
                theme: dark ? AppTheme.dark() : AppTheme.light(),
                locale: Locale(locale),
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(
                    context,
                  ).copyWith(textScaler: TextScaler.linear(scale)),
                  child: rtl
                      ? Directionality(
                          textDirection: TextDirection.rtl,
                          child: child!,
                        )
                      : child!,
                ),
                home: screen(),
              ),
            );
            await tester.pumpAndSettle();
            await afterPump?.call(tester);
            final tapTargets = _TapTargetGuideline(knownSmallTarget);
            await _checkViewport(tester, tapTargets);
            await _scrollToEnd(tester);
            await _checkViewport(tester, tapTargets);
            semantics.dispose();
          });
        }
      }
    }
  }
}

/// [androidTapTargetGuideline] minus the [skip]ped nodes.
final class _TapTargetGuideline extends MinimumTapTargetGuideline {
  const _TapTargetGuideline(this.skip)
    : super(
        size: const Size(48, 48),
        link: 'https://support.google.com/accessibility/android/answer/7101858',
      );

  final bool Function(SemanticsData data)? skip;

  @override
  bool shouldSkipNode(SemanticsNode node) =>
      super.shouldSkipNode(node) ||
      (skip?.call(node.getSemanticsData()) ?? false);
}

Future<void> _checkViewport(
  WidgetTester tester,
  AccessibilityGuideline tapTargets,
) async {
  expect(tester.takeException(), isNull);
  await expectLater(tester, meetsGuideline(tapTargets));
  await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
  await expectLater(tester, meetsGuideline(textContrastGuideline));
}

/// Drags the first vertical scrollable down to its end, a page at a time,
/// so lazily-built rows lay out (and can overflow) too.
Future<void> _scrollToEnd(WidgetTester tester) async {
  final vertical = find.byWidgetPredicate(
    (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
  );
  if (vertical.evaluate().isEmpty) {
    return;
  }
  final scrollable = vertical.first;
  for (var i = 0; i < 20; i++) {
    final position = tester.state<ScrollableState>(scrollable).position;
    if (position.pixels >= position.maxScrollExtent) {
      break;
    }
    await tester.drag(scrollable, const Offset(0, -400), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  }
}
