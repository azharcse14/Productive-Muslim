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
      repeat: 3,
    ),
  ],
);

const _sleepCategory = DuaCategory(
  id: 'sleep',
  icon: 'moon',
  duas: [
    Dua(
      id: 'sl_1',
      arabic: 'اللَّهُمَّ',
      transliteration: 'Allahumma',
      translationEn: 'O Allah, in Your name I die and live',
      translationBn: '',
      reference: 'Bukhari 6324',
      repeat: 1,
    ),
  ],
);

final class _FakeDuaRepository implements DuaRepository {
  @override
  Future<Result<List<DuaCategory>>> categories() async =>
      const Result.success([_morningCategory, _sleepCategory]);

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

void main() {
  setUp(() async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    final duaStore = DuaStore(_FakeDuaRepository());
    await duaStore.load();
    final favoritesStore = DuaFavoritesStore(SharedPreferencesAsync());
    await favoritesStore.load();
    GetIt.I
      ..registerSingleton<DuaStore>(duaStore)
      ..registerSingleton<DuaFavoritesStore>(favoritesStore);
  });

  tearDown(() => GetIt.I.reset());

  testWidgets('search filters to matching duas', (tester) async {
    await tester.pumpWidget(_app(const DuaScreen()));
    await tester.pump();

    await tester.tap(find.byIcon(Icons.search));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Bismillah');
    await tester.pumpAndSettle();

    expect(find.text('In the name of Allah'), findsOneWidget);
    expect(find.text('O Allah, in Your name I die and live'), findsNothing);
  });

  testWidgets('search by reference also matches', (tester) async {
    await tester.pumpWidget(_app(const DuaScreen()));
    await tester.pump();

    await tester.tap(find.byIcon(Icons.search));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'bukhari');
    await tester.pumpAndSettle();

    expect(find.text('O Allah, in Your name I die and live'), findsOneWidget);
    expect(find.text('In the name of Allah'), findsNothing);
  });

  testWidgets('search by category name also matches', (tester) async {
    await tester.pumpWidget(_app(const DuaScreen()));
    await tester.pump();

    await tester.tap(find.byIcon(Icons.search));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'sleep');
    await tester.pumpAndSettle();

    expect(find.text('O Allah, in Your name I die and live'), findsOneWidget);
    expect(find.text('In the name of Allah'), findsNothing);
  });

  testWidgets('gibberish query shows no-results message', (tester) async {
    await tester.pumpWidget(_app(const DuaScreen()));
    await tester.pump();

    await tester.tap(find.byIcon(Icons.search));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'zzqqxx');
    await tester.pumpAndSettle();

    expect(find.text('No duas found'), findsOneWidget);
  });
}
