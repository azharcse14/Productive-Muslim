import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../../core/di/locator.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/settings/settings_store.dart';
import '../../../../core/theme/productive_muslim_tokens.dart';
import '../../../../core/theme/productive_muslim_typography.dart';
import '../../../../core/utils/locale_digits.dart';
import '../../../../core/utils/wall_time.dart';
import '../../../../shared/extensions/context_ext.dart';
import '../../../../shared/widgets/q_banner.dart';
import '../../../../shared/widgets/q_button.dart';
import '../../../../shared/widgets/q_card.dart';
import '../../../../shared/widgets/q_hijri_offset.dart';
import '../../../../shared/widgets/q_list_row.dart';
import '../../../prayer_times/domain/usecases/get_prayer_day.dart';
import '../../../prayer_times/presentation/screens/home_formatting.dart'
    show formatCountdown;
import '../../../settings/domain/entities/app_settings.dart';
import '../../../settings/domain/repositories/zoned_clock.dart';
import '../../../share/domain/share_sheet.dart';
import '../../domain/repositories/fast_log.dart';
import '../../domain/usecases/ramadan_utils.dart';
import '../state/eid_announcement_store.dart';
import '../state/ramadan_store.dart';
import '../widgets/ramadan_share_card.dart';

/// Ramadan hub (design §4.x): roza counter, sahri & iftar month table,
/// zakat calculator entry, and the fitra reminder.
final class RamadanScreen extends StatefulWidget {
  const RamadanScreen({super.key});

  @override
  State<RamadanScreen> createState() => _RamadanScreenState();
}

final class _RamadanScreenState extends State<RamadanScreen> {
  late final SettingsStore _settings = locator<SettingsStore>();
  late final ZonedClock _clock = locator<ZonedClock>();
  late final EidAnnouncementStore _eid = locator<EidAnnouncementStore>();
  late final RamadanStore _store = RamadanStore(
    locator<GetPrayerDay>(),
    _settings,
    now: _wallNow,
  );

  bool _sharing = false;

  /// Renders the 4:5 progress card off-screen and hands the PNG to the OS
  /// share sheet. Fasting log and share sheet resolve on the first tap.
  Future<void> _shareProgress(BuildContext context) async {
    final rozaDay = _store.rozaDay.value;
    if (_sharing || rozaDay == null) {
      return;
    }
    _sharing = true;
    try {
      final l10n = context.l10n;
      final language = Localizations.localeOf(context).languageCode;
      final total = _store.ramadanLength.value;
      final png = await renderShareCard(
        context,
        RamadanShareCard(
          rozaDay: rozaDay,
          total: total,
          fastsLogged: _store.fastsLogged(locator<IsDayFasted>()),
          hijri: _store.hijriToday.value,
          date: _store.today.value,
        ),
      );
      final shown = await locator<ShareSheet>().shareImage(
        png,
        LocaleDigits.localize(
          l10n.ramadanShareText(l10n.rozaDayOf(rozaDay, total)),
          language,
        ),
      );
      if (!shown && context.mounted) {
        _showShareFailed(context);
      }
    } on Object catch (e) {
      debugPrint('ramadan share: card not rendered: $e');
      if (context.mounted) {
        _showShareFailed(context);
      }
    } finally {
      _sharing = false;
    }
  }

