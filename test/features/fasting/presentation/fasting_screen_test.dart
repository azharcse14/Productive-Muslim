import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:qalbee/core/l10n/gen/app_localizations.dart';
import 'package:qalbee/core/theme/app_theme.dart';
import 'package:qalbee/features/fasting/presentation/screens/fasting_screen.dart';
import 'package:qalbee/features/fasting/presentation/state/fasting_store.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

Widget _app(Widget home) => MaterialApp(
      theme: AppTheme.light(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: home,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    // 2026-06-15 is a Monday — a recommended fast.
    GetIt.I.registerSingleton<FastingStore>(
      FastingStore(
        SharedPreferencesAsync(),
        now: () => DateTime(2026, 6, 15, 10),
      ),
    );
  });

  tearDown(() => GetIt.I.reset());

  group('FastingScreen', () {
    testWidgets('shows the recommended-today card and a log button',
        (tester) async {
      await tester.pumpWidget(_app(const FastingScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Recommended fast today'), findsOneWidget);
      expect(find.text('Monday & Thursday'), findsWidgets);
      expect(find.text('Log today'), findsOneWidget);
    });

    testWidgets('tapping the log button records the fast', (tester) async {
      await tester.pumpWidget(_app(const FastingScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Log today'));
      await tester.pumpAndSettle();

      expect(GetIt.I<FastingStore>().isLogged(DateTime(2026, 6, 15)), isTrue);
      expect(find.text('Logged for today'), findsOneWidget);
    });

    testWidgets('renders the upcoming list', (tester) async {
      await tester.pumpWidget(_app(const FastingScreen()));
      await tester.pumpAndSettle();
      expect(find.text('Upcoming recommended fasts'), findsOneWidget);
    });
  });
}