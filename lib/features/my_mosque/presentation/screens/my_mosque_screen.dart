import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../../core/di/locator.dart';
import '../../../../core/theme/qalbee_tokens.dart';
import '../../../../core/theme/qalbee_typography.dart';
import '../../../../core/utils/locale_digits.dart';
import '../../../../shared/extensions/context_ext.dart';
import '../../../../shared/widgets/q_banner.dart';
import '../../../../shared/widgets/q_button.dart';
import '../../../../shared/widgets/q_card.dart';
import '../../../../shared/widgets/q_chip.dart';
import '../../../../shared/widgets/q_seg_control.dart';
import '../../../settings/domain/entities/prayer_params.dart';
import '../../../settings/presentation/widgets/setting_labels.dart';
import '../../domain/entities/jamaat_config.dart';
import '../../domain/entities/mosque_profile.dart';
import '../../domain/entities/mosque_schedule.dart';
import '../../domain/entities/mosque_state.dart';
import '../state/mosque_store.dart';

/// My Mosque (design §4.9): per-prayer jamaat as fixed time OR offset from
/// waqt start (Maghrib defaults +5), multiple profiles with an active
/// switcher. Reminder lead/toggle lives in Notification settings.
final class MyMosqueScreen extends StatefulWidget {
  const MyMosqueScreen({super.key});

  @override
  State<MyMosqueScreen> createState() => _MyMosqueScreenState();
}

final class _MyMosqueScreenState extends State<MyMosqueScreen> {
  final MosqueStore _store = locator<MosqueStore>();

  String _formatTime(BuildContext context, ClockTime time) {
    final locale = Localizations.localeOf(context);
    final dt = DateTime(2026, 1, 1, time.hour, time.minute);
    return LocaleDigits.localize(
      DateFormat.jm(locale.toString()).format(dt),
      locale.languageCode,
    );
  }

  Future<void> _addProfile() async {
    final l10n = context.l10n;
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => const _NameDialog(),
    );
    if (name != null) {
      await _store.addProfile(name.isEmpty ? l10n.defaultProfileName : name);
    }
  }

  Future<void> _deleteProfile(MosqueProfile profile) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.deleteProfile),
        content: Text(l10n.deleteProfileConfirm(profile.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed ?? false) {
      await _store.deleteProfile(profile.id);
    }
  }

  Future<void> _pickFixedTime(MosqueProfile profile, Prayer prayer) async {
    final existing = switch (profile.entries[prayer]) {
      FixedJamaat(:final time) => TimeOfDay(
          hour: time.hour,
          minute: time.minute,
        ),
      _ => const TimeOfDay(hour: 13, minute: 15),
    };
    final picked = await showTimePicker(
      context: context,
      initialTime: existing,
    );
    if (picked != null) {
      await _store.setEntry(
        profile.id,
        prayer,
        FixedJamaat(ClockTime(picked.hour, picked.minute)),
      );
    }
  }

  Future<void> _addRule(MosqueState state) async {
    if (state.profiles.isEmpty) {
      return;
    }
    await _store.addRule(
      MosqueRule(
        mosqueId: state.profiles.first.id,
        start: const ClockTime(0, 0),
        end: const ClockTime(0, 0),
      ),
    );
  }

  Future<void> _pickRuleTime(
    MosqueState state,
    int index, {
    required bool isStart,
  }) async {
    final rule = state.rules[index];
    final current = isStart ? rule.start : rule.end;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: current.hour, minute: current.minute),
    );
    if (picked == null) {
      return;
    }
    final clock = ClockTime(picked.hour, picked.minute);
    await _store.updateRule(
      index,
      isStart ? rule.copyWith(start: clock) : rule.copyWith(end: clock),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final q = context.q;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.myMosqueTitle)),
      body: SignalBuilder(builder: (context) {
        final state = _store.state.value;
        final active = _store.activeProfile.value;
        if (state.profiles.isEmpty) {
          return _EmptyState(onAdd: () => unawaited(_addProfile()));
        }
        return ListView(
          padding: const EdgeInsets.all(QSpace.s5),
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final profile in state.profiles) ...[
                    QChip(
                      label: profile.name,
                      icon: Icons.mosque_outlined,
                      active: profile.id == state.activeId,
                      onTap: () => unawaited(_store.setActive(profile.id)),
                    ),
                    const SizedBox(width: QSpace.s2),
                  ],
                  QChip(
                    label: l10n.addProfile,
                    icon: Icons.add,
                    onTap: () => unawaited(_addProfile()),
                  ),
                ],
              ),
            ),
            const SizedBox(height: QSpace.s5),
            _ScheduleSection(
              state: state,
              formatTime: (t) => _formatTime(context, t),
              onModeChanged: (m) => unawaited(_store.setMode(m)),
              onAddRule: () => unawaited(_addRule(state)),
              onRemoveRule: (i) => unawaited(_store.removeRule(i)),
              onRuleChanged: (i, r) => unawaited(_store.updateRule(i, r)),
              onDefaultChanged: (id) => unawaited(_store.setDefaultMosque(id)),
              onPickRuleTime: (i, {required bool isStart}) =>
                  unawaited(_pickRuleTime(state, i, isStart: isStart)),
            ),
            const SizedBox(height: QSpace.s5),
            if (active != null) ...[
              for (final prayer in Prayer.values) ...[
                _PrayerJamaatCard(
                  prayer: prayer,
                  entry: active.entries[prayer] ?? const NoJamaat(),
                  formatTime: (t) => _formatTime(context, t),
                  onChanged: (entry) => unawaited(
                    _store.setEntry(active.id, prayer, entry),
                  ),
                  onPickTime: () => unawaited(_pickFixedTime(active, prayer)),
                ),
                const SizedBox(height: QSpace.s3),
              ],
              const SizedBox(height: QSpace.s2),
              QBanner(
                text: l10n.jamaatReminderHint,
                icon: Icons.notifications_outlined,
                tone: q.surface2,
                foreground: q.ink2,
              ),
              const SizedBox(height: QSpace.s4),
              Center(
                child: QButton(
                  label: l10n.deleteProfile,
                  kind: QButtonKind.ghost,
                  small: true,
                  icon: Icons.delete_outline,
                  onPressed: () => unawaited(_deleteProfile(active)),
                ),
              ),
            ],
            const SizedBox(height: QSpace.s10),
          ],
        );
      }),
    );
  }
}