  void _showShareFailed(BuildContext context) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(context.l10n.ramadanShareFailed)));

  DateTime _wallNow() {
    final location = _settings.location.value;
    return location == null ? floatingNow() : _clock.nowAt(location);
  }

  /// Real time from wall-clock [now] to [at] at the location, so the
  /// countdown spans a DST night (and its repeated hour) right.
  Duration _left(DateTime at, DateTime now) {
    final location = _settings.location.value;
    if (location == null) {
      return at.difference(now);
    }
    DateTime instantOf(DateTime wall) => _clock.utcInstantOf(location, wall);
    return instantOf(at).difference(
      nowInstant(
        now,
        deviceUtc: DateTime.now().toUtc(),
        instantOf: instantOf,
        wallOf: (instant) => _clock.instantAt(location, instant),
      ),
    );
  }

  @override
  void dispose() {
    _store.dispose();
    super.dispose();
  }

  String _formatTime(BuildContext context, DateTime time) {
    return context.clockTime(time);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final q = context.q;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.ramadanTitle)),
      body: SafeArea(
        child: SignalBuilder(
          builder: (context) {
            final hasLocation = _settings.location.value != null;
            // The counter is pure date math; only the times need a place.
            return ListView(
              padding: const EdgeInsets.all(QSpace.s5),
              children: [
                _RozaCounterCard(
                  store: _store,
                  onShare: () => unawaited(_shareProgress(context)),
                ),
                EidAnnouncementCard(store: _store, eid: _eid),
                // Roza count and the table follow the Hijri offset.
                QHijriOffsetLink(
                  offset: _settings.hijriOffsetDays.value,
                  min: AppSettings.minHijriOffset,
                  max: AppSettings.maxHijriOffset,
                  onChanged: _settings.setHijriOffset,
                ),
                const SizedBox(height: QSpace.s2),
                if (!hasLocation)
                  QCard(
                    child: Column(
                      children: [
                        Icon(Icons.place_outlined, size: 40, color: q.ink3),
                        const SizedBox(height: QSpace.s3),
                        Text(
                          l10n.homeSetLocationBody,
                          textAlign: TextAlign.center,
                          style: QType.body.copyWith(color: q.ink2),
                        ),
                        const SizedBox(height: QSpace.s4),
                        QButton(
                          label: l10n.homeSetLocationCta,
                          icon: Icons.place_outlined,
                          onPressed: () =>
                              context.pushNamed(Routes.locationPicker.name),
                        ),
                      ],
                    ),
                  )
                else ...[
                  // Also on the eve of 1 Ramadan: from Maghrib the card
                  // counts down to the first sahri (it sizes itself to
                  // nothing before then).
                  if (_store.isRamadan.value || _store.eveMaghrib.value != null)
                    _TodayTimesCard(
                      store: _store,
                      now: _wallNow,
                      left: _left,
                      formatTime: (t) => _formatTime(context, t),
                    ),
                  _MonthTableCard(
                    store: _store,
                    formatTime: (t) => _formatTime(context, t),
                  ),
                ],
                const SizedBox(height: QSpace.s4),
                QCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: QSpace.s4,
                    vertical: QSpace.s1,
                  ),
                  child: QListRow(
                    title: l10n.zakatTitle,
                    icon: Icons.volunteer_activism_outlined,
                    trailing: Icon(Icons.chevron_right, color: q.ink3),
                    onTap: () =>
                        unawaited(context.pushNamed(Routes.zakat.name)),
                  ),
                ),
                const SizedBox(height: QSpace.s4),
                QBanner(text: l10n.fitraInfo, icon: Icons.rice_bowl_outlined),
              ],
            );
          },
        ),
      ),
    );
  }
}

final class _RozaCounterCard extends StatelessWidget {
  const _RozaCounterCard({required this.store, required this.onShare});

