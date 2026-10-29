import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../../core/di/locator.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/productive_muslim_tokens.dart';
import '../../../../core/theme/productive_muslim_typography.dart';
import '../../../../core/utils/locale_digits.dart';
import '../../../../shared/extensions/context_ext.dart';
import '../../../../shared/widgets/q_banner.dart';
import '../../../../shared/widgets/q_button.dart';
import '../../../../shared/widgets/q_card.dart';
import '../../../../shared/widgets/q_list_row.dart';
import '../../../prayer_times/domain/usecases/get_prayer_day.dart';
import '../../../prayer_times/presentation/screens/home_formatting.dart'
    show formatCountdown;
import '../../../settings/domain/repositories/zoned_clock.dart';
import '../../../settings/presentation/state/settings_store.dart';
import '../state/ramadan_store.dart';

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
  late final RamadanStore _store = RamadanStore(
    locator<GetPrayerDay>(),
    _settings,
    now: _wallNow,
  );

  DateTime _wallNow() {
    final location = _settings.location.value;
    return location == null ? DateTime.now() : _clock.nowAt(location);
  }

  @override
  void dispose() {
    _store.dispose();
    super.dispose();
  }

  String _formatTime(BuildContext context, DateTime time) {
    final locale = Localizations.localeOf(context);
    return LocaleDigits.localize(
      DateFormat.jm(locale.toString()).format(time),
      locale.languageCode,
    );
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
                _RozaCounterCard(store: _store),
                const SizedBox(height: QSpace.s4),
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
                  if (_store.isRamadan.value) ...[
                    _TodayTimesCard(
                      store: _store,
                      now: _wallNow,
                      formatTime: (t) => _formatTime(context, t),
                    ),
                    const SizedBox(height: QSpace.s4),
                  ],
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
  const _RozaCounterCard({required this.store});

  final RamadanStore store;

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
                style: QType.overline.copyWith(color: q.ink2),
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
            ],
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
    required this.formatTime,
  });

  final RamadanStore store;
  final DateTime Function() now;
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
        if (i < 0) {
          return const SizedBox.shrink();
        }
        final (_, sahri, iftar) = rows[i];
        final now = widget.now();
        final (label, target) = now.isBefore(sahri)
            ? (l10n.countdownSahriEnds, sahri)
            : now.isBefore(iftar)
            ? (l10n.countdownIftarIn, iftar)
            : i + 1 < rows.length
            ? (l10n.countdownSahriEnds, rows[i + 1].$2)
            : (null, null);
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
        return QCard(
          tone: q.primarySoft,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.todayTab.toUpperCase(),
                style: QType.overline.copyWith(color: q.onPrimarySoft),
              ),
              const SizedBox(height: QSpace.s2),
              Row(
                children: [
                  time(l10n.sahriEndsLabel, sahri),
                  time(l10n.iftarLabel, iftar),
                ],
              ),
              if (label != null && target != null) ...[
                const SizedBox(height: QSpace.s3),
                Text(
                  '$label ${formatCountdown(context, target.difference(now))}',
                  style: QType.num_(
                    QType.titleSm,
                  ).copyWith(color: q.onPrimarySoft),
                ),
              ],
            ],
          ),
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
                    const SizedBox(width: 32),
                    const Expanded(child: SizedBox.shrink()),
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
              // Inline rows (no nested scroller), so today's highlighted row
              // is reachable with the page scroll like everything else.
              for (final (index, (day, sahri, iftar)) in rows.indexed)
                Builder(
                  builder: (context) {
                    final isToday = day == today;
                    // Iftar of fasting day 20, 22, … begins odd night 21, 23, …
                    final oddNightEve =
                        index + 1 >= 20 &&
                        index + 1 <= 28 &&
                        (index + 1).isEven;
                    return DecoratedBox(
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
                              width: 32,
                              child: Text(
                                LocaleDigits.localize(
                                  '${index + 1}',
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
                                style: QType.body.copyWith(
                                  color: isToday ? q.onPrimarySoft : q.ink,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                formatTime(sahri),
                                textAlign: TextAlign.end,
                                style: QType.num_(QType.body).copyWith(
                                  color: isToday ? q.onPrimarySoft : q.ink,
                                ),
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
                                          '${index + 2}',
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
                                      style: QType.num_(QType.body).copyWith(
                                        color: isToday
                                            ? q.onPrimarySoft
                                            : q.ink,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
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
