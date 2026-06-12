import 'package:flutter/material.dart';

import '../../core/theme/qalbee_tokens.dart';
import '../../core/theme/qalbee_typography.dart';
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
      body: body,
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
                      onTap: () => onSelect(i),
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
                child: Icon(
                  active ? item.activeIcon : item.icon,
                  size: 20,
                  color: active ? q.onPrimarySoft : q.ink3,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: QType.caption.copyWith(
                  fontSize: 10.5,
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
