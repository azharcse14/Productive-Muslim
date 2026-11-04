import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:productive_muslim/core/l10n/gen/app_localizations.dart';
import 'package:productive_muslim/core/router/app_router.dart';
import 'package:productive_muslim/core/router/routes.dart';
import 'package:productive_muslim/core/theme/app_theme.dart';
import 'package:productive_muslim/core/utils/result.dart';
import 'package:productive_muslim/features/stories/domain/entities/story.dart';
import 'package:productive_muslim/features/stories/domain/repositories/story_repository.dart';
import 'package:productive_muslim/features/stories/presentation/screens/stories_screen.dart';
import 'package:productive_muslim/features/stories/presentation/screens/story_screen.dart';
import 'package:productive_muslim/features/stories/presentation/state/stories_store.dart';

final class _FakeRepo implements StoryRepository {
  _FakeRepo({this.fail = false});

  final bool fail;

  @override
  Future<Result<List<Story>>> stories(StoryKind kind) async => fail
      ? const Result.failure(UnexpectedFailure('boom'))
      : Result.success([
          Story(
            id: '${kind.name}_1',
            titleEn: '${kind.name} story',
            titleBn: '${kind.name} গল্প',
            bodyEn: const ['First paragraph.', 'Second paragraph.'],
            bodyBn: const ['প্রথম অনুচ্ছেদ।'],
            refs: [kind == StoryKind.quran ? 'Quran 12:4-101' : 'Bukhari 3450'],
          ),
        ]);
}

Widget _router(String location, {Locale? locale}) => MaterialApp.router(
  theme: AppTheme.light(),
  locale: locale,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  routerConfig: GoRouter(
    initialLocation: location,
    routes: [
      GoRoute(
        name: Routes.stories.name,
        path: Routes.stories.path,
        builder: (_, state) => StoriesScreen(
          initialKind:
              StoryKind.values.asNameMap()[state.uri.queryParameters['kind']] ??
              StoryKind.quran,
        ),
        routes: storiesRoutes(),
      ),
    ],
  ),
);

void main() {
  void register({bool fail = false}) =>
      GetIt.I.registerFactory(() => StoriesStore(_FakeRepo(fail: fail)));

  tearDown(() => GetIt.I.reset());

  testWidgets('list → detail shows title, paragraphs and refs', (tester) async {
    register();
    await tester.pumpWidget(_router(Routes.stories.path));
    await tester.pumpAndSettle();
    await tester.tap(find.text('quran story'));
    await tester.pumpAndSettle();
    expect(find.byType(StoryScreen), findsOneWidget);
    expect(find.text('First paragraph.'), findsOneWidget);
    expect(find.text('Second paragraph.'), findsOneWidget);
    expect(find.text('Quran 12:4-101'), findsOneWidget);
  });

  testWidgets('?kind=hadith opens the Hadith tab', (tester) async {
    register();
    await tester.pumpWidget(_router('${Routes.stories.path}?kind=hadith'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('hadith story'));
    await tester.pumpAndSettle();
    expect(find.text('Bukhari 3450'), findsOneWidget);
  });

  testWidgets('Bangla shows the Bangla title and body', (tester) async {
    register();
    await tester.pumpWidget(
      _router('/stories/quran/quran_1', locale: const Locale('bn')),
    );
    await tester.pumpAndSettle();
    expect(find.text('quran গল্প'), findsWidgets);
    expect(find.text('প্রথম অনুচ্ছেদ।'), findsOneWidget);
    expect(find.text('First paragraph.'), findsNothing);
  });

  testWidgets('unknown kind or id is not available', (tester) async {
    register();
    await tester.pumpWidget(_router('/stories/poems/quran_1'));
    await tester.pumpAndSettle();
    expect(find.text("This page isn't available."), findsOneWidget);
  });

  testWidgets('a failed load offers a retry', (tester) async {
    register(fail: true);
    await tester.pumpWidget(_router(Routes.stories.path));
    await tester.pumpAndSettle();
    expect(
      find.text("Couldn't load the stories. Please try again."),
      findsOneWidget,
    );
  });
}
