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
import '../../../../shared/widgets/q_chip.dart';
import '../../../../shared/widgets/q_heatmap.dart';
import '../../../../shared/widgets/q_progress_ring.dart';
import '../../../../shared/widgets/q_seg_control.dart';
import '../../../achievements/presentation/widgets/achievements_summary_card.dart';
import '../../../settings/presentation/state/settings_store.dart';
import '../../domain/entities/period_stats.dart';
import '../../domain/entities/tracker_item.dart';
import '../state/muhasaba_store.dart';
import '../widgets/item_editor_sheet.dart';
import '../widgets/tracker_row.dart';
import '../widgets/tracker_visuals.dart';
import '../widgets/trend_line.dart';

/// Muhasaba (design §4.7): daily-entry checklist (Today) + dashboard
/// aggregates. Positive framing throughout — no shame states.
final class MuhasabaScreen extends StatefulWidget {
  const MuhasabaScreen({super.key});

  @override
  State<MuhasabaScreen> createState() => _MuhasabaScreenState();
}

final class _MuhasabaScreenState extends State<MuhasabaScreen> {
  // App-scoped store — never disposed here.
  late final MuhasabaStore _store = locator<MuhasabaStore>();

  int _tab = 0;
  bool _welcomeDismissed = false;

  String _nameOf(AppLocalizations l10n, TrackerItem item) =>
      item.isDefault ? l10n.trackerName(item.name) : item.name;

  String _percent(BuildContext context, double value) => LocaleDigits.localize(
    '${(value * 100).round()}%',
    Localizations.localeOf(context).languageCode,
  );

