import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:productive_muslim/core/l10n/gen/app_localizations.dart';
import 'package:productive_muslim/core/theme/app_theme.dart';
import 'package:productive_muslim/features/settings/domain/entities/app_settings.dart';
import 'package:productive_muslim/features/settings/presentation/screens/more_screen.dart';
import 'package:productive_muslim/features/settings/presentation/state/settings_store.dart';

import '../../../helpers/settings_fakes.dart';

void main() {
  tearDown(GetIt.I.reset);

  Future<SettingsStore> pump(WidgetTester tester, AppSettings initial) async {
    final store = await makeSettingsStore(initial);
    GetIt.I.registerSingleton<SettingsStore>(store);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const MoreScreen(),
      ),
    );
    return store;
  }

  testWidgets('badge wall entry follows the Show achievements setting',
      (tester) async {
    final store = await pump(tester, const AppSettings());
    expect(find.byIcon(Icons.emoji_events_outlined), findsNothing);

    await store.setShowAchievements(show: true);
    await tester.pump();
    // It lives in the bottom "You" group.
    await tester.scrollUntilVisible(
      find.byIcon(Icons.emoji_events_outlined),
      200,
    );
    expect(find.byIcon(Icons.emoji_events_outlined), findsOneWidget);
  });
}
