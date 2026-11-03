import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/utils/haptics.dart';
import '../../../../shared/extensions/context_ext.dart';
import '../state/achievement_store.dart';

/// App-shell listener: re-evaluates badges on new activity and toasts each
/// badge that unlocks while the app is open, on whichever tab is showing.
///
/// Exactly once per unlock: the badges already pending once the store has
/// loaded (or when [enabled] turns on) are the baseline and never toast,
/// so a restart, a rebuild or re-enabling doesn't replay them; anything
/// unlocked after that, the listener's own first scan included, does.
final class BadgeUnlockListener extends StatefulWidget {
  const BadgeUnlockListener({
    required this.store,
    required this.enabled,
    required this.watchActivity,
    required this.child,
    this.paused,
    super.key,
  });

  final AchievementStore store;

  /// Reactive read of the "show achievements" setting.
  final bool Function() enabled;

  /// Reactive: while true no toast shows (a locked Muhasaba section);
  /// unlocks meanwhile toast once it turns false.
  final bool Function()? paused;

  /// Reads the signals whose change may unlock a badge (muhasaba logs),
  /// so each change triggers a re-evaluation.
  final void Function() watchActivity;

  final Widget child;

  @override
  State<BadgeUnlockListener> createState() => _BadgeUnlockListenerState();
}

final class _BadgeUnlockListenerState extends State<BadgeUnlockListener> {
  late final _enabled = computed(widget.enabled);
  late final _paused = computed(widget.paused ?? () => false);
  final _effects = <EffectCleanup>[];

  /// Unseen badge ids already toasted or baselined; null = no baseline.
  Set<String>? _known;
  var _wasPaused = false;

  @override
  void initState() {
    super.initState();
    final badges = widget.store;
    _wasPaused = _paused.peek();
    _effects
      ..add(
        effect(() {
          if (!_enabled.value) {
            return;
          }
          widget.watchActivity();
          badges.watchSources();
          untracked(
            () => unawaited(
              badges.refresh().catchError((Object e) {
                // Badges keep their last totals; the next change retries.
                debugPrint('Badge refresh failed: $e');
              }),
            ),
          );
        }),
      )
      ..add(
        effect(() {
          // Locking drops toasts already queued; they show nothing new.
          final paused = _paused.value;
          if (paused && !_wasPaused && mounted) {
            untracked(
              () => ScaffoldMessenger.maybeOf(context)?.clearSnackBars(),
            );
          }
          _wasPaused = paused;
        }),
      )
      ..add(
        effect(() {
          final ids = {for (final a in badges.newlyUnlocked.value) a.id};
          if (!_enabled.value || !badges.loaded.value) {
            _known = null;
            return;
          }
          final known = _known;
          if (known == null) {
            _known = ids; // baseline
            return;
          }
          if (_paused.value) {
            return; // keep them unknown until unpaused
          }
          _known = ids;
          final fresh = ids.difference(known).toList()..sort();
          if (fresh.isNotEmpty) {
            untracked(() => _toast(fresh));
          }
        }),
      );
  }

  @override
  void dispose() {
    for (final cleanup in _effects) {
      cleanup();
    }
    _enabled.dispose();
    _paused.dispose();
    super.dispose();
  }

  /// One snackbar per badge; the messenger queues them.
  void _toast(List<String> ids) {
    if (!mounted) {
      return;
    }
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    Haptics.medium();
    for (final id in ids) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            l10n.achievementUnlockedToast(l10n.achievementName(id)),
          ),
          behavior: SnackBarBehavior.floating,
          // With an action it would wait for a tap, holding the queue.
          persist: false,
          action: SnackBarAction(
            label: l10n.achievementsView,
            onPressed: () => context.pushNamed(Routes.achievements.name),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
