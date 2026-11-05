import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:productive_muslim/core/l10n/gen/app_localizations.dart';
import 'package:productive_muslim/core/theme/app_theme.dart';

import '../store/store_capture.dart' show loadAppFonts;

/// One cell of the manual-QA matrix: 360×640dp, text 1.0×/2.0×, light/dark,
/// en/bn, LTR/RTL (no RTL locale yet, so RTL is forced via Directionality).
typedef LayoutVariant = ({
  double scale,
  bool dark,
  String locale,
  TextDirection dir,
});

final List<LayoutVariant> layoutVariants = [
  for (final scale in const [1.0, 2.0])
    for (final dark in const [false, true])
      for (final locale in const ['en', 'bn'])
        for (final dir in TextDirection.values)
          (scale: scale, dark: dark, locale: locale, dir: dir),
];

String _label(LayoutVariant v) =>
    '${v.scale}x ${v.dark ? 'dark' : 'light'} ${v.locale} ${v.dir.name}';

/// The app shell (theme, l10n, text scale, direction) around [home] — or
/// around a [router] when the screen needs go_router.
Widget layoutApp(
  LayoutVariant v, {
  Widget? home,
  RouterConfig<Object>? router,
}) {
  Widget wrap(BuildContext context, Widget? child) => MediaQuery(
    data: MediaQuery.of(
      context,
    ).copyWith(textScaler: TextScaler.linear(v.scale)),
    child: Directionality(textDirection: v.dir, child: child!),
  );
  final theme = v.dark ? AppTheme.dark() : AppTheme.light();
  final locale = Locale(v.locale);
  return router != null
      ? MaterialApp.router(
          theme: theme,
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
          builder: wrap,
        )
      : MaterialApp(
          theme: theme,
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: wrap,
          home: home,
        );
}

Future<void> _settle(WidgetTester tester) async {
  // Countdown screens tick forever, so no pumpAndSettle.
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  await tester.pump();
}

/// Scrolls every vertical scrollable to its end so lazily built rows get
/// laid out (and overflow-checked) too.
Future<void> _scrollThrough(WidgetTester tester) async {
  for (var pass = 0; pass < 40; pass++) {
    var moved = false;
    for (final state in tester.stateList<ScrollableState>(
      find.byType(Scrollable),
    )) {
      final p = state.position;
      if (p.axis != Axis.vertical || p.pixels >= p.maxScrollExtent) continue;
      p.jumpTo((p.pixels + 400).clamp(0, p.maxScrollExtent));
      moved = true;
    }
    if (!moved) return;
    await tester.pump();
    expect(tester.takeException(), isNull);
  }
}

/// Pumps a screen across [layoutVariants] (360×640dp) asserting no
/// overflow or exception, top to bottom, then checks the accessibility
/// guidelines (tap-target size and labels in light; text contrast in
/// light and dark) at 1.0× en LTR.
///
/// [arrange] registers the screen's fakes; [prepare] drives the pumped
/// screen into the state under test; [cleanup] runs after the tree
/// is unmounted (stop tickers, dispose controllers). Set [tapTargets]
/// or [tapLabels] false only for a known shared-widget shortfall (say
/// which, inline).
void layoutMatrix(
  String name, {
  required Widget Function() screen,
  Future<void> Function(WidgetTester tester)? arrange,
  Future<void> Function(WidgetTester tester)? prepare,
  RouterConfig<Object> Function()? router,
  Future<void> Function()? cleanup,
  bool tapTargets = true,
  bool tapLabels = true,
  bool contrast = true,
}) {
  Future<void> pump(WidgetTester tester, LayoutVariant v) async {
    tester.view
      ..physicalSize = const Size(360, 640)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await arrange?.call(tester);
    await tester.pumpWidget(
      router != null
          ? layoutApp(v, router: router())
          : layoutApp(v, home: screen()),
    );
    await _settle(tester);
    if (prepare != null) {
      await prepare(tester);
      await _settle(tester);
    }
    expect(tester.takeException(), isNull);
  }

  Future<void> done(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await cleanup?.call();
  }

  group('$name layout matrix', () {
    setUpAll(loadAppFonts);

    for (final v in layoutVariants) {
      testWidgets(_label(v), (tester) async {
        await pump(tester, v);
        await _scrollThrough(tester);
        await done(tester);
      });
    }

    for (final dark in const [false, true]) {
      testWidgets('a11y guidelines ${dark ? 'dark' : 'light'}', (tester) async {
        final handle = tester.ensureSemantics();
        await pump(tester, (
          scale: 1.0,
          dark: dark,
          locale: 'en',
          dir: TextDirection.ltr,
        ));
        if (!dark) {
          if (tapTargets) {
            await expectLater(
              tester,
              meetsGuideline(androidTapTargetGuideline),
            );
          }
          if (tapLabels) {
            await expectLater(
              tester,
              meetsGuideline(labeledTapTargetGuideline),
            );
          }
        }
        if (contrast) {
          await expectLater(tester, meetsGuideline(textContrastGuideline));
        }
        handle.dispose();
        await done(tester);
      });
    }
  });
}
