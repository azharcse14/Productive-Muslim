import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../features/achievements/presentation/screens/achievements_screen.dart';
import '../../features/calculators/presentation/screens/age_screen.dart';
import '../../features/calculators/presentation/screens/calculators_screen.dart';
import '../../features/calculators/presentation/screens/fitra_screen.dart';
import '../../features/calculators/presentation/screens/inheritance_screen.dart';
import '../../features/calculators/presentation/screens/qaza_screen.dart';
import '../../features/calendar/presentation/screens/calendar_screen.dart';
import '../../features/dua_tasbih/presentation/screens/asma_quiz_screen.dart';
import '../../features/dua_tasbih/presentation/screens/dua_screen.dart';
import '../../features/expenses/presentation/screens/expense_screen.dart';
import '../../features/fasting/presentation/screens/fasting_screen.dart';
import '../../features/hadith/presentation/screens/hadith_detail_screen.dart';
import '../../features/hadith/presentation/screens/hadith_screen.dart';
import '../../features/muhasaba/presentation/screens/muhasaba_screen.dart';
import '../../features/my_mosque/presentation/screens/my_mosque_screen.dart';
import '../../features/notifications/presentation/screens/notification_settings_screen.dart';
import '../../features/onboarding/presentation/screens/lock_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../features/onboarding/presentation/screens/splash_screen.dart';
import '../../features/onboarding/presentation/state/app_lock_store.dart';
import '../../features/prayer_times/domain/entities/special_time.dart';
import '../../features/prayer_times/presentation/screens/home_screen.dart';
import '../../features/prayer_times/presentation/screens/special_times_screen.dart';
import '../../features/qibla/presentation/screens/qibla_screen.dart';
import '../../features/quran/presentation/screens/quran_reader_screen.dart';
import '../../features/quran/presentation/screens/quran_screen.dart';
import '../../features/ramadan/presentation/screens/ramadan_screen.dart';
import '../../features/ramadan/presentation/screens/zakat_screen.dart';
import '../../features/ruqyah/presentation/screens/ruqyah_screen.dart';
import '../../features/settings/presentation/screens/location_picker_screen.dart';
import '../../features/settings/presentation/screens/more_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/settings/presentation/state/settings_store.dart';
import '../../shared/gallery/widget_gallery_screen.dart';
import '../../shared/widgets/q_bottom_nav.dart';
import '../di/locator.dart';
import 'routes.dart';

