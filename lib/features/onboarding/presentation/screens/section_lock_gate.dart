import 'dart:async';

import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../../core/di/locator.dart';
import '../../../../shared/extensions/context_ext.dart';
import '../../../../shared/widgets/q_button.dart';
import '../../../../shared/widgets/q_empty_state.dart';
import '../state/app_lock_store.dart';
import 'lock_screen.dart';

/// Shows [child] (the Muhasaba tab) only while the section lock is open.
/// Locked, [child] isn't built at all; "Unlock" asks for the app PIN (or
/// biometric) once, and the lock store re-locks it after the app has been
/// in the background.
final class SectionLockGate extends StatelessWidget {
  const SectionLockGate({required this.child, super.key});

  final Widget child;

  Future<void> _unlock(BuildContext context) async {
    // Verify mode pops once the PIN or biometric checks out; the store
    // opens the section itself.
    await Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute<bool>(
        fullscreenDialog: true,
        builder: (_) => const LockScreen(mode: LockScreenMode.verify),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lock = locator<AppLockStore>();
    return SignalBuilder(
      builder: (context) {
        if (!lock.muhasabaLocked) {
          return child;
        }
        final l10n = context.l10n;
        return Scaffold(
          appBar: AppBar(title: Text(l10n.muhasabaTitle)),
          body: SafeArea(
            child: QEmptyState(
              icon: Icons.lock_outline,
              title: l10n.lockMuhasabaLockedTitle,
              body: l10n.lockMuhasabaLockedBody,
              action: QButton(
                label: l10n.lockUnlockAction,
                icon: Icons.lock_open_outlined,
                onPressed: () => unawaited(_unlock(context)),
              ),
            ),
          ),
        );
      },
    );
  }
}
