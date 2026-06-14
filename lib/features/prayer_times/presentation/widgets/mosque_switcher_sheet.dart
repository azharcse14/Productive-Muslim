import 'package:flutter/material.dart';

import '../../../../core/theme/qalbee_tokens.dart';
import '../../../../core/theme/qalbee_typography.dart';
import '../../../../shared/extensions/context_ext.dart';

/// One selectable mosque in the switcher.
typedef SwitcherMosque = ({String id, String name});

/// Opens the home mosque switcher: pick which mosque's jamaat times Home shows.
/// In auto mode the pick is a temporary override; "Reset to schedule" returns
/// to the schedule. "Manage" opens the full My Mosque editor.
Future<void> showMosqueSwitcherSheet(
  BuildContext context, {
  required List<SwitcherMosque> mosques,
  required String? currentId,
  required bool isAuto,
  required bool isOverride,
  required void Function(String id) onSelect,
  required VoidCallback onResetToAuto,
  required VoidCallback onManage,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _MosqueSwitcherSheet(
      mosques: mosques,
      currentId: currentId,
      isAuto: isAuto,
      isOverride: isOverride,
      onSelect: onSelect,
      onResetToAuto: onResetToAuto,
      onManage: onManage,
    ),
  );
}

final class _MosqueSwitcherSheet extends StatelessWidget {
  const _MosqueSwitcherSheet({
    required this.mosques,
    required this.currentId,
    required this.isAuto,
    required this.isOverride,
    required this.onSelect,
    required this.onResetToAuto,
    required this.onManage,
  });

  final List<SwitcherMosque> mosques;
  final String? currentId;
  final bool isAuto;
  final bool isOverride;
  final void Function(String id) onSelect;
  final VoidCallback onResetToAuto;
  final VoidCallback onManage;

  @override
  Widget build(BuildContext context) {
    final q = context.q;
    final l10n = context.l10n;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(QSpace.s6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: q.line,
                  borderRadius: BorderRadius.circular(QRadius.full),
                ),
              ),
            ),
            const SizedBox(height: QSpace.s5),
            Text(
              l10n.switchMosqueTitle,
              style: QType.title.copyWith(color: q.ink),
            ),
            if (isAuto) ...[
              const SizedBox(height: 2),
              Text(
                isOverride
                    ? l10n.mosqueOverrideSubtitle
                    : l10n.mosqueAutoSubtitle,
                style: QType.caption.copyWith(color: q.ink2),
              ),
            ],
            const SizedBox(height: QSpace.s4),
            for (final m in mosques)
              _MosqueRow(
                name: m.name,
                selected: m.id == currentId,
                onTap: () {
                  onSelect(m.id);
                  Navigator.of(context).pop();
                },
              ),
            if (isAuto && isOverride) ...[
              const SizedBox(height: QSpace.s2),
              _ActionRow(
                icon: Icons.schedule,
                label: l10n.mosqueResetToSchedule,
                onTap: () {
                  onResetToAuto();
                  Navigator.of(context).pop();
                },
              ),
            ],
            const Divider(height: QSpace.s6),
            _ActionRow(
              icon: Icons.tune,
              label: l10n.mosqueManage,
              onTap: () {
                Navigator.of(context).pop();
                onManage();
              },
            ),
          ],
        ),
      ),
    );
  }
}

final class _MosqueRow extends StatelessWidget {
  const _MosqueRow({
    required this.name,
    required this.selected,
    required this.onTap,
  });

  final String name;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final q = context.q;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(QRadius.md),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: QSpace.s2,
          vertical: QSpace.s3,
        ),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              size: 20,
              color: selected ? q.primary : q.ink3,
            ),
            const SizedBox(width: QSpace.s3),
            Expanded(
              child: Text(
                name,
                style: QType.titleSm.copyWith(
                  color: q.ink,
                  fontVariations: [FontVariation('wght', selected ? 700 : 600)],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final q = context.q;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(QRadius.md),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: QSpace.s2,
          vertical: QSpace.s3,
        ),
        child: Row(
          children: [
            Icon(icon, size: 19, color: q.primary),
            const SizedBox(width: QSpace.s3),
            Text(
              label,
              style: QType.titleSm.copyWith(color: q.primary),
            ),
          ],
        ),
      ),
    );
  }
}
