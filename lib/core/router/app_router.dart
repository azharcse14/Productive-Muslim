import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../features/dua_tasbih/presentation/screens/dua_screen.dart';
import '../../features/muhasaba/presentation/screens/muhasaba_screen.dart';
import '../../features/prayer_times/presentation/screens/home_screen.dart';
import '../../features/quran/presentation/screens/quran_screen.dart';
import '../../features/settings/presentation/screens/more_screen.dart';
import '../../shared/gallery/widget_gallery_screen.dart';
import '../../shared/widgets/q_bottom_nav.dart';
import 'routes.dart';

/// Single source of routes (guide §4). Bottom navigation uses
/// [StatefulShellRoute.indexedStack] so tab state persists.
///
/// Phase 11 adds the onboarding `redirect` (setupComplete gate) and the
/// `/quran/:surah/:ayah` deep link for notification taps.
GoRouter buildRouter() {
  return GoRouter(
    initialLocation: Routes.home.path,
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
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        name: Routes.gallery.name,
        path: Routes.gallery.path,
        builder: (context, state) => const WidgetGalleryScreen(),
      ),
    ],
  );
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
