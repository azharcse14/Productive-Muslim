import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../../core/di/locator.dart';
import '../../../../core/theme/productive_muslim_tokens.dart';
import '../../../../core/theme/productive_muslim_typography.dart';
import '../../../../core/utils/haptics.dart';
import '../../../../core/utils/locale_digits.dart';
import '../../../../shared/extensions/context_ext.dart';
import '../../../../shared/widgets/q_button.dart';
import '../../../../shared/widgets/q_card.dart';
import '../../../../shared/widgets/q_error_retry.dart';
import '../../../../shared/widgets/q_heatmap.dart';
import '../../../../shared/widgets/q_number_dialog.dart';
import '../../../../shared/widgets/q_skeleton.dart';
import '../../../prayer_times/presentation/state/home_store.dart';
import '../../domain/entities/fasting_stats.dart';
import '../../domain/entities/recommended_fast.dart';
import '../state/fasting_store.dart';

/// Sunnah / nafl fasting tracker: today's recommended fast (with a log
/// toggle), the upcoming recommended days, and a no-shame personal log with
/// a month heatmap.
final class FastingScreen extends StatefulWidget {
  const FastingScreen({super.key});

  @override
  State<FastingScreen> createState() => _FastingScreenState();
}

final class _FastingScreenState extends State<FastingScreen> {
  // App-scoped store — never disposed here.
  late final FastingStore _store = locator<FastingStore>();

  /// The log couldn't be read; the screen offers a retry.
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

  void _snack(SnackBar bar) => ScaffoldMessenger.of(context)
    ..removeCurrentSnackBar()
    ..showSnackBar(bar);

  Future<void> _toggle(DateTime date, {bool asQaza = false}) async {
    final wasLogged = _store.isLogged(date);
    final wasQaza = _store.isQaza(date);
    try {
      await _store.toggle(date, asQaza: asQaza);
    } on Object {
      // The store already put the log back; say why the tick vanished.
      if (mounted) {
        _snack(SnackBar(content: Text(context.l10n.saveFailed)));
      }
      return;
    }
    // Un-logging is one tap on a filled cell: make it recoverable.
    if (wasLogged && mounted) {
      _snack(
        SnackBar(
          content: Text(context.l10n.fastingUnlogged),
          persist: false,
          action: SnackBarAction(
            label: context.l10n.undo,
            onPressed: () {
              if (!_store.isLogged(date)) {
                unawaited(_toggle(date, asQaza: wasQaza));
              }
            },
          ),
        ),
      );
    }
  }

  /// Logs/un-logs [date], asking nafl vs qaza for a new non-Ramadan fast
  /// that isn't a recommended (sunnah) day.
  Future<void> _log(DateTime date, {bool ask = true}) async {
    if (_store.isLogged(date) ||
        !ask ||
        _store.isRamadan(date) ||
        !_store.canLog(date)) {
      return _toggle(date);
    }
    final asQaza = await _chooseType(context);
    if (asQaza != null) {
      await _toggle(date, asQaza: asQaza);
    }
  }

