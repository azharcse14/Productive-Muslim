import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:productive_muslim/core/l10n/gen/app_localizations.dart';
import 'package:productive_muslim/core/theme/app_theme.dart';
import 'package:productive_muslim/core/utils/result.dart';
import 'package:productive_muslim/features/dua_tasbih/domain/entities/dua.dart';
import 'package:productive_muslim/features/dua_tasbih/domain/repositories/dua_repository.dart';
import 'package:productive_muslim/features/dua_tasbih/presentation/screens/asmaul_husna_screen.dart';
import 'package:productive_muslim/features/dua_tasbih/presentation/screens/dua_category_screen.dart';
import 'package:productive_muslim/features/dua_tasbih/presentation/screens/dua_screen.dart';
import 'package:productive_muslim/features/dua_tasbih/presentation/screens/tasbih_screen.dart';
import 'package:productive_muslim/features/dua_tasbih/presentation/state/dua_favorites_store.dart';
import 'package:productive_muslim/features/dua_tasbih/presentation/state/dua_store.dart';
import 'package:productive_muslim/features/dua_tasbih/presentation/state/tasbih_store.dart';
import 'package:productive_muslim/shared/widgets/q_progress_ring.dart';
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
    Dua(
      id: 'me_2',
      arabic: 'الْحَمْدُ لِلَّهِ',
      transliteration: 'Alhamdulillah',
      translationEn: 'All praise is for Allah',
      translationBn: '',
      reference: 'Bukhari 6306',
      repeat: 1,
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
      translationEn: 'O Allah',
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
  Future<Result<List<AsmaName>>> asmaulHusna() async => Result.success([
    for (var n = 1; n <= 99; n++)
      AsmaName(
        number: n,
        arabic: 'اسم $n',
        transliteration: 'Name $n',
        meaningEn: 'Meaning $n',
        meaningBn: '',
      ),
  ]);
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
      ..registerSingleton<DuaFavoritesStore>(favoritesStore)
      ..registerSingleton<TasbihStore>(
        TasbihStore(
          SharedPreferencesAsync(),
          haptic: () {},
          milestoneHaptic: () {},
        ),
      );
  });

  tearDown(() => GetIt.I.reset());

  group('DuaScreen', () {
    testWidgets('renders feature cards and the categories grid', (
      tester,
    ) async {
      await tester.pumpWidget(_app(const DuaScreen()));
      await tester.pump();

      expect(find.text('Dua & Tasbih'), findsOneWidget);
      expect(find.text('Tasbih'), findsOneWidget);
      expect(find.text('Asmaul Husna'), findsOneWidget);
      expect(find.text('Morning & evening'), findsOneWidget);
      expect(find.text('Sleep'), findsOneWidget);
      expect(find.text('2 duas'), findsOneWidget);
      expect(find.text('1 duas'), findsOneWidget);
    });

    testWidgets('tapping a category opens its detail screen', (tester) async {
      await tester.pumpWidget(_app(const DuaScreen()));
      await tester.pump();

      await tester.tap(find.text('Sleep'));
      await tester.pumpAndSettle();

      expect(find.byType(DuaCategoryScreen), findsOneWidget);
      expect(find.text('اللَّهُمَّ'), findsOneWidget);
    });
  });

  group('DuaCategoryScreen', () {
    testWidgets('shows arabic, translation, reference and repeat chip', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(const DuaCategoryScreen(category: _morningCategory)),
      );

      expect(find.text('بِسْمِ اللَّهِ'), findsOneWidget);
      expect(find.text('Bismillah'), findsOneWidget);
      expect(find.text('In the name of Allah'), findsOneWidget);
      expect(find.textContaining('Muslim 2723'), findsOneWidget);
      expect(find.text('Repeat 3×'), findsOneWidget);
      // repeat == 1 renders no chip.
      expect(find.text('Repeat 1×'), findsNothing);
    });
  });

  group('DuaCard repeat counter', () {
    testWidgets('taps count up to the target; long-press resets', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(const DuaCategoryScreen(category: _morningCategory)),
      );
      await tester.tap(find.text('Repeat 3×'));
      await tester.pump();
      expect(find.text('1/3'), findsOneWidget);

      for (final label in ['1/3', '2/3', '3/3']) {
        await tester.tap(find.text(label));
        await tester.pump();
      }
      expect(find.text('3/3'), findsOneWidget); // stops at the target

      await tester.longPress(find.text('3/3'));
      await tester.pump();
      expect(find.text('Repeat 3×'), findsOneWidget);
    });
  });

  group('TasbihScreen', () {
    testWidgets('after-prayer preset advances the phrase at 33 and 66', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(_app(const TasbihScreen()));
      await tester.pump();

      await tester.tap(find.text('After prayer 33·33·34'));
      await tester.pump();
      expect(GetIt.I<TasbihStore>().target.value, 100);
      expect(find.text('SubhanAllah'), findsOneWidget);

      for (var i = 0; i < 33; i++) {
        await tester.tap(find.byType(QProgressRing));
      }
      await tester.pump();
      expect(find.text('Alhamdulillah'), findsOneWidget);
      expect(find.text('0 of 33'), findsOneWidget);

      for (var i = 0; i < 33; i++) {
        await tester.tap(find.byType(QProgressRing));
      }
      await tester.pump();
      expect(find.text('Allahu Akbar'), findsOneWidget);
      expect(find.text('0 of 34'), findsOneWidget);

      // A plain target leaves the preset; the phrase choice persists.
      await tester.tap(find.text('33'));
      await tester.pump();
      await tester.ensureVisible(find.text('Astaghfirullah'));
      await tester.tap(find.text('Astaghfirullah'));
      await tester.pump();
      expect(
        await SharedPreferencesAsync().getString('tasbih_phrase'),
        'astaghfirullah',
      );
    });

    testWidgets('tap increments the displayed count', (tester) async {
      await tester.pumpWidget(_app(const TasbihScreen()));
      await tester.pump();

      expect(find.text('0'), findsOneWidget);

      await tester.tap(find.byType(QProgressRing));
      await tester.pump();

      expect(find.text('1'), findsOneWidget);
      expect(find.text('0'), findsNothing);
    });
  });

  group('AsmaulHusnaScreen', () {
    testWidgets('lists all 99 names from the store', (tester) async {
      await tester.pumpWidget(_app(const AsmaulHusnaScreen()));
      await tester.pump();

      expect(find.text('Name 1'), findsOneWidget);
      expect(find.text('Meaning 1'), findsOneWidget);
      expect(
        tester.widget<ListView>(find.byType(ListView)).semanticChildCount,
        99,
      );
    });
  });
}
