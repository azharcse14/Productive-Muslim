import 'dart:async';

import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show MethodChannel;
import 'package:go_router/go_router.dart';
import 'package:signals_flutter/signals_flutter.dart';

import 'core/di/locator.dart';
import 'core/l10n/gen/app_localizations.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/notifications/presentation/state/notification_controller.dart';
import 'features/onboarding/presentation/state/app_lock_store.dart';
import 'features/settings/presentation/state/settings_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await setupLocator();
  // Schedule the notification window; never blocks first frame.
  unawaited(locator<NotificationController>().start());
  _secureWhileLocked();
  runApp(const ProductiveMuslimApp());
}

/// Android: FLAG_SECURE while app lock is on, so the recents thumbnail
/// (and screenshots) stay blank. iOS is covered by the root overlay.
void _secureWhileLocked() {
  if (defaultTargetPlatform != TargetPlatform.android) {
    return;
  }
  const channel = MethodChannel('com.productivemuslim.app/secure');
  final lock = locator<AppLockStore>();
  effect(() {
    unawaited(channel.invokeMethod<void>('setSecure', lock.enabled.value));
  });
}

/// Root widget: themed, localized, routed. Theme mode and locale are
/// driven by the app-scoped [SettingsStore] signals; the router instance
/// survives those rebuilds.
final class ProductiveMuslimApp extends StatefulWidget {
  const ProductiveMuslimApp({super.key});

  @override
  State<ProductiveMuslimApp> createState() => _ProductiveMuslimAppState();
}

final class _ProductiveMuslimAppState extends State<ProductiveMuslimApp> {
  final SettingsStore _store = locator<SettingsStore>();
  final AppLockStore _lock = locator<AppLockStore>();

  /// App-scoped (notification taps navigate it from outside the tree).
  final GoRouter _router = appRouter;

  @override
  Widget build(BuildContext context) {
    return SignalBuilder(
      builder: (context) => MaterialApp.router(
        onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: _store.themeMode.value,
        locale: _store.locale.value,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: _router,
        // App lock: an opaque cover while backgrounded hides the UI from
        // the app switcher and from the first frame back before the gate.
        builder: (context, child) => SignalBuilder(
          builder: (context) => Stack(
            fit: StackFit.expand,
            children: [
              ?child,
              if (_lock.obscured.value)
                ColoredBox(color: Theme.of(context).colorScheme.surface),
            ],
          ),
        ),
      ),
    );
  }
}