/// Single source of routes (guide §4). Bottom navigation uses
/// [StatefulShellRoute.indexedStack] so tab state persists.
///
/// Gates: splash is the cold-start entry; incomplete setup redirects to
/// onboarding; an enabled-and-locked app lock redirects to the PIN gate.
GoRouter buildRouter() {
  return GoRouter(
    initialLocation: Routes.splash.path,
    refreshListenable: _RouterRefresh(),
    redirect: (context, state) {
      final path = state.uri.path;
      if (path == Routes.splash.path) {
        return null; // splash decides where to go itself
      }
      _splashDone = true;
      final setupComplete =
          locator<SettingsStore>().settings.value.setupComplete;
      if (!setupComplete) {
        return path == Routes.onboarding.path ||
                path == Routes.locationPicker.path
            ? null
            : Routes.onboarding.path;
      }
      final locked = locator<AppLockStore>().locked.value;
      if (locked) {
        // Remember where the user was so a background re-lock returns
        // them there after unlocking.
        return path == Routes.lock.path
            ? null
            : Uri(
                path: Routes.lock.path,
                queryParameters: {_lockFromParam: state.uri.toString()},
              ).toString();
      }
      if (path == Routes.lock.path) {
        final from = state.uri.queryParameters[_lockFromParam];
        // Only in-app paths; never an absolute URL.
        return from != null && from.startsWith('/') && !from.startsWith('//')
            ? from
            : Routes.home.path;
      }
      if (path == Routes.onboarding.path) {
        return Routes.home.path; // gates passed — nothing to show here
      }
      if (path == Routes.home.path && _pendingDeepLink != null) {
        // Cold-start notification tap: splash handed off to home; open the
        // tapped destination on top of it once home is up (gates re-run).
        final link = _pendingDeepLink!;
        _pendingDeepLink = null;
        WidgetsBinding.instance.addPostFrameCallback((_) => openDeepLink(link));
      }
      return null;
    },
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => QShellScaffold(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                name: Routes.home.name,
                path: Routes.home.path,
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                name: Routes.quran.name,
                path: Routes.quran.path,
                builder: (context, state) => const QuranScreen(),
                routes: [
                  GoRoute(
                    name: Routes.quranAyah.name,
                    path: Routes.quranAyah.path,
                    builder: (context, state) => QuranReaderScreen(
                      surahId:
                          int.tryParse(state.pathParameters['surah'] ?? '') ??
                              1,
                      initialAyah:
                          int.tryParse(state.pathParameters['ayah'] ?? ''),
                    ),
                  ),
                  GoRoute(
                    name: Routes.quranReader.name,
                    path: Routes.quranReader.path,
                    builder: (context, state) => QuranReaderScreen(
                      surahId:
                          int.tryParse(state.pathParameters['surah'] ?? '') ??
                              1,
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                name: Routes.muhasaba.name,
                path: Routes.muhasaba.path,
                builder: (context, state) => const MuhasabaScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                name: Routes.dua.name,
                path: Routes.dua.path,
                builder: (context, state) => const DuaScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                name: Routes.more.name,
                path: Routes.more.path,
                builder: (context, state) => const MoreScreen(),
                routes: [
                  GoRoute(
                    name: Routes.settings.name,
                    path: Routes.settings.path,
                    builder: (context, state) => const SettingsScreen(),
                    routes: [
                      GoRoute(
                        name: Routes.notificationSettings.name,
                        path: Routes.notificationSettings.path,
                        builder: (context, state) =>
                            const NotificationSettingsScreen(),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        name: Routes.splash.name,
        path: Routes.splash.path,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        name: Routes.onboarding.name,
        path: Routes.onboarding.path,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        name: Routes.lock.name,
        path: Routes.lock.path,
        builder: (context, state) => const LockScreen(),
      ),
      GoRoute(
        name: Routes.locationPicker.name,
        path: Routes.locationPicker.path,
        builder: (context, state) => const LocationPickerScreen(),
      ),
      GoRoute(
        name: Routes.myMosque.name,
        path: Routes.myMosque.path,
        builder: (context, state) => const MyMosqueScreen(),
      ),
      GoRoute(
        name: Routes.qibla.name,
        path: Routes.qibla.path,
        builder: (context, state) => const QiblaScreen(),
      ),
      GoRoute(
        name: Routes.specialTimes.name,
        path: Routes.specialTimes.path,
        builder: (context, state) {
          final extra =
              state.extra as (SpecialKind, List<SpecialWindow>)?;
          return SpecialTimesScreen(
            kind: extra?.$1 ?? SpecialKind.forbidden,
            windows: extra?.$2 ?? const [],
          );
        },
      ),
      GoRoute(
        name: Routes.ramadan.name,
        path: Routes.ramadan.path,
        builder: (context, state) => const RamadanScreen(),
      ),
      GoRoute(
        name: Routes.calendar.name,
        path: Routes.calendar.path,
        builder: (context, state) => const CalendarScreen(),
      ),
      GoRoute(
        name: Routes.hadith.name,
        path: Routes.hadith.path,
        builder: (context, state) => const HadithScreen(),
        routes: [
          GoRoute(
            name: Routes.hadithItem.name,
            path: Routes.hadithItem.path,
            builder: (context, state) =>
                HadithDetailScreen(id: state.pathParameters['id'] ?? ''),
          ),
        ],
      ),
      GoRoute(
        name: Routes.ruqyah.name,
        path: Routes.ruqyah.path,
        builder: (context, state) => const RuqyahScreen(),
      ),
      GoRoute(
        name: Routes.asmaQuiz.name,
        path: Routes.asmaQuiz.path,
        builder: (context, state) => const AsmaQuizScreen(),
      ),
      GoRoute(
        name: Routes.fasting.name,
        path: Routes.fasting.path,
        builder: (context, state) => const FastingScreen(),
      ),
      GoRoute(
        name: Routes.expenses.name,
        path: Routes.expenses.path,
        builder: (context, state) => const ExpenseScreen(),
      ),
      GoRoute(
        name: Routes.achievements.name,
        path: Routes.achievements.path,
        builder: (context, state) => const AchievementsScreen(),
      ),
      GoRoute(
        name: Routes.zakat.name,
        path: Routes.zakat.path,
        builder: (context, state) => const ZakatScreen(),
      ),
      GoRoute(
        name: Routes.calculators.name,
        path: Routes.calculators.path,
        builder: (context, state) => const CalculatorsScreen(),
      ),
      GoRoute(
        name: Routes.fitra.name,
        path: Routes.fitra.path,
        builder: (context, state) => const FitraScreen(),
      ),
      GoRoute(
        name: Routes.qaza.name,
        path: Routes.qaza.path,
        builder: (context, state) => const QazaScreen(),
      ),
      GoRoute(
        name: Routes.faraid.name,
        path: Routes.faraid.path,
        builder: (context, state) => const InheritanceScreen(),
      ),
      GoRoute(
        name: Routes.age.name,
        path: Routes.age.path,
        builder: (context, state) => const AgeScreen(),
      ),
      GoRoute(
        name: Routes.gallery.name,
        path: Routes.gallery.path,
        builder: (context, state) => const WidgetGalleryScreen(),
      ),
    ],
  );
}

/// Query parameter carrying the pre-lock location through the PIN gate.
const _lockFromParam = 'from';

/// The app's router (one per process; also the target for deep links from
/// outside the widget tree, e.g. notification taps).
final GoRouter appRouter = buildRouter();

String? _pendingDeepLink;

/// Branch roots of the tab shell; deep links under these keep their tab.
final _shellRoots = [
  Routes.home.path,
  Routes.quran.path,
  Routes.muhasaba.path,
  Routes.dua.path,
  Routes.more.path,
];
var _splashDone = false;

/// Opens an in-app [location] from outside the widget tree (notification
/// taps). While the splash still owns cold-start navigation the link is
/// parked and applied when splash hands off to home.
void openDeepLink(String location) {
  // Only in-app paths; never an absolute URL.
  if (!location.startsWith('/') || location.startsWith('//')) {
    return;
  }
  if (_splashDone) {
    final inShell = _shellRoots.any(
      (root) => location == root || location.startsWith('$root/'),
    );
    if (inShell) {
      appRouter.go(location);
    } else {
      // Top-level pages have no tab underneath: put home below them so the
      // back arrow / system back returns into the app instead of exiting.
      // Push after the go has been applied, or it stacks on the old page.
      appRouter.go(Routes.home.path);
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => unawaited(appRouter.push<void>(location)),
      );
    }
  } else {
    _pendingDeepLink = location;
  }
}

/// Re-runs the router redirect whenever a gate signal flips
/// (lock/unlock, setup completion).
final class _RouterRefresh extends ChangeNotifier {
  _RouterRefresh() {
    _stop = effect(() {
      locator<AppLockStore>().locked.value;
      locator<SettingsStore>().settings.value.setupComplete;
      notifyListeners();
    });
  }

  late final EffectCleanup _stop;

  @override
  void dispose() {
    _stop();
    super.dispose();
  }
}

/// Shell scaffold holding the persistent bottom navigation.
final class QShellScaffold extends StatelessWidget {
  const QShellScaffold({required this.shell, super.key});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    return QBottomNavScaffold(
      currentIndex: shell.currentIndex,
      onSelect: (index) => shell.goBranch(
        index,
        initialLocation: index == shell.currentIndex,
      ),
      body: shell,
    );
  }
}
