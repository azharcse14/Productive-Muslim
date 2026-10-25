import 'package:flutter/material.dart';

import '../../../../core/theme/productive_muslim_tokens.dart';
import '../../../../core/theme/productive_muslim_typography.dart';
import '../../../../shared/extensions/context_ext.dart';
import '../../../../shared/widgets/q_button.dart';
import '../../../../shared/widgets/q_card.dart';
import '../../../../shared/widgets/q_seg_control.dart';
import '../../../settings/domain/entities/prayer_params.dart';
import '../../../settings/presentation/widgets/setting_labels.dart';
import '../../domain/entities/jamaat_config.dart';

final class PrayerJamaatCard extends StatelessWidget {
  const PrayerJamaatCard({
    super.key,
    required this.prayer,
    required this.entry,
    required this.formatTime,
    required this.onChanged,
    required this.onPickTime,
  });

  final Prayer prayer;
  final JamaatEntry entry;
  final String Function(ClockTime) formatTime;
  final ValueChanged<JamaatEntry> onChanged;
  final VoidCallback onPickTime;

  int get _modeIndex => switch (entry) {
    NoJamaat() => 0,
    OffsetJamaat() => 1,
    FixedJamaat() => 2,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final q = context.q;
    return QCard(
      padding: const EdgeInsets.all(QSpace.s4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.prayerLabel(prayer),
                  style: QType.titleSm.copyWith(color: q.ink),
                ),
              ),
              SizedBox(
                width: 220,
                child: QSegControl(
                  options: [
                    l10n.jamaatModeNone,
                    l10n.jamaatModeOffset,
                    l10n.jamaatModeFixed,
                  ],
                  activeIndex: _modeIndex,
                  onChanged: (i) => onChanged(switch (i) {
                    1 => const OffsetJamaat(Duration(minutes: 15)),
                    2 => const FixedJamaat(ClockTime(13, 15)),
                    _ => const NoJamaat(),
                  }),
                ),
              ),
            ],
          ),
          switch (entry) {
            NoJamaat() => const SizedBox.shrink(),
            OffsetJamaat(:final offset) => Padding(
              padding: const EdgeInsets.only(top: QSpace.s3),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.offsetAfterStart(offset.inMinutes),
                      style: QType.caption.copyWith(color: q.ink2),
                    ),
                  ),
                  _StepButton(
                    icon: Icons.remove,
                    semanticLabel: l10n.a11yDecrease(l10n.jamaatLabel),
                    onTap: offset.inMinutes > 5
                        ? () => onChanged(
                            OffsetJamaat(offset - const Duration(minutes: 5)),
                          )
                        : null,
                  ),
                  SizedBox(
                    width: 64,
                    child: Text(
                      l10n.minutesShort(offset.inMinutes),
                      textAlign: TextAlign.center,
                      style: QType.num_(QType.label).copyWith(color: q.ink),
                    ),
                  ),
                  _StepButton(
                    icon: Icons.add,
                    semanticLabel: l10n.a11yIncrease(l10n.jamaatLabel),
                    onTap: offset.inMinutes < 60
                        ? () => onChanged(
                            OffsetJamaat(offset + const Duration(minutes: 5)),
                          )
                        : null,
                  ),
                ],
              ),
            ),
            FixedJamaat(:final time) => Padding(
              padding: const EdgeInsets.only(top: QSpace.s3),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.fixedAtTime(formatTime(time)),
                      style: QType.num_(QType.caption).copyWith(color: q.ink2),
                    ),
                  ),
                  QButton(
                    label: l10n.pickTime,
                    kind: QButtonKind.tonal,
                    small: true,
                    icon: Icons.schedule,
                    onPressed: onPickTime,
                  ),
                ],
              ),
            ),
          },
        ],
      ),
    );
  }
}

final class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.icon,
    required this.semanticLabel,
    required this.onTap,
  });

  final IconData icon;
  final String semanticLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final q = context.q;
    return Semantics(
      button: true,
      enabled: onTap != null,
      label: semanticLabel,
      excludeSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(QRadius.full),
        onTap: onTap,
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(color: q.surface2, shape: BoxShape.circle),
          child: Icon(icon, size: 16, color: onTap == null ? q.ink3 : q.ink),
        ),
      ),
    );
  }
}