  final RamadanStore store;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final q = context.q;
    final language = Localizations.localeOf(context).languageCode;
    return SignalBuilder(
      builder: (context) {
        final rozaDay = store.rozaDay.value;
        final total = store.ramadanLength.value;
        if (rozaDay == null) {
          final (_, daysUntil) = store.nextRamadan.value;
          return QCard(
            child: Row(
              children: [
                Icon(Icons.nightlight_outlined, size: 22, color: q.primary),
                const SizedBox(width: QSpace.s3),
                Expanded(
                  child: Text(
                    LocaleDigits.localize(
                      l10n.daysUntilRamadan(daysUntil),
                      language,
                    ),
                    style: QType.title.copyWith(color: q.ink),
                  ),
                ),
              ],
            ),
          );
        }
        return QCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.ramadanTitle.toUpperCase(),
                style: context.text.labelSmall?.copyWith(color: q.ink2),
              ),
              const SizedBox(height: QSpace.s2),
              Text(
                LocaleDigits.localize(l10n.rozaDayOf(rozaDay, total), language),
                style: QType.num_(QType.headline).copyWith(color: q.ink),
              ),
              const SizedBox(height: QSpace.s4),
              ClipRRect(
                borderRadius: BorderRadius.circular(QRadius.full),
                child: SizedBox(
                  height: 8,
                  child: ColoredBox(
                    color: q.surface2,
                    child: FractionallySizedBox(
                      alignment: AlignmentDirectional.centerStart,
                      widthFactor: (rozaDay / total).clamp(0.0, 1.0),
                      child: ColoredBox(color: q.primary),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: QSpace.s2),
              Text(
                LocaleDigits.localize(
                  l10n.ramadanDaysLeft(
                    total - rozaDay < 0 ? 0 : total - rozaDay,
                  ),
                  language,
                ),
                style: QType.caption.copyWith(color: q.ink2),
              ),
              const SizedBox(height: QSpace.s4),
              QButton(
                label: l10n.ramadanShareProgress,
                icon: Icons.share_outlined,
                kind: QButtonKind.tonal,
                small: true,
                onPressed: onShare,
              ),
            ],
          ),
        );
      },
    );
  }
}

/// "Eid announced — Ramadan ended after 29 days" for the current Hijri
/// year, offered on 29/30 Ramadan and (to undo) on Eid itself; hidden on
/// every other day.
final class EidAnnouncementCard extends StatelessWidget {
  const EidAnnouncementCard({
    required this.store,
    required this.eid,
    super.key,
  });

  final RamadanStore store;
  final EidAnnouncementStore eid;

