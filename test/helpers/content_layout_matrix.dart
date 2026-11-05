import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:productive_muslim/core/l10n/gen/app_localizations.dart';
import 'package:productive_muslim/core/theme/app_theme.dart';

import '../store/store_capture.dart' show loadAppFonts;

/// One cell of the automated manual-QA matrix: text scale × theme ×
/// locale × reading direction (RTL is forced; there's no Arabic locale yet).
typedef LayoutVariant = ({double scale, bool dark, String locale, bool rtl});

final _variants = <LayoutVariant>[
  for (final scale in [1.0, 2.0])
    for (final dark in [false, true])
      for (final locale in ['en', 'bn'])
        for (final rtl in [false, true])
          (scale: scale, dark: dark, locale: locale, rtl: rtl),
];

String _label(LayoutVariant v) =>
    '${v.scale}x ${v.dark ? 'dark' : 'light'} ${v.locale}'
    '${v.rtl ? ' rtl' : ''}';

/// The variant's theme for a `MaterialApp`.
ThemeData variantTheme(LayoutVariant v) =>
    v.dark ? AppTheme.dark() : AppTheme.light();

/// A `MaterialApp.builder` that applies [v]'s text scale and direction,
/// around the app's own [inner] builder if it has one.
TransitionBuilder variantBuilder(LayoutVariant v, [TransitionBuilder? inner]) =>
    (context, child) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(v.scale)),
      child: Directionality(
        textDirection: v.rtl ? TextDirection.rtl : TextDirection.ltr,
        child: inner == null ? child! : inner(context, child),
      ),
    );

/// Pumps a screen for every [LayoutVariant] on a 360×640 dp view with the
/// real app fonts, and fails on any framework exception (RenderFlex
/// overflow included). At 1.0x it also checks the tap-target, label and
/// text-contrast guidelines.
///
/// [pump] builds the app for the variant (use [variantApp] or
/// [variantRouterApp]) and settles it. [tapTargets] false skips only the
/// 48dp tap-target check, for screens with a known shared-widget gap.
void layoutMatrix(
  String screen,
  Future<void> Function(WidgetTester tester, LayoutVariant v) pump, {
  bool tapTargets = true,
}) {
  group('$screen layout', () {
    setUpAll(loadAppFonts);
    for (final v in _variants) {
      testWidgets(_label(v), (tester) async {
        tester.view
          ..physicalSize = const Size(360, 640)
          ..devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final semantics = tester.ensureSemantics();
        await pump(tester, v);
        expect(tester.takeException(), isNull);
        if (v.scale == 1) {
          if (tapTargets) {
            await expectLater(
              tester,
              meetsGuideline(androidTapTargetGuideline),
            );
          }
          await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
          await expectLater(tester, meetsGuideline(textContrastGuideline));
        }
        semantics.dispose();
      });
    }
  });
}

/// The app's `MaterialApp` shell around [home] for variant [v].
Widget variantApp(Widget home, LayoutVariant v, {TransitionBuilder? builder}) =>
    MaterialApp(
      theme: variantTheme(v),
      locale: Locale(v.locale),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: variantBuilder(v, builder),
      home: home,
    );

/// [variantApp] for a router-driven test app.
Widget variantRouterApp(
  RouterConfig<Object> router,
  LayoutVariant v, {
  TransitionBuilder? builder,
}) => MaterialApp.router(
  theme: variantTheme(v),
  locale: Locale(v.locale),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  builder: variantBuilder(v, builder),
  routerConfig: router,
);
