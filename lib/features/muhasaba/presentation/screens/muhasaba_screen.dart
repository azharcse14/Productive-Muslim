import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:signals_flutter/signals_flutter.dart';

import '../../../../core/di/locator.dart';
import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/productive_muslim_tokens.dart';
import '../../../../core/theme/productive_muslim_typography.dart';
import '../../../../core/utils/haptics.dart';
import '../../../../core/utils/locale_digits.dart';
import '../../../../shared/extensions/context_ext.dart';
import '../../../../shared/painters/qalb_mark.dart';
import '../../../../shared/widgets/q_button.dart';
import '../../../../shared/widgets/q_card.dart';
import '../../../../shared/widgets/q_celebrate.dart';
import '../../../../shared/widgets/q_chip.dart';
import '../../../../shared/widgets/q_heatmap.dart';
import '../../../../shared/widgets/q_progress_ring.dart';
import '../../../../shared/widgets/q_seg_control.dart';
import '../../../../shared/widgets/q_skeleton.dart';
import '../../../../shared/widgets/staggered_entrance.dart';
import '../../../achievements/presentation/state/achievement_store.dart';
import '../../../achievements/presentation/widgets/achievements_summary_card.dart';
import '../../../prayer_times/presentation/state/home_store.dart';
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

  /// The Today list cascades in once per screen, not on every tab switch.
  bool _cascadePlayed = false;

  final _effects = <EffectCleanup>[];

  /// Badge ids already pending when this screen started watching; only
  /// ids beyond these get a toast. Null until achievements have loaded.
  Set<String>? _knownNewBadges;

  @override
  void initState() {
    super.initState();
    var failures = _store.saveFailures.peek();
    _effects.add(
      effect(() {
        final n = _store.saveFailures.value;
        if (n != failures) {
          failures = n;
          untracked(() => _snack(context.l10n.trackerSaveFailed));
        }
      }),
    );
    final showBadges =
        locator.isRegistered<AchievementStore>() &&
        locator.isRegistered<SettingsStore>() &&
        locator<SettingsStore>().settings.peek().showAchievements;
    if (showBadges) {
      final badges = locator<AchievementStore>();
      _effects
        // Re-evaluate badges on every check-in, whichever tab is open.
        ..add(
          effect(() {
            _store.stats.value;
            untracked(() => unawaited(badges.refresh()));
          }),
        )
        ..add(
          effect(() {
            final ids = {for (final a in badges.newlyUnlocked.value) a.id};
            if (!badges.loaded.value) {
              return;
            }
            final known = _knownNewBadges;
            _knownNewBadges = ids;
            if (known == null) {
              return;
            }
            final fresh = ids.difference(known);
            if (fresh.isNotEmpty) {
              untracked(() => _badgeToast(fresh.first));
            }
          }),
        );
    }
  }

  @override
  void dispose() {
    for (final cleanup in _effects) {
      cleanup();
    }
    super.dispose();
  }

  void _snack(String text, {SnackBarAction? action}) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(text),
          action: action,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  void _badgeToast(String id) {
    if (!mounted) {
      return;
    }
    final l10n = context.l10n;
    Haptics.medium();
    _snack(
      l10n.achievementUnlockedToast(l10n.achievementName(id)),
      action: SnackBarAction(
        label: l10n.achievementsView,
        onPressed: () => context.pushNamed(Routes.achievements.name),
      ),
    );
  }

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
            tooltip: l10n.reorderTrackers,
            icon: const Icon(Icons.swap_vert),
            onPressed: () => unawaited(_showReorder(context)),
          ),
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
                onChanged: (i) => setState(() {
                  _tab = i;
                  _cascadePlayed = true;
                }),
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
    final showWelcome = _store.firstDay.value && !_store.welcomeDismissed.value;
    final items = _store.items.value;
    final salah = [
      for (final i in items)
        if (i.id.startsWith('salah_')) i,
    ];
    // Salah whose waqt hasn't begun yet on the selected date. Home's
    // lockedPrayers flips at each waqt boundary, so the chips unlock live.
    if (locator.isRegistered<HomeStore>()) {
      locator<HomeStore>().lockedPrayers.value;
    }
    final locked = _store.lockedSalah;
    final others = [
      for (final i in items)
        if (!i.id.startsWith('salah_')) i,
    ];
    final archived = _store.archivedItems.value;
    // A horizontal fling pages the day, like the chevrons: toward the
    // reading direction's end is the next day (flipped in RTL).
    return GestureDetector(
      onHorizontalDragEnd: (details) {
        final v = details.primaryVelocity ?? 0;
        if (v.abs() < 300) {
          return;
        }
        final rtl = Directionality.of(context) == TextDirection.rtl;
        final forward = (v < 0) != rtl;
        if (!forward || _store.canGoForward) {
          Haptics.selection();
          _shiftDay(forward ? 1 : -1);
        }
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          QSpace.s5,
          QSpace.s3,
          QSpace.s5,
          QSpace.s5,
        ),
        children: staggered(limit: _cascadePlayed ? 0 : 10, [
          if (showWelcome) _welcome(context),
          _dateSwitcher(context),
          _dayComplete(context, items),
          const SizedBox(height: QSpace.s3),
          _salahCards(context, salah, locked),
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
                  onEdit: () => unawaited(
                    showItemEditor(context, _store, existing: item),
                  ),
                ),
              ),
              const SizedBox(height: QSpace.s3),
            ],
          ],
        ]),
      ),
    );
  }

  static const _waqtIcons = <String, IconData>{
    'salah_fajr': Icons.wb_twilight_outlined,
    'salah_dhuhr': Icons.wb_sunny_outlined,
    'salah_asr': Icons.wb_cloudy_outlined,
    'salah_maghrib': Icons.nights_stay_outlined,
    'salah_isha': Icons.bedtime_outlined,
  };

  void _shiftDay(int days) {
    final d = _store.selectedDate.value;
    unawaited(_store.selectDate(DateTime(d.year, d.month, d.day + days)));
  }

  Widget _salahCards(
    BuildContext context,
    List<TrackerItem> salah,
    Set<String> locked,
  ) {
    final l10n = context.l10n;
    final q = context.q;
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final cardWidth = ((availableWidth - 24) / 5).clamp(58.0, 80.0);

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final (index, item) in salah.indexed) ...[
                if (index > 0) const SizedBox(width: 6),
                Builder(
                  builder: (context) {
                    final isLocked = locked.contains(item.id);
                    final completed = _store.valueOf(item.id) > 0;
                    // Short waqt name ("Fajr", not "Fajr prayer").
                    final name = switch (item.id) {
                      'salah_fajr' => l10n.prayerFajr,
                      'salah_dhuhr' => l10n.prayerDhuhr,
                      'salah_asr' => l10n.prayerAsr,
                      'salah_maghrib' => l10n.prayerMaghrib,
                      'salah_isha' => l10n.prayerIsha,
                      _ => _nameOf(l10n, item),
                    };

                    final cardColor = completed ? q.primary : q.surface;
                    final borderColor = completed ? q.primary : q.line;
                    final textColor = completed
                        ? q.onPrimary
                        : (isLocked ? q.ink3 : q.ink);

                    void onTap() {
                      if (isLocked) {
                        if (_store.lockedSalah.contains(item.id)) {
                          _showLockedToast(context);
                        } else {
                          unawaited(_store.setValue(item.id, 1));
                        }
                      } else {
                        unawaited(_store.setValue(item.id, completed ? 0 : 1));
                      }
                    }

                    return Semantics(
                      button: true,
                      checked: completed,
                      label: name,
                      excludeSemantics: true,
                      onTap: onTap,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: onTap,
                          borderRadius: BorderRadius.circular(QRadius.md),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: cardWidth,
                            padding: const EdgeInsets.symmetric(
                              vertical: 10,
                              horizontal: 2,
                            ),
                            decoration: BoxDecoration(
                              color: cardColor,
                              borderRadius: BorderRadius.circular(QRadius.md),
                              border: Border.all(
                                color: borderColor,
                                width: 1.2,
                              ),
                              boxShadow: [
                                if (completed)
                                  BoxShadow(
                                    color: q.primary.withValues(alpha: 0.12),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isLocked
                                      ? Icons.schedule
                                      : _waqtIcons[item.id] ??
                                            Icons.mosque_outlined,
                                  size: 22,
                                  color: completed
                                      ? q.onPrimary
                                      : (isLocked ? q.ink3 : q.primary),
                                ),
                                const SizedBox(height: 6),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    name,
                                    maxLines: 1,
                                    textAlign: TextAlign.center,
                                    style: QType.caption.copyWith(
                                      fontSize: 12,
                                      color: textColor,
                                      fontVariations: [
                                        FontVariation(
                                          'wght',
                                          completed ? 700 : 500,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  /// Honey banner with the full qalb mark once every active deed of the
  /// selected day is done. Always mounted (empty when not done) so the
  /// pulse fires on the tap that completes the day; keyed by date so
  /// paging to an already-complete day doesn't celebrate again.
  Widget _dayComplete(BuildContext context, List<TrackerItem> items) {
    final q = context.q;
    final done =
        items.isNotEmpty && items.every((i) => i.isDone(_store.valueOf(i.id)));
    return QCelebrate(
      key: ValueKey(_store.selectedDate.value),
      active: done,
      haptic: true,
      child: AnimatedSize(
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : QMotion.med,
        curve: QMotion.ease,
        child: !done
            ? const SizedBox(width: double.infinity)
            : Padding(
                padding: const EdgeInsets.only(top: QSpace.s3),
                child: QCard(
                  tone: q.accentSoft,
                  padding: const EdgeInsets.symmetric(
                    horizontal: QSpace.s4,
                    vertical: QSpace.s3,
                  ),
                  child: Row(
                    children: [
                      ExcludeSemantics(
                        child: QalbMark(
                          size: 32,
                          color: q.onAccentSoft,
                          accent: q.accent,
                        ),
                      ),
                      const SizedBox(width: QSpace.s3),
                      Expanded(
                        child: Text(
                          _store.selectedIsToday
                              ? context.l10n.muhasabaDayComplete
                              : context.l10n.muhasabaDayCompletePast,
                          style: QType.titleSm.copyWith(color: q.onAccentSoft),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  /// First-run welcome, shown above the checklist until dismissed (the
  /// dismissal is persisted) or the first deed is logged.
  Widget _welcome(BuildContext context) {
    final l10n = context.l10n;
    final q = context.q;
    return Padding(
      padding: const EdgeInsets.only(bottom: QSpace.s3),
      child: QCard(
        tone: q.primarySoft,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.favorite_outline, size: 22, color: q.onPrimarySoft),
                const SizedBox(width: QSpace.s2),
                Expanded(
                  child: Text(
                    l10n.muhasabaFirstDayTitle,
                    style: QType.titleSm.copyWith(color: q.onPrimarySoft),
                  ),
                ),
              ],
            ),
            const SizedBox(height: QSpace.s2),
            Text(
              l10n.muhasabaFirstDayBody,
              style: QType.body.copyWith(color: q.onPrimarySoft),
            ),
            const SizedBox(height: QSpace.s3),
            QButton(
              label: l10n.muhasabaStart,
              small: true,
              onPressed: () => unawaited(_store.dismissWelcome()),
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
    final l10n = context.l10n;
    return Row(
      children: [
        IconButton(
          tooltip: l10n.previousDay,
          icon: const Icon(Icons.chevron_left),
          onPressed: () => _shiftDay(-1),
        ),
        Expanded(
          child: Semantics(
            button: true,
            hint: l10n.chooseDate,
            child: InkWell(
              borderRadius: BorderRadius.circular(QRadius.md),
              onTap: () => unawaited(_pickDate(context)),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: QTouch.minTarget),
                child: Center(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: QType.titleSm.copyWith(color: q.ink),
                  ),
                ),
              ),
            ),
          ),
        ),
        if (!_store.selectedIsToday)
          QChip(
            label: l10n.todayTab,
            onTap: () => unawaited(_store.selectDate(_todayDate())),
          ),
        IconButton(
          tooltip: l10n.nextDay,
          icon: const Icon(Icons.chevron_right),
          onPressed: _store.canGoForward ? () => _shiftDay(1) : null,
        ),
      ],
    );
  }

  DateTime _todayDate() {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  Future<void> _pickDate(BuildContext context) async {
    // The store clamps to its own clock; the picker just bars the future.
    final today = _todayDate();
    final selected = _store.selectedDate.value;
    final picked = await showDatePicker(
      context: context,
      initialDate: selected.isAfter(today) ? today : selected,
      firstDate: DateTime(today.year - 5),
      lastDate: today,
      helpText: context.l10n.chooseDate,
    );
    if (picked != null) {
      await _store.selectDate(picked);
    }
  }

  Future<void> _showReorder(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _ReorderSheet(store: _store, nameOf: _nameOf),
  );

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
          for (final h in const [140.0, 64.0, 120.0]) ...[
            QSkeleton(height: h, radius: QRadius.lg),
            const SizedBox(height: QSpace.s4),
          ]
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
          // A single day has no trend and no calendar to show.
          if (stats.days.length >= 2) ...[
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
          ],
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
                  label: stats.currentStreak == 0
                      ? l10n.streakStartToday
                      : l10n.currentStreakLabel(stats.currentStreak),
                  active: stats.currentStreak > 0,
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

  /// Sunday-first padding before the first day (matches [_heatmapWeeks]).
  static int _leading(List<DayCompletion> days) =>
      days.isEmpty ? 0 : days.first.date.weekday % 7;

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
    final locale = Localizations.localeOf(context);
    final days = stats.days;
    final leading = _leading(days);
    DayCompletion? dayAt(int w, int d) {
      final i = w * 7 + d - leading;
      return i >= 0 && i < days.length ? days[i] : null;
    }

    // The range ends today, so the last cell is today's.
    final todayIndex = leading + days.length - 1;
    final complete = days.where((d) => d.completion >= 1).length;
    return QCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            reverse: true,
            child: QHeatmap(
              weeks: _heatmapWeeks(days),
              highlight: (todayIndex ~/ 7, todayIndex % 7),
              semanticLabel: l10n.heatmapDaysComplete(complete, days.length),
              cellLabel: (w, d) {
                final day = dayAt(w, d);
                if (day == null) {
                  return '';
                }
                return LocaleDigits.localize(
                  '${DateFormat.MMMEd(locale.toString()).format(day.date)}: '
                  '${_percent(context, day.completion)}',
                  locale.languageCode,
                );
              },
              // Jump to that day's checklist.
              onTap: (w, d) {
                final day = dayAt(w, d);
                if (day == null) {
                  return;
                }
                Haptics.selection();
                setState(() {
                  _tab = 0;
                  _cascadePlayed = true;
                });
                unawaited(_store.selectDate(day.date));
              },
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
            if (i > 0) const SizedBox(height: QSpace.s3),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _nameOf(l10n, item),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: QType.label.copyWith(color: q.ink),
                  ),
                ),
                const SizedBox(width: QSpace.s3),
                Expanded(
                  flex: 2,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(QRadius.full),
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

/// "Reorder items": drag the non-salah checklist into a new order (the five
/// salah stay pinned as their own row).
final class _ReorderSheet extends StatefulWidget {
  const _ReorderSheet({required this.store, required this.nameOf});

  final MuhasabaStore store;
  final String Function(AppLocalizations, TrackerItem) nameOf;

  @override
  State<_ReorderSheet> createState() => _ReorderSheetState();
}

final class _ReorderSheetState extends State<_ReorderSheet> {
  late final List<TrackerItem> _items = [
    for (final i in widget.store.items.value)
      if (!i.id.startsWith('salah_')) i,
  ];

  void _onReorder(int from, int to) {
    setState(() {
      final moved = _items.removeAt(from);
      _items.insert(to, moved);
    });
    final salah = [
      for (final i in widget.store.items.value)
        if (i.id.startsWith('salah_')) i.id,
    ];
    unawaited(widget.store.reorder([...salah, for (final i in _items) i.id]));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final q = context.q;
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.7,
        ),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.reorderTrackers,
                    style: QType.title.copyWith(color: q.ink),
                  ),
                  const SizedBox(height: QSpace.s1),
                  Text(
                    l10n.reorderTrackersHint,
                    style: QType.caption.copyWith(color: q.ink2),
                  ),
                ],
              ),
            ),
            Flexible(
              child: ReorderableListView(
                shrinkWrap: true,
                onReorderItem: _onReorder,
                children: [
                  for (final item in _items)
                    ListTile(
                      key: ValueKey(item.id),
                      leading: Icon(
                        TrackerVisuals.iconOf(item.icon),
                        color: TrackerVisuals.colorOf(q, item.colorIndex),
                      ),
                      title: Text(widget.nameOf(l10n, item)),
                      trailing: const Icon(Icons.drag_handle),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
