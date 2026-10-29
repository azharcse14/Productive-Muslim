import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:productive_muslim/features/prayer_times/presentation/state/home_store.dart';

/// [testWidgets] for trees that mount Home. Home's dispose leaves the
/// app-wide [HomeStore] on its slow tick (as in the app), so the tree is
/// unmounted and the store stopped before the binding checks for pending
/// timers. Register the store as a lazy singleton, as the app does.
void testHomeWidgets(String description, WidgetTesterCallback body) =>
    testWidgets(description, (tester) async {
      await body(tester);
      await tester.pumpWidget(const SizedBox());
      if (GetIt.I.isRegistered<HomeStore>() &&
          GetIt.I.checkLazySingletonInstanceExists<HomeStore>()) {
        GetIt.I<HomeStore>().stop();
      }
    });
