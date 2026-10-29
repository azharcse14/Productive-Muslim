import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../../core/di/locator.dart';
import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/productive_muslim_tokens.dart';
import '../../../../core/theme/productive_muslim_typography.dart';
import '../../../../core/utils/locale_digits.dart';
import '../../../../shared/extensions/context_ext.dart';
import '../../../../shared/widgets/q_button.dart';
import '../../../../shared/widgets/q_card.dart';
import '../../../../shared/widgets/q_error_retry.dart';
import '../../../../shared/widgets/q_skeleton.dart';
import '../../../muhasaba/domain/entities/tracker_item.dart';
import '../../../muhasaba/presentation/state/muhasaba_store.dart';
import '../../../muhasaba/presentation/widgets/tracker_row.dart';
import '../../../prayer_times/presentation/state/home_store.dart';
import '../state/health_store.dart';

/// Sunnah-guided health: today's habits (the Muhasaba health trackers, so
/// they count toward its dashboard), a weight log, and prophetic guidance.
final class HealthScreen extends StatefulWidget {
  const HealthScreen({super.key});

  @override
  State<HealthScreen> createState() => _HealthScreenState();
}

final class _HealthScreenState extends State<HealthScreen> {
  // App-scoped stores — never disposed here.
  late final HealthStore _store = locator<HealthStore>();
  late final MuhasabaStore _muhasaba = locator<MuhasabaStore>();

  /// The weight log couldn't be read; its card offers a retry.
  bool _loadFailed = false;

  @override
  void initState() {
    super.initState();
    if (!_store.loaded.value) {
      _load();
    }
  }

  void _load() {
    if (_loadFailed) {
      setState(() => _loadFailed = false);
    }
    unawaited(
      _store.load().catchError((Object _) {
        if (mounted) {
          setState(() => _loadFailed = true);
        }
      }),
    );
  }

