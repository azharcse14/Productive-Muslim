import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:productive_muslim/core/l10n/gen/app_localizations.dart';
import 'package:productive_muslim/core/theme/app_theme.dart';
import 'package:productive_muslim/features/my_mosque/domain/entities/jamaat_config.dart';
import 'package:productive_muslim/features/my_mosque/domain/entities/mosque_profile.dart';
import 'package:productive_muslim/features/my_mosque/domain/entities/mosque_state.dart';
import 'package:productive_muslim/features/my_mosque/presentation/screens/my_mosque_screen.dart';
import 'package:productive_muslim/features/my_mosque/presentation/state/mosque_store.dart';
import 'package:productive_muslim/features/my_mosque/presentation/widgets/mosque_schedule_section.dart';
import 'package:productive_muslim/features/my_mosque/presentation/widgets/prayer_jamaat_card.dart';
import 'package:productive_muslim/features/settings/domain/entities/prayer_params.dart';

import '../../../helpers/mosque_fakes.dart';

Widget _app() => MaterialApp(
      theme: AppTheme.light(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const MyMosqueScreen(),
    );

void main() {
  late InMemoryMosqueRepository repo;

  Future<void> register([MosqueState initial = const MosqueState()]) async {
    final (store, r) = await makeMosqueStore(initial);
    repo = r;
    GetIt.I.registerSingleton<MosqueStore>(store);
  }

  tearDown(() => GetIt.I.reset());

  group('MyMosqueScreen', () {
    testWidgets('empty state offers adding a profile', (tester) async {
      await register();
      await tester.pumpWidget(_app());
      expect(find.text('Add profile'), findsOneWidget);
    });

    testWidgets('add-profile dialog creates and activates a profile',
        (tester) async {
      await register();
      await tester.pumpWidget(_app());
      await tester.tap(find.text('Add profile'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Home Mosque');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(repo.stored.profiles.single.name, 'Home Mosque');
      expect(repo.stored.activeId, repo.stored.profiles.single.id);
      // Per-prayer cards now visible; Maghrib default offset shown.
      expect(find.text('Maghrib'), findsOneWidget);
      expect(find.textContaining('5 min after waqt starts'), findsOneWidget);
    });

    testWidgets('renders all five prayer cards with mode segments',
        (tester) async {
      // Tall surface so the schedule section + all five cards fit at once.
      tester.view.physicalSize = const Size(1200, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await register(
        const MosqueState(
          profiles: [MosqueProfile(id: 'a', name: 'Home')],
          activeId: 'a',
        ),
      );
      await tester.pumpWidget(_app());
      for (final p in ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha']) {
        expect(find.text(p), findsOneWidget);
      }
      expect(find.text('None'), findsNWidgets(5));
      expect(find.text('Offset'), findsNWidgets(5));
      expect(find.text('Fixed'), findsNWidgets(5));
      expect(find.byType(MosqueScheduleSection), findsOneWidget);
      expect(find.byType(PrayerJamaatCard), findsNWidgets(5));
    });

    testWidgets('choosing Offset persists a default 15-minute entry',
        (tester) async {
      await register(
        const MosqueState(
          profiles: [MosqueProfile(id: 'a', name: 'Home')],
          activeId: 'a',
        ),
      );
      await tester.pumpWidget(_app());
      await tester.tap(find.text('Offset').first); // fajr row
      await tester.pump();
      expect(
        repo.stored.profiles.single.entries[Prayer.fajr],
        const OffsetJamaat(Duration(minutes: 15)),
      );
    });

    testWidgets('profile switcher chips change the active profile',
        (tester) async {
      await register(
        const MosqueState(
          profiles: [
            MosqueProfile(id: 'a', name: 'HomeM'),
            MosqueProfile(id: 'b', name: 'WorkM'),
          ],
          activeId: 'a',
        ),
      );
      await tester.pumpWidget(_app());
      await tester.tap(find.text('WorkM'));
      await tester.pump();
      expect(repo.stored.activeId, 'b');
    });
  });
}
