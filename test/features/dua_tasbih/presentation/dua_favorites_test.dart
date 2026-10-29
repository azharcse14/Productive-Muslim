import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:productive_muslim/core/l10n/gen/app_localizations.dart';
import 'package:productive_muslim/core/theme/app_theme.dart';
import 'package:productive_muslim/core/utils/result.dart';
import 'package:productive_muslim/features/dua_tasbih/domain/entities/dua.dart';
import 'package:productive_muslim/features/dua_tasbih/domain/repositories/dua_repository.dart';
import 'package:productive_muslim/features/dua_tasbih/presentation/screens/dua_screen.dart';
import 'package:productive_muslim/features/dua_tasbih/presentation/state/dua_favorites_store.dart';
import 'package:productive_muslim/features/dua_tasbih/presentation/state/dua_store.dart';
import 'package:productive_muslim/features/dua_tasbih/presentation/widgets/dua_card.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

const _morningCategory = DuaCategory(
  id: 'morning_evening',
  icon: 'sun',
  duas: [
    Dua(
      id: 'me_1',
      arabic: 'بِسْمِ اللَّهِ',
      transliteration: 'Bismillah',
      translationEn: 'In the name of Allah',
      translationBn: '',
      reference: 'Muslim 2723',
      repeat: 1,
    ),
  ],
);

final class _FakeDuaRepository implements DuaRepository {
  @override
  Future<Result<List<DuaCategory>>> categories() async =>
      const Result.success([_morningCategory]);

  @override
  Future<Result<List<AsmaName>>> asmaulHusna() async =>
      const Result.success([]);
}

Widget _app(Widget home) => MaterialApp(
  theme: AppTheme.light(),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: home,
);

late DuaFavoritesStore favoritesStore;

void main() {
  setUp(() async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    final duaStore = DuaStore(_FakeDuaRepository());
    await duaStore.load();
    favoritesStore = DuaFavoritesStore(SharedPreferencesAsync());
    await favoritesStore.load();
    GetIt.I
      ..registerSingleton<DuaStore>(duaStore)
      ..registerSingleton<DuaFavoritesStore>(favoritesStore);
  });

  tearDown(() => GetIt.I.reset());

  testWidgets('empty favorites shows the hint', (tester) async {
    await tester.pumpWidget(_app(const DuaScreen()));
    await tester.pump();

    expect(find.text('Favorites'), findsOneWidget);
    expect(
      find.text('Tap the heart on any dua to save it here'),
      findsOneWidget,
    );
  });

  testWidgets('tapping the heart favorites a dua and updates the section', (
    tester,
  ) async {
    await tester.pumpWidget(_app(const DuaCategoryScreenHost()));
    await tester.pump();

    // The category card shows the heart outline initially.
    expect(find.byIcon(Icons.favorite_border), findsOneWidget);

    await tester.tap(find.byIcon(Icons.favorite_border));
    await tester.pump();

    expect(favoritesStore.isFavorite('me_1'), isTrue);
    expect(find.byIcon(Icons.favorite), findsOneWidget);
  });

  testWidgets(
    'favoriting via DuaScreen heart populates the favorites section',
    (tester) async {
      await tester.pumpWidget(_app(const DuaScreen()));
      await tester.pump();

      await favoritesStore.toggle('me_1');
      await tester.pump();

      // The favorited dua now appears in the favorites section.
      expect(find.text('In the name of Allah'), findsOneWidget);
      expect(
        find.text('Tap the heart on any dua to save it here'),
        findsNothing,
      );
    },
  );
}

/// Minimal host that renders a single [DuaCard] for the heart-toggle test.
final class DuaCategoryScreenHost extends StatelessWidget {
  const DuaCategoryScreenHost({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(child: DuaCard(dua: _morningCategory.duas[0])),
  );
}
