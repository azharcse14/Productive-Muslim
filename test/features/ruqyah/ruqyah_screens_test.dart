import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:productive_muslim/core/l10n/gen/app_localizations.dart';
import 'package:productive_muslim/core/router/app_router.dart';
import 'package:productive_muslim/core/router/routes.dart';
import 'package:productive_muslim/core/theme/app_theme.dart';
import 'package:productive_muslim/core/utils/result.dart';
import 'package:productive_muslim/features/ruqyah/domain/entities/ruqyah.dart';
import 'package:productive_muslim/features/ruqyah/domain/repositories/ruqyah_repository.dart';
import 'package:productive_muslim/features/ruqyah/presentation/screens/ruqyah_category_screen.dart';
import 'package:productive_muslim/features/ruqyah/presentation/screens/ruqyah_screen.dart';
import 'package:productive_muslim/features/ruqyah/presentation/screens/tibb_nabawi_screen.dart';
import 'package:productive_muslim/features/ruqyah/presentation/state/ruqyah_store.dart';

import '../../helpers/content_fakes.dart';
import '../../helpers/content_layout_matrix.dart';

Widget _app(Widget home, {Locale? locale}) => MaterialApp(
  theme: AppTheme.light(),
  locale: locale,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: home,
);

/// The fake's passages under "Anxiety, grief & distress".
final class _TwoLineCategory implements RuqyahRepository {
  @override
  Future<Result<List<RuqyahCategory>>> categories() async =>
      (await FakeRuqyahRepository().categories()).map(
        (all) => [
          for (final c in all)
            RuqyahCategory(id: 'anxiety_grief', icon: c.icon, items: c.items),
        ],
      );
}

void main() {
  setUp(() async {
    GetIt.I
      ..registerSingleton<RuqyahStore>(await makeRuqyahStore())
      ..registerSingleton<RuqyahStore>(
        await makeRuqyahStore(),
        instanceName: RuqyahStore.tibbNabawi,
      );
  });

  tearDown(() => GetIt.I.reset());

  group('Ruqyah screens', () {
    testWidgets('landing renders guidance card and category grid', (
      tester,
    ) async {
      await tester.pumpWidget(_app(const RuqyahScreen()));
      await tester.pump();
      expect(find.text('How to perform ruqyah'), findsOneWidget);
      expect(find.text('Protection'), findsOneWidget);
      expect(find.text('1 passages'), findsOneWidget);
    });

    testWidgets('a category tile opens its named route (back returns)', (
      tester,
    ) async {
      final router = GoRouter(
        initialLocation: Routes.ruqyah.path,
        routes: [
          GoRoute(
            path: Routes.ruqyah.path,
            builder: (_, _) => const RuqyahScreen(),
            routes: ruqyahRoutes(),
          ),
        ],
      );
      await tester.pumpWidget(
        MaterialApp.router(
          theme: AppTheme.light(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      );
      await tester.pump();
      await tester.tap(find.text('Protection'));
      await tester.pumpAndSettle();
      final id = GetIt.I<RuqyahStore>().categories.value.first.id;
      expect(router.state.uri.path, '/ruqyah/category/$id');
      expect(find.byType(RuqyahCategoryScreen), findsOneWidget);
      router.pop();
      await tester.pumpAndSettle();
      expect(router.state.uri.path, Routes.ruqyah.path);
    });

    testWidgets('an unknown category id shows not available', (tester) async {
      await tester.pumpWidget(_app(const RuqyahCategoryScreen(id: 'nope')));
      await tester.pump();
      expect(find.text("This page isn't available."), findsOneWidget);
    });

    testWidgets('category detail shows title, arabic, translation, reference', (
      tester,
    ) async {
      final category = GetIt.I<RuqyahStore>().categories.value.first;
      await tester.pumpWidget(_app(RuqyahCategoryScreen(id: category.id)));
      await tester.pump();
      expect(find.text('Ayatul Kursi'), findsOneWidget);
      expect(find.text('اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ'), findsOneWidget);
      expect(find.text('Allah — there is no god but He'), findsOneWidget);
      expect(find.textContaining('2:255'), findsOneWidget);
      expect(find.textContaining('3'), findsWidgets); // repeat chip
    });

    testWidgets('Bangla shows the Bengali-script transliteration', (
      tester,
    ) async {
      final category = GetIt.I<RuqyahStore>().categories.value.first;
      await tester.pumpWidget(
        _app(RuqyahCategoryScreen(id: category.id), locale: const Locale('bn')),
      );
      await tester.pump();
      expect(find.text('আল্লা-হু লা- ইলা-হা ইল্লা- হুওয়া'), findsOneWidget);
      expect(find.text('Allahu la ilaha illa huwa'), findsNothing);
      // Screen readers speak the Arabic as the Bangla transliteration too.
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is Text &&
              w.semanticsLabel == 'আল্লা-হু লা- ইলা-হা ইল্লা- হুওয়া',
        ),
        findsOneWidget,
      );
    });

    testWidgets('Tibb an-Nabawi lists its cards lazily under the note', (
      tester,
    ) async {
      await tester.pumpWidget(_app(const TibbNabawiScreen()));
      await tester.pump();
      expect(find.text('Ayatul Kursi'), findsOneWidget);
      // One builder-backed list: the note plus one row per card.
      final list = tester.widget<ListView>(find.byType(ListView));
      expect(list.childrenDelegate, isA<SliverChildBuilderDelegate>());
    });
  });
  Future<void> pumpVariant(
    WidgetTester tester,
    LayoutVariant v,
    Widget home,
  ) async {
    await tester.pumpWidget(variantApp(home, v));
    await tester.pumpAndSettle();
  }

  layoutMatrix('RuqyahScreen', (tester, v) async {
    // A two-line category name, as real data has.
    final store = RuqyahStore(_TwoLineCategory());
    await store.load();
    GetIt.I
      ..unregister<RuqyahStore>()
      ..registerSingleton<RuqyahStore>(store);
    await pumpVariant(tester, v, const RuqyahScreen());
  });
  layoutMatrix(
    'RuqyahCategoryScreen',
    (tester, v) =>
        pumpVariant(tester, v, const RuqyahCategoryScreen(id: 'protection')),
  );
  layoutMatrix(
    'TibbNabawiScreen',
    (tester, v) => pumpVariant(tester, v, const TibbNabawiScreen()),
  );
}