/// Manual/auto mode toggle plus the auto-switch rules editor and the default
/// mosque picker (design §4.9 scheduled profiles).
final class _ScheduleSection extends StatelessWidget {
  const _ScheduleSection({
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
              SizedBox(
                width: 180,
                child: QSegControl(
                  options: [l10n.scheduleModeManual, l10n.scheduleModeAuto],
                  activeIndex: auto ? 1 : 0,
                  onChanged: (i) => onModeChanged(
                    i == 1 ? ScheduleMode.auto : ScheduleMode.manual,
                  ),
                ),
              ),
            ],
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
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
            child: Text(
              p.name,
              style: QType.titleSm.copyWith(color: q.ink),
            ),
          ),
      ],
      onChanged: onChanged,
    );
  }
}

final class _PrayerJamaatCard extends StatelessWidget {
  const _PrayerJamaatCard({
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
                      onTap: offset.inMinutes > 5
                          ? () => onChanged(
                                OffsetJamaat(
                                  offset - const Duration(minutes: 5),
                                ),
                              )
                          : null,
                    ),
                    SizedBox(
                      width: 64,
                      child: Text(
                        l10n.minutesShort(offset.inMinutes),
                        textAlign: TextAlign.center,
                        style:
                            QType.num_(QType.label).copyWith(color: q.ink),
                      ),
                    ),
                    _StepButton(
                      icon: Icons.add,
                      onTap: offset.inMinutes < 60
                          ? () => onChanged(
                                OffsetJamaat(
                                  offset + const Duration(minutes: 5),
                                ),
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
                        style: QType.num_(QType.caption)
                            .copyWith(color: q.ink2),
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
  const _StepButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final q = context.q;
    return InkWell(
      borderRadius: BorderRadius.circular(QRadius.full),
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(color: q.surface2, shape: BoxShape.circle),
        child: Icon(icon, size: 16, color: onTap == null ? q.ink3 : q.ink),
      ),
    );
  }
}

/// Owns its text controller so the dialog's exit animation never touches
/// a disposed controller.
final class _NameDialog extends StatefulWidget {
  const _NameDialog();

  @override
  State<_NameDialog> createState() => _NameDialogState();
}

final class _NameDialogState extends State<_NameDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(l10n.addProfile),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: InputDecoration(hintText: l10n.profileNameHint),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () =>
              Navigator.of(context).pop(_controller.text.trim()),
          child: Text(l10n.save),
        ),
      ],
    );
  }
}

final class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final q = context.q;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(QSpace.s8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.mosque_outlined, size: 56, color: q.ink3),
            const SizedBox(height: QSpace.s4),
            Text(
              l10n.myMosqueSubtitle,
              textAlign: TextAlign.center,
              style: QType.body.copyWith(color: q.ink2),
            ),
            const SizedBox(height: QSpace.s6),
            QButton(
              label: l10n.addProfile,
              icon: Icons.add,
              onPressed: onAdd,
            ),
          ],
        ),
      ),
    );
  }
}
