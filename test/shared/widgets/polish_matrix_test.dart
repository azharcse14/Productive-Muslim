// Automated QA pass for the shared widget library (REVIEW_FIX_PLAN manual
// QA): every widget at 360×640 with real fonts, 1.0×/2.0× text, light and
// dark, English and Bangla, LTR and RTL. Asserts no layout exception and the
// Flutter a11y guidelines (tap target, labels, text contrast).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:productive_muslim/core/l10n/gen/app_localizations.dart';
import 'package:productive_muslim/core/theme/app_theme.dart';
import 'package:productive_muslim/shared/extensions/context_ext.dart';
import 'package:productive_muslim/shared/widgets/countdown_card.dart';
import 'package:productive_muslim/shared/widgets/q_banner.dart';
import 'package:productive_muslim/shared/widgets/q_bottom_nav.dart';
import 'package:productive_muslim/shared/widgets/q_button.dart';
import 'package:productive_muslim/shared/widgets/q_card.dart';
import 'package:productive_muslim/shared/widgets/q_category_tile.dart';
import 'package:productive_muslim/shared/widgets/q_chip.dart';
import 'package:productive_muslim/shared/widgets/q_copy_button.dart';
import 'package:productive_muslim/shared/widgets/q_empty_state.dart';
import 'package:productive_muslim/shared/widgets/q_error_retry.dart';
import 'package:productive_muslim/shared/widgets/q_heatmap.dart';
import 'package:productive_muslim/shared/widgets/q_list_row.dart';
import 'package:productive_muslim/shared/widgets/q_medallion.dart';
import 'package:productive_muslim/shared/widgets/q_progress_ring.dart';
import 'package:productive_muslim/shared/widgets/q_repeat_counter.dart';
import 'package:productive_muslim/shared/widgets/q_section_header.dart';
import 'package:productive_muslim/shared/widgets/q_seg_control.dart';
import 'package:productive_muslim/shared/widgets/q_step_button.dart';

import '../../store/store_capture.dart';

typedef _Case = ({double scale, bool dark, String locale, bool rtl});

final _cases = <_Case>[
  for (final scale in [1.0, 2.0])
    for (final dark in [false, true])
      for (final locale in ['en', 'bn'])
        for (final rtl in [false, true])
          (scale: scale, dark: dark, locale: locale, rtl: rtl),
];

String _name(_Case c) =>
    '${c.scale}x ${c.dark ? 'dark' : 'light'} ${c.locale} '
    '${c.rtl ? 'rtl' : 'ltr'}';

Widget _app(_Case c, Widget Function(BuildContext) build) => MaterialApp(
  theme: c.dark ? AppTheme.dark() : AppTheme.light(),
  locale: Locale(c.locale),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(
      context,
    ).copyWith(textScaler: TextScaler.linear(c.scale)),
    child: Directionality(
      textDirection: c.rtl ? TextDirection.rtl : TextDirection.ltr,
      child: child!,
    ),
  ),
  home: Builder(builder: build),
);

/// A screen body: 20dp side padding, scrolls like the real tabs.
Widget _page(List<Widget> children) => Scaffold(
  body: ListView(
    padding: const EdgeInsetsDirectional.fromSTEB(20, 12, 20, 20),
    children: [
      for (final child in children)
        Padding(padding: const EdgeInsets.only(bottom: 12), child: child),
    ],
  ),
);

/// Pumps [build] in every [_cases] combination and checks it.
void _matrix(
  String widget,
  Widget Function(BuildContext) build, {
  bool contrast = true,
}) {
  group(widget, () {
    setUpAll(loadAppFonts);
    for (final c in _cases) {
      testWidgets(_name(c), (tester) async {
        setView(tester, const Size(360, 640), 1);
        final semantics = tester.ensureSemantics();
        await tester.pumpWidget(_app(c, build));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        if (contrast) {
          await expectLater(tester, meetsGuideline(textContrastGuideline));
        }
        semantics.dispose();
      });
    }
  });
}

void _noop() {}

