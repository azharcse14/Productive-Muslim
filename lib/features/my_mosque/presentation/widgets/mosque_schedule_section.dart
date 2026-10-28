import 'package:flutter/material.dart';

import '../../../../core/theme/productive_muslim_tokens.dart';
import '../../../../core/theme/productive_muslim_typography.dart';
import '../../../../shared/extensions/context_ext.dart';
import '../../../../shared/widgets/q_button.dart';
import '../../../../shared/widgets/q_card.dart';
import '../../../../shared/widgets/q_chip.dart';
import '../../../../shared/widgets/q_seg_control.dart';
import '../../domain/entities/jamaat_config.dart';
import '../../domain/entities/mosque_profile.dart';
import '../../domain/entities/mosque_schedule.dart';
import '../../domain/entities/mosque_state.dart';

/// Manual/auto mode toggle plus the auto-switch rules editor and the default
/// mosque picker (design §4.9 scheduled profiles).
final class MosqueScheduleSection extends StatelessWidget {
  const MosqueScheduleSection({
    super.key,
    required this.state,
    required this.formatTime,
    required this.onModeChanged,
    required this.onAddRule,
    required this.onRemoveRule,
    required this.onRuleChanged,
    required this.onDefaultChanged,
    required this.onPickRuleTime,
  });

  final MosqueState state;
  final String Function(ClockTime) formatTime;
  final ValueChanged<ScheduleMode> onModeChanged;
  final VoidCallback onAddRule;
  final ValueChanged<int> onRemoveRule;
  final void Function(int index, MosqueRule rule) onRuleChanged;
  final ValueChanged<String?> onDefaultChanged;
  final void Function(int index, {required bool isStart}) onPickRuleTime;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final q = context.q;
    final auto = state.mode == ScheduleMode.auto;
    return QCard(
      padding: const EdgeInsets.all(QSpace.s4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.event_repeat_outlined, size: 18, color: q.primary),
              const SizedBox(width: QSpace.s3),
              Expanded(
                child: Text(
                  l10n.scheduleSectionTitle,
                  style: QType.titleSm.copyWith(color: q.ink),
                ),
              ),
            ],
          ),
          // Own row so large text scales don't clip it.
          const SizedBox(height: QSpace.s3),
          QSegControl(
            options: [l10n.scheduleModeManual, l10n.scheduleModeAuto],
            activeIndex: auto ? 1 : 0,
            onChanged: (i) =>
                onModeChanged(i == 1 ? ScheduleMode.auto : ScheduleMode.manual),
          ),
          if (auto) ...[
            const SizedBox(height: QSpace.s3),
            Text(
              l10n.scheduleAutoHint,
              style: QType.caption.copyWith(color: q.ink2),
            ),
            const SizedBox(height: QSpace.s4),
            if (state.rules.isEmpty)
              Text(
                l10n.scheduleRulesEmpty,
                style: QType.caption.copyWith(color: q.ink3),
              )
            else
              for (final (i, rule) in state.rules.indexed) ...[
                _RuleCard(
                  rule: rule,
                  profiles: state.profiles,
                  formatTime: formatTime,
                  onChanged: (r) => onRuleChanged(i, r),
                  onRemove: () => onRemoveRule(i),
                  onPickTime: ({required bool isStart}) =>
                      onPickRuleTime(i, isStart: isStart),
                ),
                const SizedBox(height: QSpace.s3),
              ],
            const SizedBox(height: QSpace.s2),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: QButton(
                label: l10n.scheduleAddRule,
                kind: QButtonKind.tonal,
                small: true,
                icon: Icons.add,
                onPressed: state.profiles.isEmpty ? null : onAddRule,
              ),
            ),
            const SizedBox(height: QSpace.s4),
            Text(
              l10n.scheduleDefaultMosque,
              style: QType.label.copyWith(color: q.ink),
            ),
            const SizedBox(height: QSpace.s2),
            _MosqueDropdown(
              profiles: state.profiles,
              value: state.defaultId,
              hint: l10n.scheduleDefaultMosque,
              onChanged: onDefaultChanged,
            ),
            const SizedBox(height: QSpace.s2),
            Text(
              l10n.scheduleDefaultHint,
              style: QType.caption.copyWith(color: q.ink3),
            ),
          ],
        ],
      ),
    );
  }
}

