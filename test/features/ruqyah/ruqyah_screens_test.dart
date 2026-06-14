import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:qalbee/core/l10n/gen/app_localizations.dart';
import 'package:qalbee/core/theme/app_theme.dart';
import 'package:qalbee/features/ruqyah/presentation/screens/ruqyah_category_screen.dart';
import 'package:qalbee/features/ruqyah/presentation/screens/ruqyah_screen.dart';
import 'package:qalbee/features/ruqyah/presentation/state/ruqyah_store.dart';

import '../../helpers/content_fakes.dart';

Widget _app(Widget home) => MaterialApp(
      theme: AppTheme.light(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: home,
    );

void main() {
  setUp(() async {
    GetIt.I.registerSingleton<RuqyahStore>(await makeRuqyahStore());
  });

  tearDown(() => GetIt.I.reset());

  group('Ruqyah screens', () {
    testWidgets('landing renders guidance card and category grid',
        (tester) async {
      await tester.pumpWidget(_app(const RuqyahScreen()));
      await tester.pump();
      expect(find.text('How to perform ruqyah'), findsOneWidget);
      expect(find.text('Protection'), findsOneWidget);
      expect(find.text('1 passages'), findsOneWidget);
    });

    testWidgets('category detail shows title, arabic, translation, reference',
        (tester) async {
      final category = GetIt.I<RuqyahStore>().categories.value.first;
      await tester.pumpWidget(_app(RuqyahCategoryScreen(category: category)));
      await tester.pump();
      expect(find.text('Ayatul Kursi'), findsOneWidget);
      expect(find.text('اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ'), findsOneWidget);
      expect(find.text('Allah — there is no god but He'), findsOneWidget);
      expect(find.textContaining('2:255'), findsOneWidget);
      expect(find.textContaining('3'), findsWidgets); // repeat chip
    });
  });
}
