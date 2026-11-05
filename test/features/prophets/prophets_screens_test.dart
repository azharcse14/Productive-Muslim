import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:productive_muslim/core/l10n/gen/app_localizations.dart';
import 'package:productive_muslim/core/router/app_router.dart';
import 'package:productive_muslim/core/router/routes.dart';
import 'package:productive_muslim/core/theme/app_theme.dart';
import 'package:productive_muslim/core/utils/result.dart';
import 'package:productive_muslim/features/prophets/domain/entities/prophet.dart';
import 'package:productive_muslim/features/prophets/domain/repositories/prophet_repository.dart';
import 'package:productive_muslim/features/prophets/presentation/screens/prophet_screen.dart';
import 'package:productive_muslim/features/prophets/presentation/screens/prophets_screen.dart';
import 'package:productive_muslim/features/prophets/presentation/state/prophets_store.dart';
import 'package:productive_muslim/features/stories/domain/entities/story.dart';
import 'package:productive_muslim/features/stories/domain/repositories/story_repository.dart';
import 'package:productive_muslim/features/stories/presentation/screens/story_screen.dart';
import 'package:productive_muslim/features/stories/presentation/state/stories_store.dart';

import '../../helpers/content_layout_matrix.dart';

final class _Prophets implements ProphetRepository {
  _Prophets({this.fail = false});

  final bool fail;

  @override
  Future<Result<List<Prophet>>> prophets() async => fail
      ? const Result.failure(UnexpectedFailure('boom'))
      : const Result.success([
          Prophet(
            id: 'ibrahim',
            order: 1,
            nameAr: 'إبراهيم',
            nameEn: 'Ibrahim',
            nameBn: 'ইবরাহিম',
            titleEn: 'Khalilullah',
            summaryEn: ['A summary paragraph.'],
            quranMentions: ['14:35-41'],
            storyIds: ['fire', 'missing'],
          ),
          Prophet(
            id: 'ismail',
            order: 2,
            nameAr: 'إسماعيل',
            nameEn: 'Ismail',
            nameBn: 'ইসমাইল',
            parent: 'ibrahim',
          ),
        ]);

  @override
  Future<Result<List<Prophet>>> lineage() async => fail
      ? const Result.failure(UnexpectedFailure('boom'))
      : const Result.success([
          Prophet(
            id: 'azar',
            order: 1,
            nameAr: '',
            nameEn: 'Azar',
            nameBn: 'আযর',
          ),
          Prophet(
            id: 'ibrahim',
            order: 2,
            nameAr: 'إبراهيم',
            nameEn: 'Ibrahim',
            nameBn: 'ইবরাহিম',
            parent: 'azar',
          ),
        ]);
}

final class _Stories implements StoryRepository {
  @override
  Future<Result<List<Story>>> stories(StoryKind kind) async =>
      const Result.success([
        Story(
          id: 'fire',
          titleEn: 'Ibrahim in the fire',
          titleBn: 'আগুনে ইবরাহিম',
          bodyEn: ['Body.'],
          bodyBn: [],
          refs: ['Quran 21:68-70'],
        ),
      ]);
}

GoRouter _router() => GoRouter(
  initialLocation: Routes.prophets.path,
  routes: [
    GoRoute(
      name: Routes.prophets.name,
      path: Routes.prophets.path,
      builder: (_, _) => const ProphetsScreen(),
      routes: [
        GoRoute(
          name: Routes.prophet.name,
          path: Routes.prophet.path,
          builder: (_, state) => ProphetScreen(id: state.pathParameters['id']!),
        ),
      ],
    ),
    GoRoute(
      name: Routes.stories.name,
      path: Routes.stories.path,
      builder: (_, _) => const SizedBox(),
      routes: storiesRoutes(),
    ),
  ],
);

Widget _app(GoRouter router, {LayoutVariant? variant}) => MaterialApp.router(
  theme: variant == null ? AppTheme.light() : variantTheme(variant),
  locale: variant == null ? null : Locale(variant.locale),
  builder: variant == null ? null : variantBuilder(variant),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  routerConfig: router,
);

void main() {
  void register({bool fail = false}) => GetIt.I
    ..registerSingleton(ProphetsStore(_Prophets(fail: fail), _Stories()))
    ..registerFactory(() => StoriesStore(_Stories()));

  tearDown(() => GetIt.I.reset());

  testWidgets('list → detail → story', (tester) async {
    register();
    final router = _router();
    await tester.pumpWidget(_app(router));
    await tester.pumpAndSettle();
    expect(find.text('Ibrahim'), findsOneWidget);
    expect(find.text('Ismail'), findsOneWidget);

    await tester.tap(find.text('Ibrahim'));
    await tester.pumpAndSettle();
    expect(router.state.uri.path, '/prophets/ibrahim');
    expect(find.text('Khalilullah'), findsOneWidget);
    expect(find.text('A summary paragraph.'), findsOneWidget);
    expect(find.text('14:35-41'), findsOneWidget);
    // The unknown story id is skipped, the known one is a button.
    expect(find.text('STORIES'), findsOneWidget);
    await tester.tap(find.text('Ibrahim in the fire'));
    await tester.pumpAndSettle();
    expect(router.state.uri.path, '/stories/quran/fire');
    expect(find.byType(StoryScreen), findsOneWidget);
  });

  testWidgets('a prophet without a summary or stories says coming soon', (
    tester,
  ) async {
    register();
    final router = _router()..go('/prophets/ismail');
    await tester.pumpWidget(_app(router));
    await tester.pumpAndSettle();
    expect(find.text('Summary coming soon.'), findsOneWidget);
    expect(find.text('STORIES'), findsNothing);
  });

  testWidgets('the lineage tab shows everyone; only prophets open', (
    tester,
  ) async {
    register();
    final router = _router();
    await tester.pumpWidget(_app(router));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Full lineage'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Israelite sources'), findsOneWidget);
    await tester.tap(find.text('Azar'));
    await tester.pumpAndSettle();
    expect(router.state.uri.path, '/prophets');
    await tester.tap(find.text('Ibrahim').last);
    await tester.pumpAndSettle();
    expect(router.state.uri.path, '/prophets/ibrahim');
  });

  testWidgets('a failed load offers a retry', (tester) async {
    register(fail: true);
    await tester.pumpWidget(_app(_router()));
    await tester.pumpAndSettle();
    expect(
      find.text("Couldn't load the prophets. Please try again."),
      findsOne,
    );
  });

  for (final (screen, location) in [
    (ProphetsScreen, '/prophets'),
    (ProphetScreen, '/prophets/ibrahim'),
  ]) {
    layoutMatrix('$screen', (tester, v) async {
      register();
      await tester.pumpWidget(_app(_router()..go(location), variant: v));
      await tester.pumpAndSettle();
      expect(find.byType(screen), findsOneWidget);
    });
  }

  layoutMatrix('ProphetsScreen lineage tab', (tester, v) async {
    register();
    await tester.pumpWidget(_app(_router(), variant: v));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Tab).last);
    await tester.pumpAndSettle();
    expect(find.byType(ProphetsScreen), findsOneWidget);
  });
}
