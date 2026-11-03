import 'dart:async';

import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../../shared/extensions/context_ext.dart';
import '../../../../shared/widgets/q_button.dart';
import '../../../../shared/widgets/q_empty_state.dart';
import '../state/app_lock_store.dart';
import 'lock_screen.dart';

/// Shows [child] (a page with Muhasaba data) only while the section lock
/// is open. Locked, [child] isn't built at all; "Unlock" asks for the app
/// PIN (or biometric, or the "Forgot PIN?" reset) once, and the lock store
/// re-locks it after the app has been in the background. A re-lock while
/// this page is showing also closes what was opened on top of it (pages,
/// sheets, dialogs), which could show the same data.
final class SectionLockGate extends StatefulWidget {
  const SectionLockGate({required this.lock, required this.child, super.key});

  final AppLockStore lock;
  final Widget child;

  @override
  State<SectionLockGate> createState() => _SectionLockGateState();
}

final class _SectionLockGateState extends State<SectionLockGate> {
  late bool _wasLocked = widget.lock.muhasabaLocked;
  var _wasVisible = false;
  var _unlocking = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Coming back to a locked page (tab switch): close what's left on top.
    final visible = TickerMode.valuesOf(context).enabled;
    if (visible && !_wasVisible && widget.lock.muhasabaLocked) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _closeAbove());
    }
    _wasVisible = visible;
  }

  Future<void> _unlock() async {
    if (_unlocking) {
      return; // one lock screen per tap burst
    }
    _unlocking = true;
    try {
      await Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute<bool>(
          fullscreenDialog: true,
          builder: (_) => const LockScreen(mode: LockScreenMode.section),
        ),
      );
    } finally {
      _unlocking = false;
    }
  }

  /// Pops everything above this page in its own navigator (its tab's
  /// stack, hidden or not: sheets opened there stay editable otherwise).
  /// Root dialogs only while that navigator is showing, so a re-lock never
  /// closes another tab's.
  void _closeAbove() {
    if (!mounted) {
      return;
    }
    final navigator = Navigator.of(context);
    final route = ModalRoute.of(context);
    navigator.popUntil((r) => r == route || r.isFirst);
    final root = Navigator.of(context, rootNavigator: true);
    if (root != navigator && TickerMode.valuesOf(navigator.context).enabled) {
      root.popUntil((r) => r is! PopupRoute);
    }
  }

  @override
  Widget build(BuildContext context) => SignalBuilder(
    builder: (context) {
      final locked = widget.lock.muhasabaLocked;
      if (locked && !_wasLocked) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _closeAbove());
      }
      _wasLocked = locked;
      if (!locked) {
        return widget.child;
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
              onPressed: () => unawaited(_unlock()),
            ),
          ),
        ),
      );
    },
  );
}
