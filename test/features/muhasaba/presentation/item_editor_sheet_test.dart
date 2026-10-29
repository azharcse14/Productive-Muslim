import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:productive_muslim/core/l10n/gen/app_localizations.dart';
import 'package:productive_muslim/core/theme/app_theme.dart';
import 'package:productive_muslim/features/muhasaba/presentation/widgets/item_editor_sheet.dart';

import '../../../helpers/muhasaba_fakes.dart';

void main() {
  testWidgets('a failed save keeps the sheet open and reports it', (
    tester,
  ) async {
    final (store, repo) = await makeMuhasabaStore(
      now: () => DateTime(2026, 6, 12, 9),
    );
    addTearDown(store.dispose);
    repo.failItemWrites = true;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showItemEditor(context, store),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Walk');
    await tester.pump();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Add item'), findsOneWidget, reason: 'sheet still open');
    expect(find.text("Couldn't save. Please try again."), findsOneWidget);
    expect(store.items.value.any((i) => i.name == 'Walk'), isFalse);
  });
}
