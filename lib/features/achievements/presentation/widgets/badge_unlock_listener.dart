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
/// Exactly once per unlock: the badges pending after its first
/// evaluation (on start, or when [enabled] turns on) are the baseline and
/// never toast, so a restart, a rebuild or re-enabling doesn't replay
/// them.
final class BadgeUnlockListener extends StatefulWidget {
  const BadgeUnlockListener({
    required this.store,
    required this.enabled,
    required this.watchActivity,
    required this.child,
    super.key,
  });

  final AchievementStore store;

  /// Reactive read of the "show achievements" setting.
  final bool Function() enabled;

  /// Reads the signals whose change may unlock a badge (muhasaba logs),
  /// so each change triggers a re-evaluation.
  final void Function() watchActivity;

  final Widget child;

  @override
  State<BadgeUnlockListener> createState() => _BadgeUnlockListenerState();
}

final class _BadgeUnlockListenerState extends State<BadgeUnlockListener> {
  late final _enabled = computed(widget.enabled);
  final _effects = <EffectCleanup>[];

  /// Unseen badge ids at the last check; null = no baseline yet.
  Set<String>? _known;

  Set<String> get _pending => {
    for (final a in widget.store.newlyUnlocked.value) a.id,
  };

  @override
  void initState() {
    super.initState();
    final badges = widget.store;
    _effects
      ..add(
        effect(() {
          if (!_enabled.value) {
            _known = null;
            return;
          }
          widget.watchActivity();
          badges.watchSources();
          untracked(
            () => unawaited(
              badges
                  .refresh()
                  // The first evaluation sets the baseline.
                  .then((_) => _known ??= untracked(() => _pending))
                  .catchError((Object e) {
                    // Badges keep their last totals; the next change
                    // retries.
                    debugPrint('Badge refresh failed: $e');
                    return const <String>{};
                  }),
            ),
          );
        }),
      )
      ..add(
        effect(() {
          final ids = _pending;
          final known = _known;
          if (!_enabled.value || known == null) {
            return; // no baseline yet
          }
          _known = ids;
          final fresh = ids.difference(known);
          if (fresh.isNotEmpty) {
            untracked(() => _toast(fresh.first));
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
    super.dispose();
  }

  void _toast(String id) {
    if (!mounted) {
      return;
    }
    final l10n = context.l10n;
    Haptics.medium();
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(
            l10n.achievementUnlockedToast(l10n.achievementName(id)),
          ),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: l10n.achievementsView,
            onPressed: () => context.pushNamed(Routes.achievements.name),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