  void _showLockedToast(BuildContext context) {
    final messenger = ScaffoldMessenger.of(context)..clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Text(context.l10n.salahLockedToast),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.muhasabaTitle),
        actions: [
          IconButton(
            tooltip: l10n.addTracker,
            icon: const Icon(Icons.add),
            onPressed: () => unawaited(showItemEditor(context, _store)),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                QSpace.s5,
                QSpace.s3,
                QSpace.s5,
                0,
              ),
              child: QSegControl(
                options: [l10n.todayTab, l10n.dashboardTab],
                activeIndex: _tab,
                onChanged: (i) => setState(() => _tab = i),
              ),
            ),
            Expanded(
              child: SignalBuilder(
                builder: (context) =>
                    _tab == 0 ? _todayView(context) : _dashboardView(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---- Today -------------------------------------------------------------

  Widget _todayView(BuildContext context) {
    final l10n = context.l10n;
    if (_store.firstDay.value && !_welcomeDismissed) {
      return _welcome(context);
    }
    final items = _store.items.value;
    final salah = [
      for (final i in items)
        if (i.id.startsWith('salah_')) i,
    ];
    // Salah whose waqt hasn't begun yet on the selected date.
    final locked = _store.lockedSalah;
    final others = [
      for (final i in items)
        if (!i.id.startsWith('salah_')) i,
    ];
    final archived = _store.archivedItems.value;
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        QSpace.s5,
        QSpace.s3,
        QSpace.s5,
        QSpace.s5,
      ),
      children: [
        _dateSwitcher(context),
        const SizedBox(height: QSpace.s3),
        Wrap(
          spacing: QSpace.s2,
          runSpacing: QSpace.s2,
          children: [
            for (final item in salah)
              if (locked.contains(item.id))
                // Waqt hasn't started yet — a tap explains why.
                Opacity(
                  opacity: 0.45,
                  child: QChip(
                    label: _nameOf(l10n, item),
                    icon: Icons.schedule,
                    onTap: () => _showLockedToast(context),
                  ),
                )
              else
                QChip(
                  label: _nameOf(l10n, item),
                  active: _store.valueOf(item.id) > 0,
                  icon: Icons.mosque_outlined,
                  onTap: () => unawaited(
                    _store.setValue(
                      item.id,
                      _store.valueOf(item.id) > 0 ? 0 : 1,
                    ),
                  ),
                ),
          ],
        ),
        const SizedBox(height: QSpace.s3),
        for (final item in others) ...[
          TrackerRow(
            item: item,
            value: _store.valueOf(item.id),
            displayName: _nameOf(l10n, item),
            onChanged: (v) => unawaited(_store.setValue(item.id, v)),
            onEdit: () =>
                unawaited(showItemEditor(context, _store, existing: item)),
          ),
          const SizedBox(height: QSpace.s3),
        ],
        if (archived.isNotEmpty) ...[
          Text(
            l10n.archivedSection.toUpperCase(),
            style: context.text.labelSmall,
          ),
          const SizedBox(height: QSpace.s3),
          for (final item in archived) ...[
            Opacity(
              opacity: 0.55,
              child: TrackerRow(
                item: item,
                value: _store.valueOf(item.id),
                displayName: _nameOf(l10n, item),
                onChanged: null,
                onEdit: () =>
                    unawaited(showItemEditor(context, _store, existing: item)),
              ),
            ),
            const SizedBox(height: QSpace.s3),
          ],
        ],
      ],
    );
  }

  Widget _welcome(BuildContext context) {
    final l10n = context.l10n;
    final q = context.q;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(QSpace.s8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite_outline, size: 56, color: q.ink3),
            const SizedBox(height: QSpace.s5),
            Text(
              l10n.muhasabaFirstDayTitle,
              style: QType.title.copyWith(color: q.ink),
            ),
            const SizedBox(height: QSpace.s2),
            Text(
              l10n.muhasabaFirstDayBody,
              textAlign: TextAlign.center,
              style: QType.body.copyWith(color: q.ink2),
            ),
            const SizedBox(height: QSpace.s6),
            QButton(
              label: l10n.muhasabaStart,
              onPressed: () => setState(() => _welcomeDismissed = true),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dateSwitcher(BuildContext context) {
    final q = context.q;
    final locale = Localizations.localeOf(context);
    final selected = _store.selectedDate.value;
    final label = LocaleDigits.localize(
      DateFormat.MMMEd(locale.toString()).format(selected),
      locale.languageCode,
    );
    return Row(
      children: [
        IconButton(
          tooltip: context.l10n.previousDay,
          icon: const Icon(Icons.chevron_left),
          onPressed: () => unawaited(
            _store.selectDate(
              DateTime(selected.year, selected.month, selected.day - 1),
            ),
          ),
        ),
        Expanded(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: QType.titleSm.copyWith(color: q.ink),
          ),
        ),
        IconButton(
          tooltip: context.l10n.nextDay,
          icon: const Icon(Icons.chevron_right),
          onPressed: _store.canGoForward
              ? () => unawaited(
                  _store.selectDate(
                    DateTime(selected.year, selected.month, selected.day + 1),
                  ),
                )
              : null,
        ),
      ],
    );
  }

  // ---- Dashboard ---------------------------------------------------------

  Widget _dashboardView(BuildContext context) {
    final l10n = context.l10n;
    final q = context.q;
    final stats = _store.stats.value;
    return ListView(
      padding: const EdgeInsets.all(QSpace.s5),
      children: [
        QSegControl(
          options: [
            l10n.periodToday,
            l10n.periodWeek,
            l10n.periodMonth,
            l10n.periodYear,
          ],
          activeIndex: _store.period.value.index,
          onChanged: (i) =>
              unawaited(_store.setPeriod(MuhasabaPeriod.values[i])),
        ),
        const SizedBox(height: QSpace.s4),
        if (stats == null)
          const SizedBox.shrink()
        else if (stats.items.every((i) => i.totalValue == 0) &&
            stats.completion == 0)
          Padding(
            padding: const EdgeInsets.all(QSpace.s8),
            child: Center(
              child: Text(
                l10n.emptyRange,
                textAlign: TextAlign.center,
                style: QType.body.copyWith(color: q.ink2),
              ),
            ),
          )
        else ...[
          _headerCard(context, stats),
          const SizedBox(height: QSpace.s4),
          if (locator<SettingsStore>().settings.value.showAchievements) ...[
            const AchievementsSummaryCard(),
            const SizedBox(height: QSpace.s4),
          ],
          QCard(
            child: TrendLine(
              values: [for (final d in stats.days) d.completion],
              semanticLabel:
                  '${l10n.overallCompletion}: ${_percent(context, stats.completion)}',
            ),
          ),
          const SizedBox(height: QSpace.s4),
          _heatmapCard(context, stats),
          const SizedBox(height: QSpace.s4),
          _itemBarsCard(context, stats),
        ],
      ],
    );
  }

  Widget _headerCard(BuildContext context, PeriodStats stats) {
    final l10n = context.l10n;
    final q = context.q;
    final previous = stats.previousCompletion;
    final delta = previous == null ? null : stats.completion - previous;
    final trend = delta == null
        ? null
        : delta > 0.05
        ? 'up'
        : delta < -0.05
        ? 'down'
        : 'same';
    return QCard(
      child: Row(
        children: [
          QProgressRing(
            progress: stats.completion,
            size: 110,
            child: Text(
              _percent(context, stats.completion),
              style: QType.num_(QType.title).copyWith(color: q.ink),
            ),
          ),
          const SizedBox(width: QSpace.s4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.overallCompletion,
                  style: QType.caption.copyWith(color: q.ink2),
                ),
                const SizedBox(height: QSpace.s2),
                QChip(
                  label: l10n.currentStreakLabel(stats.currentStreak),
                  active: true,
                  icon: Icons.local_fire_department_outlined,
                ),
                const SizedBox(height: QSpace.s2),
                Text(
                  l10n.bestStreakLabel(stats.bestStreak),
                  style: QType.caption.copyWith(color: q.ink2),
                ),
                if (trend != null) ...[
                  const SizedBox(height: QSpace.s1),
                  Text(
                    l10n.vsPrevious(trend),
                    style: QType.caption.copyWith(
                      color: trend == 'up' ? q.ok : q.ink2,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  static int _levelOf(double completion) => completion == 0
      ? 0
      : completion < 0.25
      ? 1
      : completion < 0.5
      ? 2
      : completion < 0.75
      ? 3
      : 4;

  static List<List<int>> _heatmapWeeks(List<DayCompletion> days) {
    if (days.isEmpty) {
      return const [];
    }
    final levels = <int>[
      for (var i = 0; i < days.first.date.weekday % 7; i++) -1,
      for (final d in days) _levelOf(d.completion),
    ];
    while (levels.length % 7 != 0) {
      levels.add(-1);
    }
    return [
      for (var w = 0; w < levels.length ~/ 7; w++)
        levels.sublist(w * 7, w * 7 + 7),
    ];
  }

  Widget _heatmapCard(BuildContext context, PeriodStats stats) {
    final l10n = context.l10n;
    final q = context.q;
    return QCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            reverse: true,
            child: QHeatmap(
              weeks: _heatmapWeeks(stats.days),
              semanticLabel:
                  '${l10n.overallCompletion}: ${_percent(context, stats.completion)}',
            ),
          ),
          const SizedBox(height: QSpace.s3),
          Row(
            children: [
              Text(l10n.notYet, style: QType.caption.copyWith(color: q.ink2)),
              const SizedBox(width: QSpace.s2),
              for (var level = 0; level <= 4; level++) ...[
                if (level > 0) const SizedBox(width: 3.5),
                QHeatmapCell(level: level),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _itemBarsCard(BuildContext context, PeriodStats stats) {
    final l10n = context.l10n;
    final q = context.q;
    final byId = {for (final i in _store.items.value) i.id: i};
    final rows = [
      for (final it in stats.items)
        if (byId[it.itemId] case final item?) (item, it),
    ];
    return QCard(
      child: Column(
        children: [
          for (final (i, (item, it)) in rows.indexed) ...[
            if (i > 0) const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _nameOf(l10n, item),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: QType.caption.copyWith(fontSize: 12.5, color: q.ink),
                  ),
                ),
                const SizedBox(width: QSpace.s3),
                Expanded(
                  flex: 2,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: Container(
                      height: 6,
                      color: q.surface2,
                      child: FractionallySizedBox(
                        alignment: AlignmentDirectional.centerStart,
                        widthFactor: it.completion,
                        child: ColoredBox(
                          color: TrackerVisuals.colorOf(q, item.colorIndex),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: QSpace.s3),
                Text(
                  _percent(context, it.completion),
                  style: QType.num_(QType.caption).copyWith(color: q.ink2),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