  Future<void> _setOwed(BuildContext context) async {
    final l10n = context.l10n;
    // 0 clears the count (the store treats 0 as unset).
    final owed = await showNumberDialog(
      context,
      title: l10n.fastingQazaSetOwed,
      hint: l10n.fastingQazaOwedInvalid,
      actionLabel: l10n.save,
      min: 0,
      initial: _store.qazaOwed.value,
    );
    if (owed == null) {
      return;
    }
    try {
      await _store.setQazaOwed(owed);
    } on Object {
      if (mounted) {
        _snack(SnackBar(content: Text(l10n.saveFailed)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.fastingTitle)),
      body: SafeArea(
        child: SignalBuilder(
          builder: (context) {
            if (_loadFailed) {
              return QErrorRetry(
                message: l10n.dataLoadFailed,
                retryLabel: l10n.hadithRetry,
                onRetry: _load,
              );
            }
            if (!_store.loaded.value) {
              return const QSkeletonList(count: 3, height: 160);
            }
            // Touch the signals so the builder re-runs on change.
            _store.logged.value;
            _store.qaza.value;
            _store.qazaOwed.value;
            // Home's day signal flips at midnight, so "today" follows it.
            if (locator.isRegistered<HomeStore>()) {
              locator<HomeStore>().dateKey.value;
            }
            final today = _store.today;
            final todays = _store.recommendedOn(today);
            final upcoming = _store.upcoming();
            final stats = _store.stats();
            return ListView(
              padding: const EdgeInsets.fromLTRB(
                QSpace.s5,
                QSpace.s3,
                QSpace.s5,
                QSpace.s5,
              ),
              children: [
                _TodayCard(
                  date: today,
                  fasts: todays,
                  forbidden: _store.isForbidden(today),
                  ramadan: _store.isRamadan(today),
                  logged: _store.isLogged(today),
                  // A recommended day is the sunnah fast; otherwise ask.
                  onToggle: () => _log(today, ask: todays.isEmpty),
                ),
                const SizedBox(height: QSpace.s4),
                _StatsCard(
                  stats: stats,
                  weeks: _store.monthHeatmap(),
                  today: today,
                  dateAt: _store.heatmapDate,
                  isLogged: _store.isLogged,
                  // Past/today days toggle; future & forbidden ones can't
                  // be logged (removing stays allowed).
                  onDayTap: (date) {
                    if (_store.isLogged(date) || _store.canLog(date)) {
                      Haptics.selection();
                      unawaited(_log(date));
                    }
                  },
                ),
                if (upcoming.isNotEmpty) ...[
                  const SizedBox(height: QSpace.s4),
                  _UpcomingCard(
                    upcoming: upcoming,
                    isLogged: _store.isLogged,
                    canLog: _store.canLog,
                    // Rows are plain InkWells; the today card's QButton
                    // already buzzes on its own.
                    onToggle: (date) {
                      Haptics.selection();
                      unawaited(_toggle(date));
                    },
                  ),
                ],
                const SizedBox(height: QSpace.s4),
                _QazaCard(
                  done: _store.qaza.value.length,
                  owed: _store.qazaOwed.value,
                  onSetOwed: () => unawaited(_setOwed(context)),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// "Today" card — is today a recommended fast, its virtue, and a toggle.
final class _TodayCard extends StatelessWidget {
  const _TodayCard({
    required this.date,
    required this.fasts,
    required this.forbidden,
    required this.ramadan,
    required this.logged,
    required this.onToggle,
  });

  final DateTime date;
  final List<RecommendedFast> fasts;

  /// Eid / Tashreeq — fasting is not permitted, so no log button.
  final bool forbidden;

  /// Ramadan — the obligatory fast, logged as such (not "voluntary").
  final bool ramadan;
  final bool logged;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final q = context.q;
    final recommended = fasts.isNotEmpty;
    return QCard(
      tone: recommended ? q.primarySoft : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                recommended
                    ? Icons.wb_twilight_outlined
                    : Icons.nightlight_round,
                size: 20,
                color: recommended ? q.onPrimarySoft : q.ink2,
              ),
              const SizedBox(width: QSpace.s2),
              Expanded(
                child: Text(
                  recommended
                      ? l10n.fastingTodayRecommended
                      : forbidden
                      ? l10n.fastingTodayForbidden
                      : ramadan
                      ? l10n.fastingTodayRamadan
                      : l10n.fastingTodayNone,
                  style: QType.titleSm.copyWith(
                    color: recommended ? q.onPrimarySoft : q.ink,
                  ),
                ),
              ),
            ],
          ),
          if (recommended) ...[
            for (final fast in fasts) ...[
              const SizedBox(height: QSpace.s3),
              Text(
                l10n.fastingKindName(fast.id),
                style: QType.titleSm.copyWith(color: q.ink),
              ),
              const SizedBox(height: 2),
              Text(
                l10n.fastingKindNote(fast.id),
                style: QType.body.copyWith(color: q.ink2),
              ),
            ],
            const SizedBox(height: QSpace.s4),
            QButton(
              label: logged ? l10n.fastingLoggedToday : l10n.fastingLogToday,
              icon: logged ? Icons.check_circle_outline : Icons.add,
              kind: logged ? QButtonKind.tonal : QButtonKind.primary,
              expand: true,
              onPressed: onToggle,
            ),
          ] else if (forbidden) ...[
            const SizedBox(height: QSpace.s2),
            Text(
              l10n.fastingTodayForbiddenNote,
              style: QType.body.copyWith(color: q.ink2),
            ),
          ] else ...[
            const SizedBox(height: QSpace.s2),
            Text(
              ramadan
                  ? l10n.fastingTodayRamadanNote
                  : l10n.fastingTodayNoneNote,
              style: QType.body.copyWith(color: q.ink2),
            ),
            const SizedBox(height: QSpace.s4),
            QButton(
              label: logged
                  ? l10n.fastingLoggedToday
                  : ramadan
                  ? l10n.fastingLogToday
                  : l10n.fastingLogVoluntary,
              icon: logged ? Icons.check_circle_outline : Icons.add,
              kind: logged ? QButtonKind.tonal : QButtonKind.outline,
              expand: true,
              onPressed: onToggle,
            ),
          ],
        ],
      ),
    );
  }
}

/// Nafl or qaza? Null when dismissed.
Future<bool?> _chooseType(BuildContext context) {
  final l10n = context.l10n;
  return showModalBottomSheet<bool>(
    context: context,
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              QSpace.s5,
              QSpace.s5,
              QSpace.s5,
              QSpace.s2,
            ),
            child: Text(
              l10n.fastTypeTitle,
              style: QType.title.copyWith(color: sheetContext.q.ink),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.wb_twilight_outlined),
            title: Text(l10n.fastTypeNafl),
            onTap: () => Navigator.of(sheetContext).pop(false),
          ),
          ListTile(
            leading: const Icon(Icons.replay_outlined),
            title: Text(l10n.fastTypeQaza),
            onTap: () => Navigator.of(sheetContext).pop(true),
          ),
          const SizedBox(height: QSpace.s3),
        ],
      ),
    ),
  );
}