void main() {
  _matrix(
    'QButton',
    (context) => _page([
      QButton(label: context.l10n.save, icon: Icons.check, onPressed: _noop),
      QButton(
        label: context.l10n.onboardingNotifAllow,
        kind: QButtonKind.tonal,
        onPressed: _noop,
      ),
      QButton(
        label: context.l10n.retry,
        kind: QButtonKind.outline,
        onPressed: _noop,
      ),
      QButton(
        label: context.l10n.cancel,
        kind: QButtonKind.ghost,
        onPressed: _noop,
      ),
      QButton(
        label: context.l10n.onboardingBegin,
        kind: QButtonKind.accent,
        expand: true,
        onPressed: _noop,
      ),
      QButton(label: context.l10n.copyLabel, small: true, onPressed: _noop),
    ]),
  );

  _matrix(
    'QChip + QSegControl',
    (context) => _page([
      Wrap(
        spacing: 8,
        children: [
          QChip(label: context.l10n.tabHome, active: true, onTap: _noop),
          QChip(label: context.l10n.tabQuran, icon: Icons.add, onTap: _noop),
          QChip(label: context.l10n.tabMuhasaba, onTap: _noop),
        ],
      ),
      QSegControl(
        options: [
          context.l10n.tabHome,
          context.l10n.tabDua,
          context.l10n.tabMore,
        ],
        activeIndex: 1,
        onChanged: (_) {},
      ),
    ]),
  );

  _matrix(
    'QBanner + QListRow + QCard + QSectionHeader',
    (context) => _page([
      QSectionHeader(context.l10n.settingsTitle),
      QBanner(text: context.l10n.onboardingNotifDenied),
      QBanner(text: context.l10n.onboardingExactAlarmBody, onTap: _noop),
      QCard(onTap: _noop, child: Text(context.l10n.onboardingMethodNote)),
      QCard(
        child: Column(
          children: [
            QListRow(
              icon: Icons.notifications_outlined,
              title: context.l10n.onboardingNotifTitle,
              subtitle: context.l10n.onboardingNotifBody,
              trailing: const Icon(Icons.chevron_right),
              onTap: _noop,
            ),
            QListRow(
              icon: Icons.language,
              title: context.l10n.onboardingLanguageTitle,
              selected: true,
              trailing: const Icon(Icons.check),
            ),
          ],
        ),
      ),
    ]),
  );

  // The Dua/Ruqyah tab grid: 2 columns, 12dp gaps, 1.2 aspect divided by
  // the text growth, longest category names in each language.
  _matrix(
    'QCategoryTile grid',
    (context) => Scaffold(
      body: GridView.count(
        padding: const EdgeInsets.all(20),
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.2 / context.textGrowth,
        children: [
          for (final id in ['home', 'knowledge', 'istighfar', 'family'])
            QCategoryTile(
              icon: Icons.bedtime_outlined,
              title: context.l10n.duaCategoryName(id),
              subtitle: context.digits(context.l10n.duaCount(112)),
              onTap: _noop,
            ),
        ],
      ),
    ),
  );

  group('QCategoryTile title lines follow the height it gets', () {
    setUpAll(loadAppFonts);
    for (final (height, lines) in [(128.0, 1), (200.0, 2)]) {
      testWidgets('$height dp tall → $lines line(s)', (tester) async {
        await tester.pumpWidget(
          _app(
            (scale: 1, dark: false, locale: 'en', rtl: false),
            (context) => Center(
              child: SizedBox(
                width: 154,
                height: height,
                child: const QCategoryTile(
                  icon: Icons.home_outlined,
                  title: 'Entering & leaving home',
                  subtitle: '12 duas',
                  onTap: _noop,
                ),
              ),
            ),
          ),
        );
        expect(tester.takeException(), isNull);
        expect(
          tester.widget<Text>(find.text('Entering & leaving home')).maxLines,
          lines,
        );
      });
    }
  });

  for (final state in CountdownState.values) {
    _matrix(
      'CountdownCard ${state.name}',
      (context) => _page([
        CountdownCard(
          state: state,
          eyebrow: context.l10n.onboardingExactAlarmTitle,
          big: context.digits('01:24:36'),
          sub: context.l10n.onboardingMadhabNote,
          progress: 0.42,
          footer: [
            (icon: Icons.mosque_outlined, text: context.l10n.tabHome),
            (icon: Icons.wb_twilight, text: context.l10n.onboardingBegin),
          ],
          corner: (fg) => IconButton(
            tooltip: context.l10n.copyLabel,
            icon: Icon(Icons.explore_outlined, color: fg),
            onPressed: _noop,
          ),
        ),
        CountdownCard(
          state: state,
          compact: true,
          eyebrow: context.l10n.tabQuran,
          big: context.digits('12:05'),
          sub: context.l10n.tabDua,
          progress: 0.9,
        ),
      ]),
      // The sky gradient and motif sit under the text; the guideline
      // samples one flat colour and misreads those.
      contrast: false,
    );
  }

  _matrix(
    'QBottomNavScaffold',
    (context) => QBottomNavScaffold(
      currentIndex: 2,
      onSelect: (_) {},
      body: const SizedBox.expand(),
    ),
  );

  _matrix(
    'QErrorRetry',
    (context) => Scaffold(
      body: QErrorRetry(
        message: context.l10n.duaLoadError,
        retryLabel: context.l10n.retry,
        onRetry: _noop,
      ),
    ),
  );

  _matrix(
    'QEmptyState',
    (context) => Scaffold(
      body: QEmptyState(
        icon: Icons.inbox_outlined,
        title: context.l10n.onboardingWelcomeTitle,
        body: context.l10n.onboardingWelcomeBody,
        detail: context.digits('123°'),
        action: QButton(label: context.l10n.retry, onPressed: _noop),
      ),
    ),
  );

  _matrix(
    'Small controls',
    (context) => _page([
      Row(
        children: [
          QStepButton(
            icon: Icons.remove,
            semanticLabel: context.l10n.cancel,
            onTap: _noop,
          ),
          const QMedallion(number: 114),
          QCopyButton(text: context.l10n.tabDua),
          const QRepeatCounter(repeat: 33),
        ],
      ),
      const QProgressRing(progress: 0.6),
      QHeatmap(
        weeks: [
          for (var w = 0; w < 12; w++) [for (var d = 0; d < 7; d++) d % 5],
        ],
      ),
    ]),
  );
}
