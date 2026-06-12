import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:qalbee/core/l10n/gen/app_localizations.dart';
import 'package:qalbee/core/theme/app_theme.dart';
import 'package:qalbee/core/utils/result.dart';
import 'package:qalbee/features/dua_tasbih/domain/entities/dua.dart';
import 'package:qalbee/features/dua_tasbih/domain/repositories/dua_repository.dart';
import 'package:qalbee/features/dua_tasbih/presentation/screens/asmaul_husna_screen.dart';
import 'package:qalbee/features/dua_tasbih/presentation/screens/dua_category_screen.dart';
import 'package:qalbee/features/dua_tasbih/presentation/screens/dua_screen.dart';
import 'package:qalbee/features/dua_tasbih/presentation/screens/tasbih_screen.dart';
import 'package:qalbee/features/dua_tasbih/presentation/state/dua_store.dart';
import 'package:qalbee/features/dua_tasbih/presentation/state/tasbih_store.dart';
import 'package:qalbee/shared/widgets/q_progress_ring.dart';
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
    GetIt.I
      ..registerSingleton<DuaStore>(duaStore)
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
    testWidgets('renders feature cards and the categories grid',
        (tester) async {
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
    testWidgets('shows arabic, translation, reference and repeat chip',
        (tester) async {
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

  group('TasbihScreen', () {
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