  Future<void> _set(BuildContext context, int year, bool ended) async {
    try {
      await eid.setEnded(year, ended: ended);
    } on Object {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.l10n.saveFailed)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final q = context.q;
    return SignalBuilder(
      builder: (context) {
        final today = store.hijriToday.value;
        final ended = eid.years.value.contains(today.year);
        if (!RamadanUtils.offersEidAnnouncement(today, ended: ended)) {
          return const SizedBox.shrink();
        }
        // Tabular 30 Ramadan: the user is likely mid-day, so ask about
        // today rather than "the 30th".
        final lastDay = today.day == 30;
        return Padding(
          padding: const EdgeInsets.only(top: QSpace.s4),
          child: QCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  context.digits(
                    ended
                        ? l10n.ramadanEidMarked
                        : lastDay
                        ? l10n.ramadanEidPromptLastDay
                        : l10n.ramadanEidPrompt,
                  ),
                  style: QType.body.copyWith(color: q.ink2),
                ),
                const SizedBox(height: QSpace.s3),
                QButton(
                  label: ended
                      ? l10n.undo
                      : lastDay
                      ? l10n.ramadanEidAnnounceToday
                      : context.digits(l10n.ramadanEidAnnounce),
                  icon: ended ? Icons.undo : Icons.celebration_outlined,
                  kind: ended ? QButtonKind.ghost : QButtonKind.tonal,
                  onPressed: () => unawaited(_set(context, today.year, !ended)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// During Ramadan: today's sahri-end and iftar, with a live countdown to
/// whichever comes next (tomorrow's sahri after iftar).
final class _TodayTimesCard extends StatefulWidget {
  const _TodayTimesCard({
    required this.store,
    required this.now,
    required this.left,
    required this.formatTime,
  });

  final RamadanStore store;
  final DateTime Function() now;
  final Duration Function(DateTime at, DateTime now) left;
  final String Function(DateTime) formatTime;

  @override
  State<_TodayTimesCard> createState() => _TodayTimesCardState();
}

final class _TodayTimesCardState extends State<_TodayTimesCard> {
  late final Timer _tick;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _tick.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final q = context.q;
    return SignalBuilder(
      builder: (context) {
        final rows = widget.store.monthRows.value;
        final today = widget.store.today.value;
        final i = rows.indexWhere((r) => r.$1 == today);
        final now = widget.now();
        final RamadanRow? next;
        final DateTime sahri, iftar;
        final (String?, DateTime?) countdown;
        if (i < 0) {
          // Eve of 1 Ramadan, after Maghrib: the first fast's times.
          next = widget.store.firstFastAfterEve(now);
          if (next == null) {
            return const SizedBox.shrink();
          }
          sahri = next.$2;
          iftar = next.$3;
          countdown = (l10n.countdownSahriEnds, sahri);
        } else {
          final (_, todaySahri, todayIftar, _) = rows[i];
          iftar = todayIftar;
          // After iftar, today's sahri is past: show tomorrow's instead.
          next = now.isBefore(iftar) ? null : widget.store.rowAfter(today);
          sahri = next?.$2 ?? todaySahri;
          countdown = now.isBefore(todaySahri)
              ? (l10n.countdownSahriEnds, todaySahri)
              : now.isBefore(iftar)
              ? (l10n.countdownIftarIn, iftar)
              : next != null
              ? (l10n.countdownSahriEnds, next.$2)
              : (null, null);
        }
        final (label, target) = countdown;
        Duration left(DateTime at) => widget.left(at, now);
        Widget time(String caption, DateTime at) => Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(caption, style: QType.caption.copyWith(color: q.ink2)),
              Text(
                widget.formatTime(at),
                style: QType.num_(QType.title).copyWith(color: q.ink),
              ),
            ],
          ),
        );
        final card = QCard(
          tone: q.primarySoft,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.todayTab.toUpperCase(),
                style: context.text.labelSmall?.copyWith(
                  color: q.onPrimarySoft,
                ),
              ),
              const SizedBox(height: QSpace.s2),
              Row(
                children: [
                  time(
                    next == null ? l10n.sahriEndsLabel : l10n.sahriEndsTomorrow,
                    sahri,
                  ),
                  time(l10n.iftarLabel, iftar),
                ],
              ),
              if (label != null && target != null) ...[
                const SizedBox(height: QSpace.s3),
                Text(
                  '$label ${formatCountdown(context, left(target))}',
                  style: QType.num_(
                    QType.titleSm,
                  ).copyWith(color: q.onPrimarySoft),
                ),
              ],
            ],
          ),
        );
        return Padding(
          padding: const EdgeInsetsDirectional.only(bottom: QSpace.s4),
          child: card,
        );
      },
    );
  }
}

final class _MonthTableCard extends StatelessWidget {
  const _MonthTableCard({required this.store, required this.formatTime});

