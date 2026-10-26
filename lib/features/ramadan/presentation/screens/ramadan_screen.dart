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
import '../../../settings/domain/repositories/zoned_clock.dart';
import '../../../settings/presentation/state/settings_store.dart';
import '../state/ramadan_store.dart';
import 'zakat_screen.dart';

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
        child: SignalBuilder(builder: (context) {
          if (_settings.location.value == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(QSpace.s8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.place_outlined, size: 56, color: q.ink3),
                    const SizedBox(height: QSpace.s4),
                    Text(
                      l10n.qiblaNeedsLocation,
                      textAlign: TextAlign.center,
                      style: QType.body.copyWith(color: q.ink2),
                    ),
                    const SizedBox(height: QSpace.s6),
                    QButton(
                      label: l10n.homeSetLocationCta,
                      icon: Icons.place_outlined,
                      onPressed: () =>
                          context.pushNamed(Routes.locationPicker.name),
                    ),
                  ],
                ),
              ),
            );
          }
          return ListView(
            padding: const EdgeInsets.all(QSpace.s5),
            children: [
              _RozaCounterCard(store: _store),
              const SizedBox(height: QSpace.s4),
              _MonthTableCard(
                store: _store,
                formatTime: (t) => _formatTime(context, t),
              ),
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
                  onTap: () => unawaited(
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const ZakatScreen(),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: QSpace.s4),
              QBanner(
                text: l10n.fitraInfo,
                icon: Icons.rice_bowl_outlined,
              ),
            ],
          );
        }),
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
    return SignalBuilder(builder: (context) {
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
    });
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
      child: SignalBuilder(builder: (context) {
        final rows = store.monthRows.value;
        final today = store.today.value;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.monthTable,
              style: QType.titleSm.copyWith(color: q.ink),
            ),
            const SizedBox(height: QSpace.s2),
            Row(
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
            const SizedBox(height: QSpace.s2),
            SizedBox(
              height: 320,
              child: ListView.builder(
                itemCount: rows.length,
                itemBuilder: (context, index) {
                  final (day, sahri, iftar) = rows[index];
                  final isToday = day == today;
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
                                color:
                                    isToday ? q.onPrimarySoft : q.ink2,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              LocaleDigits.localize(
                                DateFormat.MMMd(locale.toString())
                                    .format(day),
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
                            child: Text(
                              formatTime(iftar),
                              textAlign: TextAlign.end,
                              style: QType.num_(QType.body).copyWith(
                                color: isToday ? q.onPrimarySoft : q.ink,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      }),
    );
  }
}
