import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:productive_muslim/core/l10n/gen/app_localizations.dart';
import 'package:productive_muslim/core/theme/app_theme.dart';
import 'package:productive_muslim/core/utils/hijri_date.dart';
import 'package:productive_muslim/features/settings/domain/entities/app_settings.dart';
import 'package:productive_muslim/features/settings/domain/entities/location_config.dart';
import 'package:productive_muslim/features/settings/domain/repositories/zoned_clock.dart';
import 'package:productive_muslim/features/settings/presentation/screens/more_screen.dart';
import 'package:productive_muslim/features/settings/presentation/state/settings_store.dart';

import '../../../helpers/settings_fakes.dart';

final class _MutableClock implements ZonedClock {
  _MutableClock(this.now);

  DateTime now;

  @override
  DateTime nowAt(LocationConfig location) => now;

  @override
  DateTime instantAt(LocationConfig location, DateTime instant) => instant;

  @override
  DateTime utcInstantOf(LocationConfig location, DateTime wall) => wall;
}

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

  testWidgets('badge wall entry follows the Show achievements setting', (
    tester,
  ) async {
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

  testWidgets('app bar has a Settings shortcut', (tester) async {
    await pump(tester, const AppSettings());
    expect(find.byTooltip('Settings'), findsOneWidget);
  });

  testWidgets('Ramadan rises overnight while the tab stays open', (
    tester,
  ) async {
    // The last day of Sha'ban 1448, a few minutes before midnight.
    var eve = DateTime(2027);
    while (HijriDate.fromGregorian(eve.add(const Duration(days: 1))).month !=
        HijriDate.ramadanMonth) {
      eve = eve.add(const Duration(days: 1));
    }
    final clock = _MutableClock(
      eve.add(const Duration(hours: 23, minutes: 59)),
    );
    GetIt.I.registerSingleton<ZonedClock>(clock);
    await pump(
      tester,
      const AppSettings(location: GpsLocation(latitude: 23.8, longitude: 90.4)),
    );
    bool promoted() {
      final ramadan = find.text('Ramadan');
      return ramadan.evaluate().isNotEmpty &&
          tester.getTopLeft(ramadan).dy <
              tester.getTopLeft(find.text('WORSHIP')).dy;
    }

    expect(promoted(), isFalse);
    clock.now = clock.now.add(const Duration(minutes: 1));
    await tester.pump(const Duration(minutes: 1));
    await tester.pumpAndSettle();
    expect(promoted(), isTrue);
    await tester.pumpWidget(const SizedBox()); // cancels the ticker
  });
}