  final RamadanStore store;
  final String Function(DateTime) formatTime;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final q = context.q;
    final locale = Localizations.localeOf(context);
    // Roza-number column grows with the text size instead of clipping.
    final dayWidth = 40 * context.textGrowth;
    return QCard(
      padding: const EdgeInsets.symmetric(
        horizontal: QSpace.s4,
        vertical: QSpace.s4,
      ),
      child: SignalBuilder(
        builder: (context) {
          final rows = store.monthRows.value;
          final today = store.today.value;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.monthTable(
                  LocaleDigits.localize(
                    '${store.nextRamadan.value.$1}',
                    locale.languageCode,
                  ),
                ),
                style: QType.titleSm.copyWith(color: q.ink),
              ),
              const SizedBox(height: QSpace.s2),
              // Same inset as the data rows, so the headers sit over them.
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: QSpace.s2),
                child: Row(
                  children: [
                    SizedBox(
                      width: dayWidth,
                      child: Text(
                        l10n.ramadanColDay,
                        style: QType.caption.copyWith(color: q.ink2),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        l10n.ramadanColDate,
                        style: QType.caption.copyWith(color: q.ink2),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        l10n.sahriEndsLabel,
                        textAlign: TextAlign.end,
                        style: QType.caption.copyWith(color: q.ink2),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        l10n.iftarLabel,
                        textAlign: TextAlign.end,
                        style: QType.caption.copyWith(color: q.ink2),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: QSpace.s2),
              if (rows.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(QSpace.s2),
                  child: Text(
                    l10n.ramadanTableEmpty,
                    style: QType.body.copyWith(color: q.ink2),
                  ),
                ),
              // Inline rows (no nested scroller), so today's highlighted row
              // is reachable with the page scroll like everything else.
              for (final (day, sahri, iftar, roza) in rows)
                Builder(
                  builder: (context) {
                    final isToday = day == today;
                    // Iftar of fasting day 20, 22, … begins odd night 21, 23, …
                    final oddNightEve = roza >= 20 && roza <= 28 && roza.isEven;
                    // Past days recede; today is highlighted.
                    final ink = isToday
                        ? q.onPrimarySoft
                        : day.isBefore(today)
                        ? q.ink3
                        : q.ink;
                    final language = locale.languageCode;
                    final a11y = [
                      l10n.ramadanRowA11y(
                        LocaleDigits.localize('$roza', language),
                        LocaleDigits.localize(
                          DateFormat.MMMMd(locale.toString()).format(day),
                          language,
                        ),
                        formatTime(sahri),
                        formatTime(iftar),
                      ),
                      if (oddNightEve)
                        l10n.oddNightBegins(
                          LocaleDigits.localize('${roza + 1}', language),
                        ),
                      if (isToday) l10n.todayTab,
                    ].join(', ');
                    return Semantics(
                      container: true,
                      label: a11y,
                      excludeSemantics: true,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: isToday ? q.primarySoft : null,
                          borderRadius: BorderRadius.circular(QRadius.sm),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: QSpace.s2,
                            vertical: QSpace.s2,
                          ),
                          child: Row(
                            children: [
                              SizedBox(
                                width: dayWidth,
                                child: Text(
                                  LocaleDigits.localize(
                                    '$roza',
                                    locale.languageCode,
                                  ),
                                  style: QType.num_(QType.label).copyWith(
                                    color: isToday ? q.onPrimarySoft : q.ink2,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  LocaleDigits.localize(
                                    DateFormat.MMMd(
                                      locale.toString(),
                                    ).format(day),
                                    locale.languageCode,
                                  ),
                                  style: QType.body.copyWith(color: ink),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  formatTime(sahri),
                                  textAlign: TextAlign.end,
                                  style: QType.num_(
                                    QType.body,
                                  ).copyWith(color: ink),
                                ),
                              ),
                              Expanded(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    if (oddNightEve) ...[
                                      Tooltip(
                                        message: l10n.oddNightBegins(
                                          LocaleDigits.localize(
                                            '${roza + 1}',
                                            locale.languageCode,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.nightlight_round,
                                          size: 14,
                                          color: q.accent,
                                        ),
                                      ),
                                      const SizedBox(width: QSpace.s1),
                                    ],
                                    Flexible(
                                      child: Text(
                                        formatTime(iftar),
                                        textAlign: TextAlign.end,
                                        style: QType.num_(
                                          QType.body,
                                        ).copyWith(color: ink),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              if (rows.length >= 28) ...[
                const SizedBox(height: QSpace.s3),
                Row(
                  children: [
                    Icon(Icons.nightlight_round, size: 14, color: q.accent),
                    const SizedBox(width: QSpace.s2),
                    Expanded(
                      child: Text(
                        l10n.laylatulQadrOddNights,
                        style: QType.caption.copyWith(color: q.ink2),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
