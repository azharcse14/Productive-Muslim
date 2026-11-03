import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:productive_muslim/core/l10n/gen/app_localizations.dart';
import 'package:productive_muslim/core/theme/app_theme.dart';
import 'package:productive_muslim/features/muhasaba/domain/entities/tracker_item.dart';
import 'package:productive_muslim/features/muhasaba/presentation/screens/muhasaba_screen.dart';
import 'package:productive_muslim/features/muhasaba/presentation/state/muhasaba_store.dart';
import 'package:productive_muslim/features/muhasaba/presentation/widgets/item_editor_sheet.dart';

import '../../../helpers/muhasaba_fakes.dart';

Widget _host(MuhasabaStore store, {TrackerItem? existing}) => MaterialApp(
  theme: AppTheme.light(),
  locale: const Locale('en'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(
    body: Builder(
      builder: (context) => TextButton(
        onPressed: () => showItemEditor(context, store, existing: existing),
        child: const Text('open'),
      ),
    ),
  ),
);

void main() {
  testWidgets('archiving shows a toast whose Undo restores the tracker', (
    tester,
  ) async {
    final (store, _) = await makeMuhasabaStore(
      now: () => DateTime(2026, 6, 12, 9),
    );
    addTearDown(store.dispose);
    final azkar = store.items.value.firstWhere((i) => i.id == 'azkar');
    await tester.pumpWidget(_host(store, existing: azkar));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Archive'));
    await tester.tap(find.text('Archive'));
    await tester.pumpAndSettle();

    expect(store.archivedItems.value.map((i) => i.id), contains('azkar'));
    expect(find.text('Archived'), findsOneWidget);
    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(store.items.value.map((i) => i.id), contains('azkar'));
  });

  testWidgets('the target value opens a number dialog', (tester) async {
    final (store, _) = await makeMuhasabaStore(
      now: () => DateTime(2026, 6, 12, 9),
    );
    addTearDown(store.dispose);
    await tester.pumpWidget(_host(store));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Count'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('—'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, '33');
    await tester.tap(find.text('Save').last);
    await tester.pumpAndSettle();
    expect(find.text('33'), findsOneWidget);
  });

  testWidgets('a failed tracker load offers a retry', (tester) async {
    final (store, repo) = await makeMuhasabaStore(
      now: () => DateTime(2026, 6, 12, 9),
    );
    addTearDown(store.dispose);
    addTearDown(GetIt.I.reset);
    // A fresh store whose first load fails.
    repo.failItemReads = true;
    final failing = MuhasabaStore(repo, now: () => DateTime(2026, 6, 12, 9));
    addTearDown(failing.dispose);
    await failing.load();
    GetIt.I.registerSingleton<MuhasabaStore>(failing);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const MuhasabaScreen(),
      ),
    );
    await tester.pump();
    expect(find.text('Try again'), findsOneWidget);

    repo.failItemReads = false;
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(find.text('Try again'), findsNothing);
    expect(failing.loaded.value, isTrue);
  });

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

  testWidgets('the close button closes, confirming unsaved changes first', (
    tester,
  ) async {
    final (store, _) = await makeMuhasabaStore(
      now: () => DateTime(2026, 6, 12, 9),
    );
    addTearDown(store.dispose);
    await tester.pumpWidget(_host(store));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();
    expect(find.text('Add item'), findsNothing);

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Walk');
    await tester.pump();
    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();
    expect(find.text('Discard your changes?'), findsOneWidget);
    await tester.tap(find.text('Discard'));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsNothing);
  });
}
