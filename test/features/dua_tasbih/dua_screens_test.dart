import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:productive_muslim/core/l10n/gen/app_localizations.dart';
import 'package:productive_muslim/core/theme/app_theme.dart';
import 'package:productive_muslim/features/dua_tasbih/presentation/screens/asmaul_husna_screen.dart';
import 'package:productive_muslim/features/dua_tasbih/presentation/screens/dua_category_screen.dart';
import 'package:productive_muslim/features/dua_tasbih/presentation/screens/dua_screen.dart';
import 'package:productive_muslim/features/dua_tasbih/presentation/state/dua_favorites_store.dart';
import 'package:productive_muslim/features/dua_tasbih/presentation/state/dua_store.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import '../../helpers/content_fakes.dart';

Widget _app(Widget home) => MaterialApp(
      theme: AppTheme.light(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: home,
    );

void main() {
  setUp(() async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    final favoritesStore = DuaFavoritesStore(SharedPreferencesAsync());
    await favoritesStore.load();
    GetIt.I
      ..registerSingleton<DuaStore>(await makeDuaStore())
      ..registerSingleton<DuaFavoritesStore>(favoritesStore);
  });

  tearDown(() => GetIt.I.reset());

  group('Dua screens', () {
    testWidgets('landing renders feature cards and category grid',
        (tester) async {
      await tester.pumpWidget(_app(const DuaScreen()));
      await tester.pump();
      expect(find.text('Tasbih'), findsOneWidget);
      expect(find.text('Asmaul Husna'), findsOneWidget);
      expect(find.text('Morning & evening'), findsOneWidget);
      expect(find.text('1 duas'), findsOneWidget);
    });

    testWidgets('category detail shows arabic, translation, reference',
        (tester) async {
      final store = GetIt.I<DuaStore>();
      final category = store.categories.value.first;
      await tester.pumpWidget(
        _app(DuaCategoryScreen(category: category)),
      );
      await tester.pump();
      expect(find.text('سُبْحَانَ اللَّهِ'), findsOneWidget);
      expect(find.text('Glory be to Allah'), findsOneWidget);
      expect(find.textContaining('Muslim 2691'), findsOneWidget);
      expect(find.textContaining('33'), findsOneWidget); // repeat chip
    });

    testWidgets('asmaul husna lists names with meanings', (tester) async {
      await tester.pumpWidget(_app(const AsmaulHusnaScreen()));
      await tester.pump();
      expect(find.text('Ar-Rahman'), findsOneWidget);
      expect(find.text('The Most Merciful'), findsOneWidget);
    });
  });
}
