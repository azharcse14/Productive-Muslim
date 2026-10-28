import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme/productive_muslim_tokens.dart';
import '../../core/theme/productive_muslim_typography.dart';
import '../../core/utils/haptics.dart';
import '../extensions/context_ext.dart';

/// One destination of the 5-tab bottom navigation.
final class QNavItem {
  const QNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
}

/// Scaffold with the designed bottom navigation: surface bar with hairline
/// top border; active tab gets a 52×30 primary-soft pill. The Muhasaba tab
/// is the only place the heart icon appears outside the full mark.
final class QBottomNavScaffold extends StatelessWidget {
  const QBottomNavScaffold({
    required this.body,
    required this.currentIndex,
    required this.onSelect,
    super.key,
  });

  final Widget body;
  final int currentIndex;
  final ValueChanged<int> onSelect;

  static List<QNavItem> itemsOf(BuildContext context) {
    final l10n = context.l10n;
    return [
      QNavItem(
        icon: Icons.home_outlined,
        activeIcon: Icons.home_rounded,
        label: l10n.tabHome,
      ),
      QNavItem(
        icon: Icons.menu_book_outlined,
        activeIcon: Icons.menu_book_rounded,
        label: l10n.tabQuran,
      ),
      QNavItem(
        icon: Icons.favorite_outline_rounded,
        activeIcon: Icons.favorite_rounded,
        label: l10n.tabMuhasaba,
      ),
      QNavItem(
        icon: Icons.grain_rounded,
        activeIcon: Icons.grain_rounded,
        label: l10n.tabDua,
      ),
      QNavItem(
        icon: Icons.more_horiz_rounded,
        activeIcon: Icons.more_horiz_rounded,
        label: l10n.tabMore,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final q = context.q;
    final items = itemsOf(context);
    return Scaffold(
      body: _TabFade(index: currentIndex, child: body),
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          color: q.surface,
          border: Border(top: BorderSide(color: q.line)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              QSpace.s2,
              QSpace.s2,
              QSpace.s2,
              2,
            ),
            child: Row(
              children: [
                for (final (i, item) in items.indexed)
                  Expanded(
                    child: _NavDestination(
                      item: item,
                      active: i == currentIndex,
                      onTap: () {
                        if (i != currentIndex) {
                          Haptics.selection();
                        }
                        onSelect(i);
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Fades the tab body in on each tab switch. The shell keeps one child (an
/// indexed stack), so this replays a fade rather than cross-fading two
/// trees. Cut under reduced-motion.
final class _TabFade extends StatefulWidget {
  const _TabFade({required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  State<_TabFade> createState() => _TabFadeState();
}

final class _TabFadeState extends State<_TabFade>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: QMotion.med,
    value: 1,
  );
  late final Animation<double> _opacity = CurvedAnimation(
    parent: _controller,
    curve: QMotion.ease,
  ).drive(Tween(begin: 0.4, end: 1));

  @override
  void didUpdateWidget(_TabFade oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.index != widget.index &&
        !MediaQuery.disableAnimationsOf(context)) {
      unawaited(_controller.forward(from: 0));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      FadeTransition(opacity: _opacity, child: widget.child);
}

final class _NavDestination extends StatelessWidget {
  const _NavDestination({
    required this.item,
    required this.active,
    required this.onTap,
  });

  final QNavItem item;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final q = context.q;
    return Semantics(
      button: true,
      selected: active,
      label: item.label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(QRadius.md),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: QTouch.minTarget),
          child: Column(
            // min, NOT max: Scaffold hands the nav slot loose constraints,
            // so a max-sized Column would swallow the whole screen height.
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: QMotion.fast,
                curve: QMotion.ease,
                width: 52,
                height: 30,
                decoration: BoxDecoration(
                  color: active ? q.primarySoft : const Color(0x00000000),
                  borderRadius: BorderRadius.circular(QRadius.full),
                ),
                // Pops in (overshoot) when the tab becomes active; the key
                // restarts the tween on each activation.
                child: TweenAnimationBuilder<double>(
                  key: ValueKey(active),
                  tween: Tween(begin: active ? 0.75 : 1, end: 1),
                  duration: MediaQuery.disableAnimationsOf(context)
                      ? Duration.zero
                      : QMotion.med,
                  curve: Curves.easeOutBack,
                  builder: (context, scale, child) =>
                      Transform.scale(scale: scale, child: child),
                  child: Icon(
                    active ? item.activeIcon : item.icon,
                    size: 20,
                    color: active ? q.onPrimarySoft : q.ink3,
                  ),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: QType.caption.copyWith(
                  color: active ? q.ink : q.ink3,
                  fontVariations: [FontVariation('wght', active ? 700 : 500)],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