/// Qaza (make-up) counter: how many are made up, of an optional owed total.
final class _QazaCard extends StatelessWidget {
  const _QazaCard({
    required this.done,
    required this.owed,
    required this.onSetOwed,
  });

  final int done;
  final int? owed;
  final VoidCallback onSetOwed;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final q = context.q;
    final code = Localizations.localeOf(context).languageCode;
    final owed = this.owed;
    // The button sits under the progress, not beside it: a long label
    // must not squeeze the text column.
    return QCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.fastingQazaTitle,
            style: QType.titleSm.copyWith(color: q.ink),
          ),
          const SizedBox(height: 2),
          Text(
            LocaleDigits.localize(
              owed == null
                  ? l10n.fastingQazaMadeUp(done)
                  : l10n.fastingQazaOfOwed(done, owed),
              code,
            ),
            style: QType.caption.copyWith(color: q.ink2),
          ),
          if (owed != null) ...[
            const SizedBox(height: QSpace.s2),
            ClipRRect(
              borderRadius: BorderRadius.circular(QRadius.full),
              child: LinearProgressIndicator(
                value: (done / owed).clamp(0.0, 1.0),
                minHeight: 6,
                color: q.primary,
                backgroundColor: q.surface2,
              ),
            ),
          ],
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: TextButton(
              onPressed: onSetOwed,
              child: Text(l10n.fastingQazaSetOwed),
            ),
          ),
        ],
      ),
    );
  }
}

/// Personal log stats + a month heatmap (no-shame framing). Heatmap days
/// are tappable to log or remove a fast.
final class _StatsCard extends StatelessWidget {
  const _StatsCard({
    required this.stats,
    required this.weeks,
    required this.today,
    required this.dateAt,
    required this.isLogged,
    required this.onDayTap,
  });