final class _RuleCard extends StatelessWidget {
  const _RuleCard({
    required this.rule,
    required this.profiles,
    required this.formatTime,
    required this.onChanged,
    required this.onRemove,
    required this.onPickTime,
  });

  final MosqueRule rule;
  final List<MosqueProfile> profiles;
  final String Function(ClockTime) formatTime;
  final ValueChanged<MosqueRule> onChanged;
  final VoidCallback onRemove;
  final void Function({required bool isStart}) onPickTime;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final q = context.q;
    return Container(
      padding: const EdgeInsets.all(QSpace.s3),
      decoration: BoxDecoration(
        color: q.surface2,
        borderRadius: BorderRadius.circular(QRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _MosqueDropdown(
                  profiles: profiles,
                  value: rule.mosqueId,
                  hint: l10n.scheduleDefaultMosque,
                  onChanged: (id) {
                    if (id != null) {
                      onChanged(rule.copyWith(mosqueId: id));
                    }
                  },
                ),
              ),
              IconButton(
                tooltip: MaterialLocalizations.of(context).deleteButtonTooltip,
                onPressed: onRemove,
                icon: Icon(Icons.delete_outline, size: 20, color: q.ink3),
              ),
            ],
          ),
          const SizedBox(height: QSpace.s2),
          Wrap(
            spacing: QSpace.s2,
            runSpacing: QSpace.s2,
            children: [
              for (var d = 1; d <= 7; d++)
                QChip(
                  label: l10n.weekdayShort('$d'),
                  active: rule.days.contains(d),
                  onTap: () {
                    final next = {...rule.days};
                    if (!next.remove(d)) {
                      next.add(d);
                    }
                    onChanged(rule.copyWith(days: next));
                  },
                ),
            ],
          ),
          if (rule.days.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: QSpace.s1),
              child: Text(
                l10n.scheduleEveryDay,
                style: QType.caption.copyWith(color: q.ink3),
              ),
            ),
          const SizedBox(height: QSpace.s3),
          Row(
            children: [
              Text(
                l10n.scheduleFrom,
                style: QType.caption.copyWith(color: q.ink2),
              ),
              const SizedBox(width: QSpace.s2),
              _TimeChip(
                label: formatTime(rule.start),
                onTap: () => onPickTime(isStart: true),
              ),
              const SizedBox(width: QSpace.s3),
              Text(
                l10n.scheduleTo,
                style: QType.caption.copyWith(color: q.ink2),
              ),
              const SizedBox(width: QSpace.s2),
              _TimeChip(
                label: formatTime(rule.end),
                onTap: () => onPickTime(isStart: false),
              ),
              if (rule.allDay) ...[
                const SizedBox(width: QSpace.s3),
                Text(
                  l10n.scheduleAllDay,
                  style: QType.caption.copyWith(color: q.ink3),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

final class _TimeChip extends StatelessWidget {
  const _TimeChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final q = context.q;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(QRadius.full),
      // The pill stays compact; the transparent band makes the tap target
      // 48dp tall.
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: QTouch.minTarget),
        child: Center(
          widthFactor: 1,
          heightFactor: 1,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: QSpace.s3,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: q.surface,
              borderRadius: BorderRadius.circular(QRadius.full),
              border: Border.all(color: q.line),
            ),
            child: Text(
              label,
              style: QType.num_(QType.caption).copyWith(color: q.ink),
            ),
          ),
        ),
      ),
    );
  }
}

/// Profile picker used by the rule editor and the default-mosque selector.
final class _MosqueDropdown extends StatelessWidget {
  const _MosqueDropdown({
    required this.profiles,
    required this.value,
    required this.hint,
    required this.onChanged,
  });

  final List<MosqueProfile> profiles;
  final String? value;
  final String hint;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final q = context.q;
    final valid = profiles.any((p) => p.id == value) ? value : null;
    return DropdownButton<String>(
      value: valid,
      isExpanded: true,
      hint: Text(hint, style: QType.caption.copyWith(color: q.ink3)),
      underline: const SizedBox.shrink(),
      items: [
        for (final p in profiles)
          DropdownMenuItem(
            value: p.id,
            child: Text(p.name, style: QType.titleSm.copyWith(color: q.ink)),
          ),
      ],
      onChanged: onChanged,
    );
  }
}
