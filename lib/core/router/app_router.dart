import 'dart:async';

import 'package:flutter/foundation.dart' show SynchronousFuture, kDebugMode;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../features/achievements/presentation/screens/achievements_screen.dart';
import '../../features/achievements/presentation/state/achievement_store.dart';
import '../../features/achievements/presentation/widgets/badge_unlock_listener.dart';
import '../../features/calculators/presentation/screens/age_screen.dart';
import '../../features/calculators/presentation/screens/calculators_screen.dart';
import '../../features/calculators/presentation/screens/fitra_screen.dart';
import '../../features/calculators/presentation/screens/inheritance_screen.dart';
import '../../features/calculators/presentation/screens/qaza_screen.dart';
import '../../features/calendar/presentation/screens/calendar_screen.dart';
import '../../features/dua_tasbih/domain/entities/dua.dart';
import '../../features/dua_tasbih/presentation/screens/asma_quiz_screen.dart';
import '../../features/dua_tasbih/presentation/screens/asmaul_husna_screen.dart';
import '../../features/dua_tasbih/presentation/screens/dua_category_screen.dart';
import '../../features/dua_tasbih/presentation/screens/dua_screen.dart';
import '../../features/dua_tasbih/presentation/screens/tasbih_screen.dart';
import '../../features/expenses/presentation/screens/expense_screen.dart';
import '../../features/fasting/presentation/screens/fasting_screen.dart';
import '../../features/hadith/presentation/screens/hadith_book_route.dart';
import '../../features/hadith/presentation/screens/hadith_books_screen.dart';
import '../../features/hadith/presentation/screens/hadith_detail_screen.dart';
import '../../features/hadith/presentation/screens/hadith_screen.dart';
import '../../features/hadith/presentation/screens/hadith_search_screen.dart';
import '../../features/hadith/presentation/screens/hadith_topic_screen.dart';
import '../../features/health/presentation/screens/health_screen.dart';
import '../../features/muhasaba/presentation/screens/muhasaba_screen.dart';
import '../../features/muhasaba/presentation/state/muhasaba_store.dart';
import '../../features/my_mosque/presentation/screens/my_mosque_screen.dart';
import '../../features/notifications/presentation/screens/notification_settings_screen.dart';
import '../../features/notifications/presentation/screens/notifications_screen.dart';
import '../../features/onboarding/presentation/screens/lock_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../features/onboarding/presentation/screens/section_lock_gate.dart';
import '../../features/onboarding/presentation/screens/splash_screen.dart';
import '../../features/onboarding/presentation/state/app_lock_store.dart';
import '../../features/prayer_times/domain/entities/special_time.dart';
import '../../features/prayer_times/presentation/screens/home_screen.dart';
import '../../features/prayer_times/presentation/screens/special_times_screen.dart';
import '../../features/prayer_times/presentation/state/home_store.dart';
import '../../features/qibla/presentation/screens/qibla_screen.dart';
import '../../features/quran/presentation/screens/quran_reader_screen.dart';
import '../../features/quran/presentation/screens/quran_screen.dart';
import '../../features/ramadan/presentation/screens/ramadan_screen.dart';
import '../../features/ramadan/presentation/screens/zakat_screen.dart';
import '../../features/ruqyah/presentation/screens/ruqyah_category_screen.dart';
import '../../features/ruqyah/presentation/screens/ruqyah_screen.dart';
import '../../features/ruqyah/presentation/screens/tibb_nabawi_screen.dart';
import '../../features/settings/presentation/screens/credits_screen.dart';
import '../../features/settings/presentation/screens/location_picker_screen.dart';
import '../../features/settings/presentation/screens/more_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/stories/domain/entities/story.dart';
import '../../features/stories/presentation/screens/stories_screen.dart';
import '../../features/stories/presentation/screens/story_screen.dart';
import '../../shared/gallery/widget_gallery_screen.dart';
import '../../shared/widgets/q_bottom_nav.dart';
import '../di/locator.dart';
import '../settings/settings_store.dart';
import 'routes.dart';

