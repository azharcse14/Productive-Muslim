import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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
import '../../domain/usecases/resolve_active_mosque.dart';

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
    required this.now,
    required this.onAddSeason,
    required this.onSeasonChanged,
  });

  /// The moment the "active now" line resolves for.
  final DateTime now;
  final VoidCallback onAddSeason;

  /// Edits the season at an index; a null season removes it.
  final void Function(int index, MosqueSeason? season) onSeasonChanged;

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
            if (_activeNow(context) case final line?) ...[
              const SizedBox(height: QSpace.s2),
              Text(line, style: QType.label.copyWith(color: q.primary)),
            ],
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
              l10n.mosqueSeasonTitle,
              style: QType.label.copyWith(color: q.ink),
            ),
            const SizedBox(height: QSpace.s1),
            Text(
              l10n.mosqueSeasonHint,
              style: QType.caption.copyWith(color: q.ink3),
            ),
            const SizedBox(height: QSpace.s3),
            for (final (i, season) in state.seasons.indexed) ...[
              _SeasonCard(
                season: season,
                profiles: state.profiles,
                onChanged: (s) => onSeasonChanged(i, s),
              ),
              const SizedBox(height: QSpace.s3),
            ],
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: QButton(
                label: l10n.mosqueSeasonAdd,
                kind: QButtonKind.tonal,
                small: true,
                icon: Icons.add,
                onPressed: state.profiles.isEmpty ? null : onAddSeason,
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

  /// The "active now" line (mosque and why), or null with no profiles.
  String? _activeNow(BuildContext context) {
    final l10n = context.l10n;
    final r = resolveActiveMosque(state, now);
    final profile = r.profile;
    if (profile == null) {
      return null;
    }
    final why = switch (r.reason) {
      MosqueReason.rule => l10n.mosqueSeasonReasonRule,
      MosqueReason.season => l10n.mosqueSeasonReasonSeason(
        _range(
          context,
          state.seasons.firstWhere(
            (s) => s.mosqueId == profile.id && s.contains(now),
          ),
        ),
      ),
      MosqueReason.override => l10n.mosqueSeasonReasonOverride,
      MosqueReason.manual ||
      MosqueReason.fallback => l10n.mosqueSeasonReasonDefault,
    };
    return l10n.mosqueSeasonActiveNow(profile.name, why);
  }
}

String _range(BuildContext context, MosqueSeason s) {
  final fmt = DateFormat.MMMd(Localizations.localeOf(context).toString());
  // A leap year, so Feb 29 formats.
  String f(MonthDay d) => fmt.format(DateTime(2024, d.month, d.day));
  return '${f(s.start)} – ${f(s.end)}';
}

/// One yearly date range: profile picker plus month/day pickers per end.
final class _SeasonCard extends StatelessWidget {
  const _SeasonCard({
    required this.season,
    required this.profiles,
    required this.onChanged,
  });

  final MosqueSeason season;
  final List<MosqueProfile> profiles;
  final ValueChanged<MosqueSeason?> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final q = context.q;
    final months = DateFormat.MMM(Localizations.localeOf(context).toString());
    Widget picker(MonthDay value, ValueChanged<MonthDay> set) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        DropdownButton<int>(
          value: value.month,
          underline: const SizedBox.shrink(),
          items: [
            for (var m = 1; m <= 12; m++)
              DropdownMenuItem(
                value: m,
                child: Text(months.format(DateTime(2024, m))),
              ),
          ],
          onChanged: (m) {
            if (m != null) {
              // Keep the day valid for the new month (Jan 31 → Feb 29).
              final max = MosqueSeason.maxDay(m);
              set((month: m, day: value.day > max ? max : value.day));
            }
          },
        ),
        const SizedBox(width: QSpace.s2),
        DropdownButton<int>(
          value: value.day,
          underline: const SizedBox.shrink(),
          items: [
            for (var d = 1; d <= MosqueSeason.maxDay(value.month); d++)
              DropdownMenuItem(value: d, child: Text(context.digits('$d'))),
          ],
          onChanged: (d) {
            if (d != null) {
              set((month: value.month, day: d));
            }
          },
        ),
      ],
    );
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
                  value: season.mosqueId,
                  hint: l10n.scheduleDefaultMosque,
                  onChanged: (id) {
                    if (id != null) {
                      onChanged(season.copyWith(mosqueId: id));
                    }
                  },
                ),
              ),
              IconButton(
                tooltip: MaterialLocalizations.of(context).deleteButtonTooltip,
                onPressed: () => onChanged(null),
                icon: Icon(Icons.delete_outline, size: 20, color: q.ink3),
              ),
            ],
          ),
          Wrap(
            spacing: QSpace.s2,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                l10n.scheduleFrom,
                style: QType.caption.copyWith(color: q.ink2),
              ),
              picker(season.start, (d) => onChanged(season.copyWith(start: d))),
              Text(
                l10n.scheduleTo,
                style: QType.caption.copyWith(color: q.ink2),
              ),
              picker(season.end, (d) => onChanged(season.copyWith(end: d))),
            ],
          ),
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
          // Wraps at large text / narrow widths instead of overflowing.
          Wrap(
            spacing: QSpace.s2,
            runSpacing: QSpace.s2,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                l10n.scheduleFrom,
                style: QType.caption.copyWith(color: q.ink2),
              ),
              _TimeChip(
                label: formatTime(rule.start),
                onTap: () => onPickTime(isStart: true),
              ),
              Text(
                l10n.scheduleTo,
                style: QType.caption.copyWith(color: q.ink2),
              ),
              _TimeChip(
                label: formatTime(rule.end),
                onTap: () => onPickTime(isStart: false),
              ),
              if (rule.allDay)
                Text(
                  l10n.scheduleAllDay,
                  style: QType.caption.copyWith(color: q.ink3),
                ),
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
