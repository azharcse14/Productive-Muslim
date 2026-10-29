import 'package:flutter/material.dart';

import '../../../../core/theme/productive_muslim_tokens.dart';
import '../../../../core/theme/productive_muslim_typography.dart';
import '../../../../core/utils/haptics.dart';
import '../../../../core/utils/locale_digits.dart';
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
    this.onEdit,
    super.key,
  });

  final TrackerItem item;
  final int value;

  /// Localized name (default items resolve via l10n keys).
  final String displayName;

  /// null renders the controls disabled (archived items).
  final ValueChanged<int>? onChanged;

  /// Tapping (or long-pressing) the row outside its controls edits it.
  final VoidCallback? onEdit;

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
    final changed = this.onChanged;
    final target = item.dailyTarget;
    final onChanged = changed == null
        ? null
        : (int next) {
            // A firmer buzz the moment the daily target is reached.
            if (target != null && value < target && next >= target) {
              Haptics.medium();
            }
            changed(next);
          };
    return Material(
      color: q.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(QRadius.md),
        side: BorderSide(color: q.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onEdit == null
            ? null
            : () {
                Haptics.selection();
                onEdit!();
              },
        onLongPress: onEdit,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: QSpace.s4,
            vertical: QSpace.s3,
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: q.primarySoft,
                  borderRadius: BorderRadius.circular(QRadius.md),
                ),
                child: Icon(
                  TrackerVisuals.iconOf(item.icon),
                  size: 20,
                  color: tone,
                ),
              ),
              const SizedBox(width: QSpace.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: QType.titleSm.copyWith(color: q.ink),
                    ),
                    if (sub != null)
                      Text(
                        context.digits(sub),
                        style: QType.num_(
                          QType.caption,
                        ).copyWith(color: q.ink2),
                      ),
                  ],
                ),
              ),
              switch (item.kind) {
                // container: its own node, not merged into the row's tap.
                TrackerKind.yesNo => Semantics(
                  container: true,
                  label: displayName,
                  child: Switch(
                    value: value > 0,
                    onChanged: onChanged == null
                        ? null
                        : (v) {
                            Haptics.light();
                            onChanged(v ? 1 : 0);
                          },
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
                  // Long targets (sleep) in half hours, not 84 taps.
                  step: (item.dailyTarget ?? 0) >= 120 ? 30 : 5,
                  label: displayName,
                  onChanged: onChanged,
                ),
              },
            ],
          ),
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
  final ValueChanged<int>? onChanged;

  /// Typing beats 12 taps of +5 for an hour of tahajjud.
  Future<void> _typeValue(BuildContext context) async {
    final typed = await showDialog<int>(
      context: context,
      builder: (_) =>
          _TypeValueDialog(label: label, initial: context.digits('$value')),
    );
    if (typed != null && typed >= 0) {
      onChanged?.call(typed);
    }
  }

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
            onTap: onChanged != null && value > 0
                ? () => onChanged!(value - step < 0 ? 0 : value - step)
                : null,
          ),
          InkWell(
            onTap: onChanged == null ? null : () => _typeValue(context),
            child: SizedBox(
              width: 38,
              height: QTouch.minTarget,
              child: Center(
                child: Text(
                  context.digits('$value'),
                  style: QType.num_(QType.titleSm).copyWith(color: q.ink),
                ),
              ),
            ),
          ),
          QStepButton(
            icon: Icons.add,
            semanticLabel: l10n.a11yIncrease(label),
            onTap: onChanged == null ? null : () => onChanged!(value + step),
          ),
        ],
      ),
    );
  }
}

/// Owns its controller, so it is disposed with the dialog — after the
/// exit animation, not while the field is still on screen.
final class _TypeValueDialog extends StatefulWidget {
  const _TypeValueDialog({required this.label, required this.initial});

  final String label;
  final String initial;

  @override
  State<_TypeValueDialog> createState() => _TypeValueDialogState();
}

final class _TypeValueDialogState extends State<_TypeValueDialog> {
  late final _controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() => Navigator.of(
    context,
  ).pop(int.tryParse(LocaleDigits.toAscii(_controller.text.trim())));

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(widget.label),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: TextInputType.number,
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(onPressed: _submit, child: Text(l10n.save)),
      ],
    );
  }
}
