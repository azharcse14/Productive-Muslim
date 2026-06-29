import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/locator.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/productive_muslim_tokens.dart';
import '../../../../core/theme/productive_muslim_typography.dart';
import '../../../../shared/extensions/context_ext.dart';
import '../../../../shared/painters/qalb_mark.dart';
import '../../../settings/presentation/state/settings_store.dart';
import '../state/app_lock_store.dart';

/// Branded splash (design §4.1): the mark draws in, total ≤2s, never
/// blocks on anything. Reduced-motion users get a cut, not an animation.
final class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

final class _SplashScreenState extends State<SplashScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 1200), _continue);
  }

  void _continue() {
    if (!mounted) {
      return;
    }
    final setupComplete =
        locator<SettingsStore>().settings.value.setupComplete;
    final locked = locator<AppLockStore>().locked.value;
    if (!setupComplete) {
      context.goNamed(Routes.onboarding.name);
    } else if (locked) {
      context.goNamed(Routes.lock.name);
    } else {
      context.goNamed(Routes.home.name);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final q = context.q;
    final reduced = MediaQuery.disableAnimationsOf(context);
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: reduced ? 1 : 0, end: 1),
              duration: reduced ? Duration.zero : QMotion.slow,
              curve: QMotion.ease,
              builder: (context, t, child) => Opacity(
                opacity: t,
                child: Transform.scale(scale: 0.8 + 0.2 * t, child: child),
              ),
              child: QalbMark(
                size: 120,
                color: q.primary,
                accent: q.primary,
              ),
            ),
            const SizedBox(height: QSpace.s5),
            Text(
              context.l10n.appTitle,
              style: QType.headline.copyWith(color: q.ink),
            ),
          ],
        ),
      ),
    );
  }
}
