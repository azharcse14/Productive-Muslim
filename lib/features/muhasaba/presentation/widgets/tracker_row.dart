import 'package:flutter/material.dart';

import '../../../../core/theme/productive_muslim_tokens.dart';
import '../../../../core/theme/productive_muslim_typography.dart';
import '../../../../shared/extensions/context_ext.dart';
import '../../../../shared/widgets/q_step_button.dart';
import '../../domain/entities/tracker_item.dart';
import 'tracker_visuals.dart';

/// One checklist row — the three input kinds render distinctly
/// (design §4.7): yes/no toggle, count stepper, duration chip-stepper.
/// One-thumb friendly; no shame states.
final class TrackerRow extends StatelessWidget {
  const TrackerRow({
    required this.item,
    required this.value,
    required this.displayName,
    required this.onChanged,
    this.onLongPress,
    super.key,
  });

  final TrackerItem item;
  final int value;

  /// Localized name (default items resolve via l10n keys).
  final String displayName;
  final ValueChanged<int> onChanged;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final q = context.q;
    final l10n = context.l10n;
    final tone = TrackerVisuals.colorOf(q, item.colorIndex);
    final sub = switch ((item.kind, item.dailyTarget)) {
      (TrackerKind.count, final t?) => '$value / $t ${l10n.targetCountSuffix}',
      (TrackerKind.duration, final t?) =>
        '${l10n.minutesValue(value)} / $t ${l10n.targetMinutesSuffix}',
      (TrackerKind.duration, null) => l10n.minutesValue(value),
      _ => null,
    };
    return GestureDetector(
      onLongPress: onLongPress,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: QSpace.s4,
          vertical: QSpace.s3,
        ),
        decoration: BoxDecoration(
          color: q.surface,
          borderRadius: BorderRadius.circular(QRadius.md),
          border: Border.all(color: q.line),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: q.primarySoft,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(
                TrackerVisuals.iconOf(item.icon),
                size: 20,
                color: tone,
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: QType.titleSm.copyWith(fontSize: 15.5, color: q.ink),
                  ),
                  if (sub != null)
                    Text(
                      context.digits(sub),
                      style: QType.num_(QType.caption).copyWith(color: q.ink2),
                    ),
                ],
              ),
            ),
            switch (item.kind) {
              TrackerKind.yesNo => Semantics(
                label: displayName,
                child: Switch(
                  value: value > 0,
                  onChanged: (v) => onChanged(v ? 1 : 0),
                ),
              ),
              TrackerKind.count => _Stepper(
                value: value,
                step: 1,
                label: displayName,
                onChanged: onChanged,
              ),
              TrackerKind.duration => _Stepper(
                value: value,
                step: 5,
                label: displayName,
                onChanged: onChanged,
              ),
            },
          ],
        ),
      ),
    );
  }
}

final class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.value,
    required this.step,
    required this.label,
    required this.onChanged,
  });

  final int value;
  final int step;

  /// Item name, woven into the +/- buttons' screen-reader labels.
  final String label;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final q = context.q;
    final l10n = context.l10n;
    return Container(
      decoration: BoxDecoration(
        color: q.surface2,
        borderRadius: BorderRadius.circular(QRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          QStepButton(
            icon: Icons.remove,
            semanticLabel: l10n.a11yDecrease(label),
            onTap: value > 0 ? () => onChanged(value - step) : null,
          ),
          SizedBox(
            width: 38,
            child: Text(
              context.digits('$value'),
              textAlign: TextAlign.center,
              style: QType.num_(QType.titleSm).copyWith(color: q.ink),
            ),
          ),
          QStepButton(
            icon: Icons.add,
            semanticLabel: l10n.a11yIncrease(label),
            onTap: () => onChanged(value + step),
          ),
        ],
      ),
    );
  }
}

