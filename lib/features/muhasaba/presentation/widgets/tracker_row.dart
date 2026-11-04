import 'package:flutter/material.dart';

import '../../../../core/theme/productive_muslim_tokens.dart';
import '../../../../core/theme/productive_muslim_typography.dart';
import '../../../../core/utils/haptics.dart';
import '../../../../shared/extensions/context_ext.dart';
import '../../../../shared/widgets/q_number_dialog.dart';
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

  /// A long press edits the item; so does a plain tap, except on an active
  /// yes/no row, where a tap toggles it (and a pencil button edits).
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final q = context.q;
    final l10n = context.l10n;
    final tone = TrackerVisuals.colorOf(q, item.colorIndex);
    // An hour and up reads as "8 h" / "1 h 30 min", not "480 min".
    String duration(int minutes) => minutes < 60
        ? l10n.minutesValue(minutes)
        : minutes % 60 == 0
        ? l10n.durationHours(minutes ~/ 60)
        : l10n.durationHoursMinutes(minutes ~/ 60, minutes % 60);
    final sub = switch ((item.kind, item.dailyTarget)) {
      (TrackerKind.count, final t?) => '$value / $t ${l10n.targetCountSuffix}',
      (TrackerKind.duration, final t?) => '${duration(value)} / ${duration(t)}',
      (TrackerKind.duration, null) => duration(value),
      _ => null,
    };
    final changed = this.onChanged;
    // Archived (read-only): dim the icon and controls, keep the name legible.
    final dim = changed == null;
    Widget dimmed(Widget child) =>
        dim ? Opacity(opacity: 0.55, child: child) : child;
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
    final toggles = item.kind == TrackerKind.yesNo && onChanged != null;
    final control = dimmed(switch (item.kind) {
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
        unit: l10n.targetMinutesSuffix,
        onChanged: onChanged,
      ),
    });
    // Large text: the stepper moves under the name (settings' _UnderRow),
    // or it squeezes the name to a sliver on narrow phones.
    final under = item.kind != TrackerKind.yesNo && context.textGrowth > 1.3;
    return Material(
      color: q.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(QRadius.md),
        side: BorderSide(color: q.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        // An active yes/no row toggles like its switch; others edit.
        onTap: toggles
            ? () {
                Haptics.light();
                onChanged(value > 0 ? 0 : 1);
              }
            : onEdit == null
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  dimmed(
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
                  ),
                  const SizedBox(width: QSpace.s3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          style: QType.titleSm.copyWith(
                            color: dim ? q.ink2 : q.ink,
                          ),
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
                  if (!under) control,
                  // The tap toggles, so editing needs its own button.
                  if (toggles && onEdit != null)
                    IconButton(
                      tooltip: l10n.editTracker,
                      visualDensity: VisualDensity.compact,
                      icon: Icon(Icons.edit_outlined, size: 18, color: q.ink3),
                      onPressed: onEdit,
                    ),
                ],
              ),
              if (under)
                Padding(
                  // 40 icon tile + gap: aligned with the name.
                  padding: const EdgeInsetsDirectional.only(
                    start: 40 + QSpace.s3,
                    top: QSpace.s2,
                  ),
                  child: control,
                ),
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
    this.unit,
  });

  final int value;
  final int step;

  /// Item name, woven into the +/- buttons' screen-reader labels.
  final String label;

  /// Unit shown in the type-a-value dialog ("minutes"); null for counts.
  final String? unit;
  final ValueChanged<int>? onChanged;

  /// Typing beats 12 taps of +5 for an hour of tahajjud.
  Future<void> _typeValue(BuildContext context) async {
    // Capped: a huge value would overflow SQLite's SUM in the stats query.
    final typed = await showNumberDialog(
      context,
      title: label,
      hint: context.l10n.trackerValueInvalid,
      actionLabel: context.l10n.save,
      min: 0,
      max: 100000,
      initial: value,
      suffix: unit,
    );
    if (typed != null) {
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
          Semantics(
            button: onChanged != null,
            label: label,
            value: context.digits('$value'),
            onTapHint: l10n.a11yTypeValue,
            onTap: onChanged == null ? null : () => _typeValue(context),
            excludeSemantics: true,
            child: InkWell(
              onTap: onChanged == null ? null : () => _typeValue(context),
              // A floor, not a fixed width: big text or long numbers grow it.
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minWidth: 38,
                  minHeight: QTouch.minTarget,
                ),
                child: Center(
                  widthFactor: 1,
                  heightFactor: 1,
                  child: Text(
                    context.digits('$value'),
                    style: QType.num_(QType.titleSm).copyWith(color: q.ink),
                  ),
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
