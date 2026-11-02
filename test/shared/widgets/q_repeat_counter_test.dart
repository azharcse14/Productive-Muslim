import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:productive_muslim/core/l10n/gen/app_localizations.dart';
import 'package:productive_muslim/core/theme/app_theme.dart';
import 'package:productive_muslim/features/ruqyah/domain/entities/ruqyah.dart';
import 'package:productive_muslim/features/ruqyah/presentation/widgets/ruqyah_card.dart';
import 'package:productive_muslim/shared/widgets/q_repeat_counter.dart';

Widget _app(Widget child) => MaterialApp(
  theme: AppTheme.light(),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: SingleChildScrollView(child: child)),
);

RuqyahItem _item(String id) => RuqyahItem(
  id: id,
  titleEn: 'Title $id',
  titleBn: '',
  arabic: 'arabic $id',
  transliteration: '',
  translationEn: '',
  translationBn: '',
  reference: '',
  repeat: 3,
);

void main() {
  testWidgets("a passage's count never moves to the card that replaces it", (
    tester,
  ) async {
    // Same slot, different passage — e.g. a search list that changed.
    await tester.pumpWidget(_app(RuqyahCard(item: _item('a'))));
    for (var i = 0; i < 3; i++) {
      await tester.tap(find.text(i == 0 ? 'Repeat 3×' : '$i/3'));
      await tester.pump();
    }
    expect(find.text('3/3'), findsOneWidget);
    expect(find.byIcon(Icons.check), findsOneWidget);

    await tester.pumpWidget(_app(RuqyahCard(item: _item('b'))));
    expect(find.text('Repeat 3×'), findsOneWidget);
    expect(find.byIcon(Icons.check), findsNothing);
  });

  testWidgets('a changed target restarts the count', (tester) async {
    await tester.pumpWidget(_app(const QRepeatCounter(repeat: 3)));
    await tester.tap(find.text('Repeat 3×'));
    await tester.pump();
    expect(find.text('1/3'), findsOneWidget);

    await tester.pumpWidget(_app(const QRepeatCounter(repeat: 7)));
    expect(find.text('Repeat 7×'), findsOneWidget);
  });
}
