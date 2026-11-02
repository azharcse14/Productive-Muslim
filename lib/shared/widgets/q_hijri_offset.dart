import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme/productive_muslim_tokens.dart';
import '../../core/theme/productive_muslim_typography.dart';
import '../extensions/context_ext.dart';
import 'q_step_button.dart';

/// "+1 day" / "−2 days" / "0 days" for a Hijri offset.
String hijriOffsetText(BuildContext context, int days) => context.digits(
  context.l10n.hijriOffsetValue(
    days.abs(),
    days > 0 ? '+' : (days < 0 ? '−' : ''),
  ),
);

/// Small centered link that opens the Hijri-offset sheet: "Adjust Hijri
/// date", or "Hijri dates adjusted +1 day · Change" once an offset is set.
final class QHijriOffsetLink extends StatelessWidget {
  const QHijriOffsetLink({
    required this.offset,
    required this.min,
    required this.max,
    required this.onChanged,
    super.key,
  });

  final int offset;
  final int min;
  final int max;
  final Future<void> Function(int) onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return InkWell(
      borderRadius: BorderRadius.circular(QRadius.sm),
      onTap: () => unawaited(
        showModalBottomSheet<void>(
          context: context,
          builder: (_) => _HijriOffsetSheet(
            initial: offset,
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: QTouch.minTarget),
        child: Center(
          child: Text(
            offset == 0
                ? l10n.hijriAdjustLink
                : '${l10n.hijriAdjustedBy(hijriOffsetText(context, offset))}'
                      ' · ${l10n.hijriAdjustChange}',
            textAlign: TextAlign.center,
            style: QType.caption.copyWith(color: context.q.primary),
          ),
        ),
      ),
    );
  }
}

final class _HijriOffsetSheet extends StatefulWidget {
  const _HijriOffsetSheet({
    required this.initial,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final int initial;
  final int min;
  final int max;
  final Future<void> Function(int) onChanged;

  @override
  State<_HijriOffsetSheet> createState() => _HijriOffsetSheetState();
}

final class _HijriOffsetSheetState extends State<_HijriOffsetSheet> {
  late int _value = widget.initial;

  void _set(int value) {
    setState(() => _value = value);
    unawaited(widget.onChanged(value));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final q = context.q;
    final label = l10n.settingHijriOffset;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(QSpace.s5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: QType.title.copyWith(color: q.ink)),
            const SizedBox(height: QSpace.s1),
            Text(
              l10n.settingHijriOffsetSub,
              textAlign: TextAlign.center,
              style: QType.body.copyWith(color: q.ink2),
            ),
            const SizedBox(height: QSpace.s4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                QStepButton(
                  icon: Icons.remove,
                  semanticLabel: l10n.a11yDecrease(label),
                  fill: q.surface2,
                  onTap: _value > widget.min ? () => _set(_value - 1) : null,
                ),
                ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 88),
                  child: Text(
                    hijriOffsetText(context, _value),
                    textAlign: TextAlign.center,
                    style: QType.num_(QType.titleSm).copyWith(color: q.ink),
                  ),
                ),
                QStepButton(
                  icon: Icons.add,
                  semanticLabel: l10n.a11yIncrease(label),
                  fill: q.surface2,
                  onTap: _value < widget.max ? () => _set(_value + 1) : null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