/// Single source of routes (guide §4). Bottom navigation uses
/// [StatefulShellRoute.indexedStack] so tab state persists.
///
/// Gates: splash is the cold-start entry; incomplete setup redirects to
/// onboarding; an enabled-and-locked app lock redirects to the PIN gate on
/// cold start only. Later (background) re-locks are covered by the root
/// [LockOverlay] instead, so the navigation stack, tab
/// state and pushed pages survive the lock.
///
/// The bottom bar shows on the five tab roots only: every secondary page
/// is full-screen on the root navigator, whether it is a top-level route
/// (Qibla, Calendar, …) or nested under a tab's path for deep links
/// (Settings, the Quran reader, dua categories), which then keeps that
/// tab's state underneath.
GoRouter buildRouter() {
  // Set once the lock gate has been passed; from then on the router never
  // redirects to /lock again.
  var lockGatePassed = false;
  final root = GlobalKey<NavigatorState>();
  return GoRouter(
    navigatorKey: root,
    initialLocation: Routes.splash.path,
    refreshListenable: _RouterRefresh(),
    // An unknown path (a stale notification payload, an old deep link)
    // goes home; go_router's default page is English-only and its Home
    // button targets '/', which isn't a route — a dead end.
    onException: (_, _, router) => router.go(Routes.home.path),
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
      if (locked && !lockGatePassed) {
        // Remember where the user was headed so unlocking lands there.
        return path == Routes.lock.path
            ? null
            : Uri(
                path: Routes.lock.path,
                queryParameters: {_lockFromParam: state.uri.toString()},
              ).toString();
      }
      if (!locked) {
        lockGatePassed = true;
      }
      if (path == Routes.lock.path) {
        if (_pendingDeepLink != null) {
          return Routes.home.path; // home opens the link parked at the gate
        }
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
                builder: (context, state) =>
                    HomeScreen(sectionLock: locator<AppLockStore>()),
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
                    parentNavigatorKey: root,
                    // Out-of-range / non-numeric surah → back to the index.
                    redirect: (context, state) => switch (int.tryParse(
                      state.pathParameters['surah'] ?? '',
                    )) {
                      final id? when id >= 1 && id <= 114 => null,
                      _ => Routes.quran.path,
                    },
                    builder: (context, state) => QuranReaderScreen(
                      surahId: int.parse(state.pathParameters['surah']!),
                      initialAyah: int.tryParse(
                        state.pathParameters['ayah'] ?? '',
                      ),
                    ),
                  ),
                  GoRoute(
                    name: Routes.quranReader.name,
                    path: Routes.quranReader.path,
                    parentNavigatorKey: root,
                    // Out-of-range / non-numeric surah → back to the index.
                    redirect: (context, state) => switch (int.tryParse(
                      state.pathParameters['surah'] ?? '',
                    )) {
                      final id? when id >= 1 && id <= 114 => null,
                      _ => Routes.quran.path,
                    },
                    builder: (context, state) => QuranReaderScreen(
                      surahId: int.parse(state.pathParameters['surah']!),
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
                builder: (context, state) => SectionLockGate(
                  lock: locator<AppLockStore>(),
                  child: const MuhasabaScreen(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                name: Routes.dua.name,
                path: Routes.dua.path,
                // ?category= (focus end notification payloads) opens that
                // category, with the Dua tab beneath it.
                redirect: (context, state) =>
                    switch (state.uri.queryParameters['category']) {
                      final id?
                          when id.isNotEmpty &&
                              state.uri.path == Routes.dua.path =>
                        state.namedLocation(
                          Routes.duaCategory.name,
                          pathParameters: {'id': id},
                        ),
                      _ => null,
                    },
                builder: (context, state) => const DuaScreen(),
                routes: duaRoutes(root),
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
                    parentNavigatorKey: root,
                    builder: (context, state) => const SettingsScreen(),
                    routes: [
                      GoRoute(
                        name: Routes.credits.name,
                        path: Routes.credits.path,
                        parentNavigatorKey: root,
                        builder: (context, state) => const CreditsScreen(),
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
        name: Routes.notifications.name,
        path: Routes.notifications.path,
        builder: (context, state) => const NotificationsScreen(),
        routes: [
          GoRoute(
            name: Routes.notificationSettings.name,
            path: Routes.notificationSettings.path,
            builder: (context, state) => const NotificationSettingsScreen(),
          ),
        ],
      ),
      GoRoute(
        name: Routes.notificationFocus.name,
        path: Routes.notificationFocus.path,
        builder: (context, state) => const JamaatFocusSettingsScreen(),
      ),
      GoRoute(
        name: Routes.locationPicker.name,
        path: Routes.locationPicker.path,
        builder: (context, state) => LocationPickerScreen(
          autoGps: state.uri.queryParameters['gps'] == '1',
        ),
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
          final extra = state.extra as (SpecialKind, List<SpecialWindow>)?;
          final kind = extra?.$1 ?? SpecialKind.forbidden;
          // No extra (deep link, restored route): read today's windows.
          return SpecialTimesScreen(
            kind: kind,
            windows:
                extra?.$2 ??
                [
                  for (final w in locator<HomeStore>().specialWindows.value)
                    if (w.kind == kind) w,
                ],
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
        routes: hadithRoutes(),
      ),
      GoRoute(
        name: Routes.ruqyah.name,
        path: Routes.ruqyah.path,
        builder: (context, state) => const RuqyahScreen(),
        routes: ruqyahRoutes(),
      ),
      GoRoute(
        name: Routes.asmaulHusna.name,
        path: Routes.asmaulHusna.path,
        builder: (context, state) => const AsmaulHusnaScreen(),
      ),
      GoRoute(
        name: Routes.rasulNames.name,
        path: Routes.rasulNames.path,
        builder: (context, state) =>
            const AsmaulHusnaScreen(nameSet: NameSet.rasul),
      ),
      GoRoute(
        name: Routes.rasulQuiz.name,
        path: Routes.rasulQuiz.path,
        builder: (context, state) =>
            const AsmaQuizScreen(nameSet: NameSet.rasul),
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
        name: Routes.health.name,
        path: Routes.health.path,
        // Its habits are Muhasaba trackers.
        builder: (context, state) => SectionLockGate(
          lock: locator<AppLockStore>(),
          child: const HealthScreen(),
        ),
      ),
      GoRoute(
        name: Routes.stories.name,
        path: Routes.stories.path,
        builder: (context, state) => StoriesScreen(
          initialKind:
              StoryKind.values.asNameMap()[state.uri.queryParameters['kind']] ??
              StoryKind.quran,
        ),
        routes: storiesRoutes(),
      ),
      GoRoute(
        name: Routes.tibbNabawi.name,
        path: Routes.tibbNabawi.path,
        builder: (context, state) => const TibbNabawiScreen(),
      ),
      GoRoute(
        name: Routes.achievements.name,
        path: Routes.achievements.path,
        // Badges are built from Muhasaba history.
        builder: (context, state) => SectionLockGate(
          lock: locator<AppLockStore>(),
          child: const AchievementsScreen(),
        ),
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
      if (kDebugMode)
        GoRoute(
          name: Routes.gallery.name,
          path: Routes.gallery.path,
          builder: (context, state) => const WidgetGalleryScreen(),
        ),
    ],
  );
}

/// Dua tab sub-pages, full-screen on the [root] navigator.
List<RouteBase> duaRoutes(GlobalKey<NavigatorState> root) => [
  GoRoute(
    name: Routes.duaCategory.name,
    path: Routes.duaCategory.path,
    parentNavigatorKey: root,
    builder: (context, state) =>
        DuaCategoryScreen(id: state.pathParameters['id']!),
  ),
  GoRoute(
    name: Routes.tasbih.name,
    path: Routes.tasbih.path,
    parentNavigatorKey: root,
    builder: (context, state) => const TasbihScreen(),
  ),
];

/// Hadith sub-pages: everything is addressed by id, the screens resolve
/// it through their stores.
List<RouteBase> hadithRoutes() => [
  GoRoute(
    name: Routes.hadithItem.name,
    path: Routes.hadithItem.path,
    builder: (context, state) =>
        HadithDetailScreen(id: state.pathParameters['id'] ?? ''),
  ),
  GoRoute(
    name: Routes.hadithTopic.name,
    path: Routes.hadithTopic.path,
    builder: (context, state) =>
        HadithTopicScreen(id: state.pathParameters['topic']!),
  ),
  GoRoute(
    name: Routes.hadithBooks.name,
    path: Routes.hadithBooks.path,
    builder: (context, state) => const HadithBooksScreen(),
    routes: [
      // Before ':book', or "search" would read as a book id.
      GoRoute(
        name: Routes.hadithSearch.name,
        path: Routes.hadithSearch.path,
        builder: (context, state) => const HadithSearchScreen(),
      ),
      GoRoute(
        name: Routes.hadithBook.name,
        path: Routes.hadithBook.path,
        builder: (context, state) =>
            HadithBookRoute(bookId: state.pathParameters['book']!),
        routes: [
          GoRoute(
            name: Routes.hadithSection.name,
            path: Routes.hadithSection.path,
            // A non-numeric chapter → that book's chapter list.
            redirect: (context, state) =>
                int.tryParse(state.pathParameters['section'] ?? '') == null
                ? state.namedLocation(
                    Routes.hadithBook.name,
                    pathParameters: {'book': state.pathParameters['book']!},
                  )
                : null,
            builder: (context, state) => HadithBookRoute(
              bookId: state.pathParameters['book']!,
              section: int.parse(state.pathParameters['section']!),
              languageCode: state.uri.queryParameters['lang'],
              focusNumber: int.tryParse(state.uri.queryParameters['n'] ?? ''),
            ),
          ),
        ],
      ),
    ],
  ),
];

/// Ruqyah sub-pages.
List<RouteBase> ruqyahRoutes() => [
  GoRoute(
    name: Routes.ruqyahCategory.name,
    path: Routes.ruqyahCategory.path,
    builder: (context, state) =>
        RuqyahCategoryScreen(id: state.pathParameters['id']!),
  ),
];

/// Story detail, under the stories list.
List<RouteBase> storiesRoutes() => [
  GoRoute(
    name: Routes.story.name,
    path: Routes.story.path,
    builder: (context, state) => StoryScreen(
      kind: StoryKind.values.asNameMap()[state.pathParameters['kind']],
      id: state.pathParameters['id']!,
    ),
  ),
];

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
/// taps). While the splash or the cold-start PIN gate still owns navigation
/// the link is parked and applied once home is reached (after unlock).
void openDeepLink(String location) {
  // Only in-app paths; never an absolute URL.
  if (!location.startsWith('/') || location.startsWith('//')) {
    return;
  }
  // The redirect keeps /lock only until the first unlock (later re-locks
  // use the overlay), so this is the cold-start gate: navigating now would
  // be redirected to /lock and, after unlock, leave the page with no home
  // beneath it.
  if (_splashDone && appRouter.state.uri.path != Routes.lock.path) {
    final path = Uri.parse(location).path;
    final inShell = _shellRoots.any(
      (root) => path == root || path.startsWith('$root/'),
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
    // System back on another tab's root returns to Home instead of
    // exiting the app; only Home's root lets the OS close it.
    final scaffold = PopScope(
      canPop: shell.currentIndex == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          shell.goBranch(0);
        }
      },
      child: QBottomNavScaffold(
        currentIndex: shell.currentIndex,
        onSelect: (index) =>
            shell.goBranch(index, initialLocation: index == shell.currentIndex),
        body: shell,
      ),
    );
    // Badge unlock toasts show on every tab, once each.
    if (!locator.isRegistered<AchievementStore>() ||
        !locator.isRegistered<MuhasabaStore>()) {
      return scaffold;
    }
    final lock = locator.isRegistered<AppLockStore>()
        ? locator<AppLockStore>()
        : null;
    return BadgeUnlockListener(
      store: locator<AchievementStore>(),
      enabled: () => locator<SettingsStore>().settings.value.showAchievements,
      // A locked Muhasaba section holds its toasts until unlocked.
      paused: () => lock?.muhasabaLocked ?? false,
      watchActivity: () => locator<MuhasabaStore>().stats.value,
      child: scaffold,
    );
  }
}

/// Root-builder layer for background re-locks: covers the app with the PIN
/// gate while [AppLockStore.locked], leaving [child] (the router and its
/// whole navigation state) mounted underneath but unreachable — no
/// pointer, focus or semantics. Cold start is gated by the redirect
/// instead, so the overlay stays off on the splash and /lock routes.
final class LockOverlay extends StatelessWidget {
  const LockOverlay({required this.router, required this.child, super.key});

  final GoRouter router;
  final Widget? child;

  bool _covers(bool locked) {
    if (!locked) {
      return false;
    }
    final config = router.routerDelegate.currentConfiguration;
    final path = config.uri.path;
    return config.isNotEmpty &&
        path != Routes.lock.path &&
        path != Routes.splash.path;
  }

  @override
  Widget build(BuildContext context) {
    final lock = locator<AppLockStore>();
    // Rebuilds on lock flips only. The route is read, not listened to (its
    // delegate notifies mid-build): while locked it can only be the cold-
    // start gate, which the redirect keeps until the first unlock.
    return SignalBuilder(
      builder: (context) {
        final covered = _covers(lock.locked.value);
        return Stack(
          fit: StackFit.expand,
          children: [
            // Same wrappers either way, so locking never remounts the app.
            ExcludeFocus(
              excluding: covered,
              child: ExcludeSemantics(
                excluding: covered,
                child: IgnorePointer(
                  ignoring: covered,
                  child: child ?? const SizedBox.shrink(),
                ),
              ),
            ),
            if (covered) _LockLayer(back: router.backButtonDispatcher),
          ],
        );
      },
    );
  }
}

/// The overlaid [LockScreen], in its own navigator (its dialogs) and
/// holding the back button so it can't pop the hidden pages underneath.
final class _LockLayer extends StatefulWidget {
  const _LockLayer({required this.back});

  final BackButtonDispatcher? back;

  @override
  State<_LockLayer> createState() => _LockLayerState();
}

final class _LockLayerState extends State<_LockLayer> {
  final _navigator = GlobalKey<NavigatorState>();
  ChildBackButtonDispatcher? _dispatcher;

  Future<bool> _onBack() {
    // Closes a lock-screen dialog; never reaches the app's pages.
    unawaited(_navigator.currentState?.maybePop());
    return SynchronousFuture(true);
  }

  @override
  void initState() {
    super.initState();
    _dispatcher = widget.back?.createChildBackButtonDispatcher()
      ?..addCallback(_onBack)
      ..takePriority();
  }

  @override
  void dispose() {
    final dispatcher = _dispatcher;
    if (dispatcher != null) {
      dispatcher.removeCallback(_onBack);
      widget.back?.forget(dispatcher);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => HeroControllerScope.none(
    child: Navigator(
      key: _navigator,
      onGenerateRoute: (_) =>
          PageRouteBuilder<void>(pageBuilder: (_, _, _) => const LockScreen()),
    ),
  );
}
