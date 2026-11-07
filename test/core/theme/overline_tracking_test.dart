import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:productive_muslim/core/l10n/gen/app_localizations.dart';
import 'package:productive_muslim/core/theme/app_theme.dart';
import 'package:productive_muslim/core/theme/productive_muslim_typography.dart';

void main() {
  group('QType.localize — overline tracking per script', () {
    for (final (name, build) in [
      ('light', AppTheme.light),
      ('dark', AppTheme.dark),
    ]) {
      test('$name: English keeps the +1.4 overline tracking', () {
        final t = QType.localize(build(), const Locale('en')).textTheme;
        expect(t.labelSmall!.letterSpacing, 1.4);
      });

      test('$name: Bangla drops the overline tracking, keeps the rest', () {
        final base = build().textTheme;
        final t = QType.localize(build(), const Locale('bn')).textTheme;
        expect(t.labelSmall!.letterSpacing, 0);
        expect(t.labelSmall!.fontSize, base.labelSmall!.fontSize);
        expect(t.labelSmall!.color, base.labelSmall!.color);
        // Negative tracking is deliberately untouched.
        expect(t.titleLarge!.letterSpacing, base.titleLarge!.letterSpacing);
      });
    }

    testWidgets('a widget reading labelSmall under bn is untracked', (
      tester,
    ) async {
      TextStyle? style;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          locale: const Locale('bn'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          builder: (context, child) => Theme(
            data: QType.localize(
              Theme.of(context),
              Localizations.localeOf(context),
            ),
            child: child!,
          ),
          home: Builder(
            builder: (context) {
              style = Theme.of(context).textTheme.labelSmall;
              return const SizedBox();
            },
          ),
        ),
      );
      expect(style!.letterSpacing, 0);
    });
  });
}
