import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:signals_flutter/signals_flutter.dart';

import 'core/di/locator.dart';
import 'core/l10n/gen/app_localizations.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/notifications/presentation/state/notification_controller.dart';
import 'features/settings/presentation/state/settings_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await setupLocator();
  // Schedule the next ~48h of notifications; never blocks first frame.
  unawaited(locator<NotificationController>().start());
  runApp(const QalbeeApp());
}

/// Root widget: themed, localized, routed. Theme mode and locale are
/// driven by the app-scoped [SettingsStore] signals; the router instance
/// survives those rebuilds.
final class QalbeeApp extends StatefulWidget {
  const QalbeeApp({super.key});

  @override
  State<QalbeeApp> createState() => _QalbeeAppState();
}

final class _QalbeeAppState extends State<QalbeeApp> {
  final SettingsStore _store = locator<SettingsStore>();
  late final GoRouter _router = buildRouter();

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

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
      ),
    );
  }
}
