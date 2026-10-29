import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../../core/di/locator.dart';
import '../../../../core/theme/productive_muslim_tokens.dart';
import '../../../../core/theme/productive_muslim_typography.dart';
import '../../../../core/utils/locale_digits.dart';
import '../../../../shared/extensions/context_ext.dart';
import '../../../../shared/widgets/q_banner.dart';
import '../../../../shared/widgets/q_button.dart';
import '../../../../shared/widgets/q_chip.dart';
import '../../../prayer_times/presentation/state/home_store.dart';
import '../../../settings/domain/entities/prayer_params.dart';
import '../../domain/entities/jamaat_config.dart';
import '../../domain/entities/mosque_profile.dart';
import '../../domain/entities/mosque_schedule.dart';
import '../../domain/entities/mosque_state.dart';
import '../state/mosque_store.dart';
import '../widgets/mosque_schedule_section.dart';
import '../widgets/prayer_jamaat_card.dart';

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
  late final void Function() _unwatchSaves;

  @override
  void initState() {
    super.initState();
    // Tell the user when a change couldn't be saved (it was rolled back).
    final seen = _store.saveFailures.value;
    _unwatchSaves = _store.saveFailures.subscribe((n) {
      if (n != seen && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.l10n.expenseSaveFailed)));
      }
    });
  }

  @override
  void dispose() {
    _unwatchSaves();
    super.dispose();
  }

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
      builder: (dialogContext) => _NameDialog(title: l10n.addProfile),
    );
    if (name != null) {
      await _store.addProfile(name.isEmpty ? l10n.defaultProfileName : name);
    }
  }

  Future<void> _renameProfile(MosqueProfile profile) async {
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => _NameDialog(
        title: context.l10n.mosqueRenameProfile,
        initial: profile.name,
      ),
    );
    if (name != null && name.isNotEmpty && name != profile.name) {
      await _store.renameProfile(profile.id, name);
    }
  }

  /// One tap deletes a whole rule, so offer a brief undo.
  void _removeRule(MosqueState state, int index) {
    final rule = state.rules[index];
    unawaited(_store.removeRule(index));
    final l10n = context.l10n;
    ScaffoldMessenger.of(context)
      ..removeCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(l10n.scheduleRuleRemoved),
          persist: false,
          action: SnackBarAction(
            label: l10n.expenseUndo,
            onPressed: () => unawaited(_store.insertRule(index, rule)),
          ),
        ),
      );
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

  /// Today's start of [prayer]'s waqt, when a location is set.
  DateTime? _waqtStart(Prayer prayer) => locator.isRegistered<HomeStore>()
      ? locator<HomeStore>().prayerDay.value?.startOf(prayer)
      : null;

  Future<void> _pickFixedTime(MosqueProfile profile, Prayer prayer) async {
    // Start from the current jamaat (or waqt) time so the picker opens
    // near a sensible value for this prayer.
    final start = _waqtStart(prayer);
    final computed = start == null
        ? null
        : profile.config.timeFor(prayer, start) ?? start;
    final current = switch (profile.entries[prayer]) {
      FixedJamaat(:final time) => TimeOfDay(
        hour: time.hour,
        minute: time.minute,
      ),
      _ when computed != null => TimeOfDay.fromDateTime(computed),
      _ => const TimeOfDay(hour: 13, minute: 15),
    };
    final picked = await showTimePicker(context: context, initialTime: current);
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
      body: SignalBuilder(
        builder: (context) {
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
                      GestureDetector(
                        onLongPress: () => unawaited(_renameProfile(profile)),
                        child: QChip(
                          label: profile.name,
                          icon: Icons.mosque_outlined,
                          active: profile.id == active?.id,
                          onTap: () => unawaited(_store.setActive(profile.id)),
                        ),
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
              MosqueScheduleSection(
                state: state,
                formatTime: (t) => _formatTime(context, t),
                onModeChanged: (m) => unawaited(_store.setMode(m)),
                onAddRule: () => unawaited(_addRule(state)),
                onRemoveRule: (i) => _removeRule(state, i),
                onRuleChanged: (i, r) => unawaited(_store.updateRule(i, r)),
                onDefaultChanged: (id) =>
                    unawaited(_store.setDefaultMosque(id)),
                onPickRuleTime: (i, {required bool isStart}) =>
                    unawaited(_pickRuleTime(state, i, isStart: isStart)),
              ),
              const SizedBox(height: QSpace.s5),
              if (active != null) ...[
                for (final prayer in Prayer.values) ...[
                  PrayerJamaatCard(
                    prayer: prayer,
                    entry: active.entries[prayer] ?? const NoJamaat(),
                    formatTime: (t) => _formatTime(context, t),
                    onChanged: (entry) =>
                        unawaited(_store.setEntry(active.id, prayer, entry)),
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
        },
      ),
    );
  }
}

/// Owns its text controller so the dialog's exit animation never touches
/// a disposed controller.
final class _NameDialog extends StatefulWidget {
  const _NameDialog({required this.title, this.initial = ''});

  final String title;
  final String initial;

  @override
  State<_NameDialog> createState() => _NameDialogState();
}

final class _NameDialogState extends State<_NameDialog> {
  late final _controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(widget.title),
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
          onPressed: () => Navigator.of(context).pop(_controller.text.trim()),
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
            QButton(label: l10n.addProfile, icon: Icons.add, onPressed: onAdd),
          ],
        ),
      ),
    );
  }
}
