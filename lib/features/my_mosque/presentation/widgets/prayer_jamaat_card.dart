import 'package:flutter/material.dart';

import '../../../../core/theme/productive_muslim_tokens.dart';
import '../../../../core/theme/productive_muslim_typography.dart';
import '../../../../shared/extensions/context_ext.dart';
import '../../../../shared/widgets/q_button.dart';
import '../../../../shared/widgets/q_card.dart';
import '../../../../shared/widgets/q_number_dialog.dart';
import '../../../../shared/widgets/q_seg_control.dart';
import '../../../../shared/widgets/q_step_button.dart';
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
    this.preview,
    this.warning,
  });

  final Prayer prayer;
  final JamaatEntry entry;
  final String Function(ClockTime) formatTime;
  final ValueChanged<JamaatEntry> onChanged;

  /// Opens the time picker; also used when switching to Fixed, so a fixed
  /// time is only ever saved once the user actually picks one.
  final VoidCallback onPickTime;

  /// Today's resolved time for an offset entry, e.g. "→ 1:35 PM today".
  final String? preview;

  /// Shown when a fixed time falls outside today's waqt.
  final String? warning;

  static const _minOffset = 1;
  static const _maxOffset = 60;

  /// Steps snap to multiples of 5, kept within the bounds.
  void _setOffset(int minutes) => onChanged(
    OffsetJamaat(Duration(minutes: minutes.clamp(_minOffset, _maxOffset))),
  );

  int get _modeIndex => switch (entry) {
    NoJamaat() => 0,
    OffsetJamaat() => 1,
    FixedJamaat() => 2,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final q = context.q;
    final stepperLabel = '${l10n.prayerLabel(prayer)} ${l10n.jamaatLabel}';
    return QCard(
      padding: const EdgeInsets.all(QSpace.s4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.prayerLabel(prayer),
            style: QType.titleSm.copyWith(color: q.ink),
          ),
          // Own row: a fixed-width control beside the title clipped at
          // large text scales.
          const SizedBox(height: QSpace.s2),
          QSegControl(
            options: [
              l10n.jamaatModeNone,
              l10n.jamaatModeOffset,
              l10n.jamaatModeFixed,
            ],
            activeIndex: _modeIndex,
            onChanged: (i) {
              if (i == _modeIndex) {
                return;
              }
              switch (i) {
                case 1:
                  // Maghrib is prayed promptly; others gather later.
                  onChanged(
                    OffsetJamaat(
                      Duration(minutes: prayer == Prayer.maghrib ? 5 : 15),
                    ),
                  );
                case 2:
                  onPickTime();
                default:
                  onChanged(const NoJamaat());
              }
            },
          ),
          switch (entry) {
            NoJamaat() => const SizedBox.shrink(),
            OffsetJamaat(:final offset) => Padding(
              padding: const EdgeInsets.only(top: QSpace.s3),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.offsetAfterStart(offset.inMinutes),
                          style: QType.caption.copyWith(color: q.ink2),
                        ),
                        if (preview case final p?)
                          Text(
                            p,
                            style: QType.num_(
                              QType.caption,
                            ).copyWith(color: q.ink),
                          ),
                      ],
                    ),
                  ),
                  QStepButton(
                    fill: context.q.surface2,
                    size: 32,
                    icon: Icons.remove,
                    semanticLabel: l10n.a11yDecrease(stepperLabel),
                    onTap: offset.inMinutes > _minOffset
                        ? () => _setOffset(((offset.inMinutes - 1) ~/ 5) * 5)
                        : null,
                  ),
                  // ±5 nudges; tapping the value types an exact minute.
                  InkWell(
                    borderRadius: BorderRadius.circular(QRadius.sm),
                    onTap: () async {
                      final picked = await showNumberDialog(
                        context,
                        title: stepperLabel,
                        hint: l10n.jamaatOffsetHint,
                        actionLabel: l10n.save,
                        max: _maxOffset,
                        initial: offset.inMinutes,
                      );
                      if (picked != null) {
                        _setOffset(picked);
                      }
                    },
                    child: SizedBox(
                      width: 64,
                      height: QTouch.minTarget,
                      child: Center(
                        child: Text(
                          l10n.minutesShort(offset.inMinutes),
                          textAlign: TextAlign.center,
                          style: QType.num_(
                            QType.label,
                          ).copyWith(color: q.primary),
                        ),
                      ),
                    ),
                  ),
                  QStepButton(
                    fill: context.q.surface2,
                    size: 32,
                    icon: Icons.add,
                    semanticLabel: l10n.a11yIncrease(stepperLabel),
                    onTap: offset.inMinutes < _maxOffset
                        ? () => _setOffset((offset.inMinutes ~/ 5 + 1) * 5)
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
          if (warning case final w?) ...[
            const SizedBox(height: QSpace.s2),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.warning_amber_rounded, size: 16, color: q.warn),
                const SizedBox(width: QSpace.s2),
                Expanded(
                  child: Text(w, style: QType.caption.copyWith(color: q.warn)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