  void _snack(String message, {SnackBarAction? action}) =>
      ScaffoldMessenger.of(context)
        ..removeCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(message),
            persist: action == null ? null : false,
            action: action,
          ),
        );

  Future<void> _enableHabits() async {
    if (!await _muhasaba.enableHealthHabits() && mounted) {
      _snack(context.l10n.saveFailed);
    }
  }

  /// Saves [kg] for [day]; true when it was stored.
  Future<bool> _saveWeight(DateTime day, double? kg) async {
    try {
      if (await _store.setWeight(day, kg)) {
        return true;
      }
      if (mounted) {
        _snack(context.l10n.healthWeightInvalid);
      }
    } on Object {
      if (mounted) {
        _snack(context.l10n.saveFailed);
      }
    }
    return false;
  }

  /// Removes [day]'s weight and offers Undo (the dialog doesn't confirm).
  Future<void> _removeWeight(DateTime day, double previous) async {
    if (await _saveWeight(day, null) && mounted) {
      _snack(
        context.l10n.healthWeightRemoved,
        action: SnackBarAction(
          label: context.l10n.undo,
          onPressed: () => unawaited(_saveWeight(day, previous)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.healthTitle)),
      body: SafeArea(
        child: SignalBuilder(
          builder: (context) {
            // Home's day signal flips at midnight, so "today" follows it.
            if (locator.isRegistered<HomeStore>()) {
              locator<HomeStore>().dateKey.value;
            }
            final today = _muhasaba.today;
            final values = _muhasaba.entriesOn(today);
            final habits = [
              for (final i in _muhasaba.items.value)
                if (DefaultTrackers.healthIds.contains(i.id)) i,
            ];
            final archivedHabits = _muhasaba.archivedItems.value.any(
              (i) => DefaultTrackers.healthIds.contains(i.id),
            );
            return ListView(
              padding: const EdgeInsets.fromLTRB(
                QSpace.s5,
                QSpace.s3,
                QSpace.s5,
                QSpace.s5,
              ),
              children: [
                // No header over nothing: hidden when there are no
                // habits to show or restore.
                if (!_muhasaba.loaded.value ||
                    habits.isNotEmpty ||
                    archivedHabits)
                  _Section(l10n.healthToday),
                if (!_muhasaba.loaded.value) ...[
                  for (var i = 0; i < 3; i++) ...[
                    const QSkeleton(height: 56, radius: QRadius.md),
                    const SizedBox(height: QSpace.s2),
                  ],
                ] else if (habits.isEmpty && archivedHabits) ...[
                  Text(
                    l10n.healthNoHabits,
                    style: QType.body.copyWith(color: context.q.ink2),
                  ),
                  const SizedBox(height: QSpace.s3),
                  QButton(
                    label: l10n.healthEnableHabits,
                    icon: Icons.add_task_outlined,
                    kind: QButtonKind.tonal,
                    small: true,
                    onPressed: _enableHabits,
                  ),
                ],
                for (final item in habits) ...[
                  TrackerRow(
                    item: item,
                    value: values[item.id] ?? 0,
                    displayName: l10n.trackerName(item.name),
                    onChanged: (v) =>
                        unawaited(_muhasaba.setValueOn(item.id, today, v)),
                  ),
                  const SizedBox(height: QSpace.s2),
                ],
                const SizedBox(height: QSpace.s4),
                if (_loadFailed)
                  QCard(
                    child: QErrorRetry(
                      message: l10n.dataLoadFailed,
                      retryLabel: l10n.hadithRetry,
                      onRetry: _load,
                    ),
                  )
                else if (!_store.loaded.value)
                  const QSkeleton(height: 140, radius: QRadius.lg)
                else
                  _WeightCard(
                    history: _store.history,
                    today: _store.today,
                    onLog: (current) {
                      // Pinned at open: a save past midnight still edits
                      // the day the dialog showed.
                      final day = _store.today;
                      unawaited(
                        showDialog<void>(
                          context: context,
                          builder: (_) => _WeightDialog(
                            current: current,
                            onSave: (kg) => _saveWeight(day, kg),
                            onRemove: current == null
                                ? null
                                : () => _removeWeight(day, current),
                          ),
                        ),
                      );
                    },
                  ),
                const SizedBox(height: QSpace.s4),
                _Section(l10n.healthSunnahTitle),
                for (final (title, body, ref) in _tips(l10n)) ...[
                  QCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: QType.titleSm.copyWith(color: context.q.ink),
                        ),
                        const SizedBox(height: QSpace.s1),
                        Text(
                          body,
                          style: QType.body.copyWith(color: context.q.ink2),
                        ),
                        const SizedBox(height: QSpace.s1),
                        Text(
                          context.digits(ref),
                          style: QType.caption.copyWith(
                            color: context.q.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: QSpace.s3),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

List<(String, String, String)> _tips(AppLocalizations l10n) => [
  (l10n.healthTipEatTitle, l10n.healthTipEatBody, l10n.healthTipEatRef),
  (l10n.healthTipDrinkTitle, l10n.healthTipDrinkBody, l10n.healthTipDrinkRef),
  (l10n.healthTipSleepTitle, l10n.healthTipSleepBody, l10n.healthTipSleepRef),
  (
    l10n.healthTipMiswakTitle,
    l10n.healthTipMiswakBody,
    l10n.healthTipMiswakRef,
  ),
  (
    l10n.healthTipStrongTitle,
    l10n.healthTipStrongBody,
    l10n.healthTipStrongRef,
  ),
  (
    l10n.healthTipBlessingTitle,
    l10n.healthTipBlessingBody,
    l10n.healthTipBlessingRef,
  ),
];

final class _Section extends StatelessWidget {
  const _Section(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: QSpace.s3),
    child: Text(text, style: QType.titleSm.copyWith(color: context.q.ink)),
  );
}

/// Latest weight, change over the shown history, and the last few logs.
final class _WeightCard extends StatelessWidget {
  const _WeightCard({
    required this.history,
    required this.today,
    required this.onLog,
  });

  /// Newest first.
  final List<(DateTime, double)> history;
  final DateTime today;
  final void Function(double? current) onLog;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final q = context.q;
    final code = Localizations.localeOf(context).languageCode;
    String kg(double v) => l10n.healthKg(v.toStringAsFixed(1));
    final recent = history.take(7).toList();
    final todays = history.firstOrNull?.$1 == today ? history.first.$2 : null;
    final change = recent.length > 1 ? recent.first.$2 - recent.last.$2 : null;
    return QCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.healthWeightTitle,
            style: QType.caption.copyWith(color: q.ink2),
          ),
          const SizedBox(height: QSpace.s1),
          Text(
            context.digits(
              recent.isEmpty ? l10n.healthWeightEmpty : kg(recent.first.$2),
            ),
            style: QType.num_(QType.title).copyWith(color: q.ink),
          ),
          if (change != null)
            Text(
              context.digits(
                l10n.healthWeightChange(
                  '${change > 0 ? '+' : ''}${change.toStringAsFixed(1)}',
                ),
              ),
              style: QType.caption.copyWith(color: q.ink2),
            ),
          for (final (date, w) in recent.skip(1))
            Padding(
              padding: const EdgeInsets.only(top: QSpace.s1),
              child: Text(
                context.digits(
                  '${LocaleDigits.localize(DateFormat.MMMd(code).format(date), code)} · ${kg(w)}',
                ),
                style: QType.caption.copyWith(color: q.ink2),
              ),
            ),
          const SizedBox(height: QSpace.s3),
          QButton(
            label: todays == null
                ? l10n.healthWeightLog
                : l10n.healthWeightEdit,
            icon: Icons.monitor_weight_outlined,
            kind: QButtonKind.tonal,
            small: true,
            onPressed: () => onLog(todays),
          ),
        ],
      ),
    );
  }
}

/// Owns its controller so it outlives the dialog's exit animation
/// (mirrors the expense budget dialog).
final class _WeightDialog extends StatefulWidget {
  const _WeightDialog({
    required this.current,
    required this.onSave,
    required this.onRemove,
  });

  final double? current;
  final Future<void> Function(double) onSave;

  /// Null when there's nothing logged to remove.
  final Future<void> Function()? onRemove;

  @override
  State<_WeightDialog> createState() => _WeightDialogState();
}

final class _WeightDialogState extends State<_WeightDialog> {
  late final _controller = TextEditingController(
    text: widget.current == null
        ? ''
        : LocaleDigits.localize(
            widget.current!.toStringAsFixed(1),
            Localizations.localeOf(context).languageCode,
          ),
  );

  double? get _parsed {
    final v = double.tryParse(
      LocaleDigits.toAscii(_controller.text.trim()).replaceAll(',', '.'),
    );
    return v != null && v >= HealthStore.minKg && v <= HealthStore.maxKg
        ? v
        : null;
  }

  void _close(Future<void> pending) {
    unawaited(pending);
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = _controller.text.trim();
    return AlertDialog(
      title: Text(l10n.healthWeightTitle),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          hintText: l10n.healthWeightHint,
          errorText: text.isNotEmpty && _parsed == null
              ? l10n.healthWeightInvalid
              : null,
        ),
        onChanged: (_) => setState(() {}),
      ),
      actions: [
        if (widget.onRemove case final remove?)
          TextButton(
            onPressed: () => _close(remove()),
            child: Text(l10n.healthWeightRemove),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        TextButton(
          onPressed: _parsed == null
              ? null
              : () => _close(widget.onSave(_parsed!)),
          child: Text(l10n.save),
        ),
      ],
    );
  }
}
