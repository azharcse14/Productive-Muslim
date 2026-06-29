import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:productive_muslim/core/l10n/gen/app_localizations.dart';
import 'package:productive_muslim/core/theme/app_theme.dart';
import 'package:productive_muslim/core/utils/result.dart';
import 'package:productive_muslim/features/dua_tasbih/domain/entities/dua.dart';
import 'package:productive_muslim/features/dua_tasbih/domain/repositories/dua_repository.dart';
import 'package:productive_muslim/features/dua_tasbih/presentation/screens/asma_quiz_screen.dart';
import 'package:productive_muslim/features/dua_tasbih/presentation/state/asma_quiz_store.dart';
import 'package:productive_muslim/features/dua_tasbih/presentation/state/dua_store.dart';
import 'package:productive_muslim/shared/widgets/q_seg_control.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

final class _FakeDuaRepository implements DuaRepository {
  @override
  Future<Result<List<DuaCategory>>> categories() async =>
      const Result.success([]);

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
      ..registerFactory<AsmaQuizStore>(
        () => AsmaQuizStore(
          SharedPreferencesAsync(),
          seed: () => 1,
          correctHaptic: () {},
          wrongHaptic: () {},
          questionCount: 3,
        ),
      );
  });

  tearDown(() => GetIt.I.reset());

  group('AsmaQuizScreen', () {
    testWidgets('renders the mode switch', (tester) async {
      await tester.pumpWidget(_app(const AsmaQuizScreen()));
      await tester.pumpAndSettle();

      expect(find.byType(QSegControl), findsOneWidget);
    });

    testWidgets('answering reveals the Next action', (tester) async {
      await tester.pumpWidget(_app(const AsmaQuizScreen()));
      await tester.pumpAndSettle();

      // Default mode is name->meaning, so options show "Meaning N". The
      // digit guard avoids matching the "Meaning → name" mode switch.
      final firstOption = find.textContaining(RegExp(r'Meaning \d')).first;
      await tester.tap(firstOption);
      await tester.pumpAndSettle();

      // The Next button is the last child of a lazy ListView — scroll it
      // into view so the lazy builder constructs it.
      await tester.scrollUntilVisible(find.text('Next'), 200);
      expect(find.text('Next'), findsOneWidget);
    });
  });
}