  final FastingStats stats;
  final List<List<int>> weeks;
  final DateTime today;
  final DateTime? Function(int week, int day) dateAt;
  final bool Function(DateTime) isLogged;
  final ValueChanged<DateTime> onDayTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final q = context.q;
    final code = Localizations.localeOf(context).languageCode;
    String n(int v) => LocaleDigits.localize('$v', code);
    // Same Sunday-first padding as monthHeatmap.
    final todayCell =
        today.day - 1 + DateTime(today.year, today.month).weekday % 7;
    return QCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.fastingLogTitle,
            style: QType.titleSm.copyWith(color: q.ink),
          ),
          const SizedBox(height: QSpace.s3),
          Row(
            children: [
              Expanded(
                child: _Stat(
                  value: n(stats.total),
                  label: l10n.fastingNaflTotal,
                ),
              ),
              Expanded(
                child: _Stat(
                  value: n(stats.thisMonth),
                  label: l10n.fastingThisMonth,
                ),
              ),
              Expanded(
                child: _Stat(
                  value: n(stats.thisHijriMonth),
                  label: l10n.fastingThisHijriMonth,
                ),
              ),
            ],
          ),
          const SizedBox(height: QSpace.s4),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: QHeatmap(
              weeks: weeks,
              semanticLabel: l10n.fastingHeatmapLabel(stats.thisMonth),
              highlight: (todayCell ~/ 7, todayCell % 7),
              cellLabel: (w, d) {
                final date = dateAt(w, d);
                if (date == null) {
                  return '';
                }
                return LocaleDigits.localize(
                  '${DateFormat.MMMEd(code).format(date)}: '
                  '${isLogged(date) ? l10n.fastingFasted : l10n.notYet}',
                  code,
                );
              },
              onTap: (w, d) {
                if (dateAt(w, d) case final date?) {
                  onDayTap(date);
                }
              },
            ),
          ),
          const SizedBox(height: QSpace.s2),
          Text(
            l10n.fastingHeatmapHint,
            style: QType.caption.copyWith(color: q.ink3),
          ),
          const SizedBox(height: QSpace.s3),
          Row(
            children: [
              Text(l10n.notYet, style: QType.caption.copyWith(color: q.ink2)),
              const SizedBox(width: QSpace.s2),
              const QHeatmapCell(level: 0),
              const SizedBox(width: 3.5),
              const QHeatmapCell(level: 4),
              const SizedBox(width: QSpace.s2),
              Text(
                l10n.fastingFasted,
                style: QType.caption.copyWith(color: q.ink2),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

final class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final q = context.q;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: QType.num_(QType.title).copyWith(color: q.primary)),
        const SizedBox(height: 2),
        Text(label, style: QType.caption.copyWith(color: q.ink2)),
      ],
    );
  }
}

/// The next recommended fasting days, each tappable to log/un-log.
final class _UpcomingCard extends StatelessWidget {
  const _UpcomingCard({
    required this.upcoming,
    required this.isLogged,
    required this.canLog,
    required this.onToggle,
  });

  final List<UpcomingFast> upcoming;
  final bool Function(DateTime) isLogged;
  final bool Function(DateTime) canLog;
  final void Function(DateTime) onToggle;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final q = context.q;
    final code = Localizations.localeOf(context).languageCode;
    final dateFmt = DateFormat.MMMEd(code);
    return QCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.fastingUpcomingTitle,
            style: QType.titleSm.copyWith(color: q.ink),
          ),
          for (final (i, item) in upcoming.indexed) ...[
            if (i > 0) Divider(color: q.line),
            _UpcomingRow(
              item: item,
              subtitle: LocaleDigits.localize(
                dateFmt.format(item.fast.date),
                code,
              ),
              logged: isLogged(item.fast.date),
              // Future days can't be logged yet (un-logging stays allowed).
              onToggle: isLogged(item.fast.date) || canLog(item.fast.date)
                  ? () => onToggle(item.fast.date)
                  : null,
            ),
          ],
        ],
      ),
    );
  }
}

final class _UpcomingRow extends StatelessWidget {
  const _UpcomingRow({
    required this.item,
    required this.subtitle,
    required this.logged,
    required this.onToggle,
  });

  final UpcomingFast item;
  final String subtitle;
  final bool logged;

  /// Null when the day can't be logged yet (it's in the future).
  final VoidCallback? onToggle;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final q = context.q;
    return Semantics(
      button: true,
      enabled: onToggle != null,
      checked: logged,
      child: InkWell(
        onTap: onToggle,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: QSpace.s3),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.fastingKindName(item.fast.id),
                      style: QType.titleSm.copyWith(color: q.ink),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      subtitle,
                      style: QType.caption.copyWith(color: q.ink2),
                    ),
                  ],
                ),
              ),
              Icon(
                logged
                    ? Icons.check_circle
                    : onToggle == null
                    ? Icons.schedule
                    : Icons.radio_button_unchecked,
                size: 22,
                color: logged ? q.primary : q.ink3,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
