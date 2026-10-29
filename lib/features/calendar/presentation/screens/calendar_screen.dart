import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../../core/di/locator.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/productive_muslim_tokens.dart';
import '../../../../core/theme/productive_muslim_typography.dart';
import '../../../../core/utils/bangla_date.dart';
import '../../../../core/utils/hijri_date.dart';
import '../../../../core/utils/islamic_dates.dart';
import '../../../../core/utils/locale_digits.dart';
import '../../../../shared/extensions/context_ext.dart';
import '../../../prayer_times/domain/entities/prayer_day.dart';
import '../../../prayer_times/domain/usecases/get_prayer_day.dart';
import '../../../settings/domain/entities/prayer_params.dart';
import '../../../settings/domain/repositories/zoned_clock.dart';
import '../../../settings/presentation/state/settings_store.dart';
import '../../../settings/presentation/widgets/setting_labels.dart';

/// Combined Gregorian / hijri / Bangla month calendar (design §4.x):
/// month grid with hijri captions and Islamic-event dots, a per-day
/// detail sheet (all three dates + prayer times), and an event legend.
final class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

final class _CalendarScreenState extends State<CalendarScreen> {
  late final SettingsStore _settings = locator<SettingsStore>();
  late final GetPrayerDay _getPrayerDay = locator<GetPrayerDay>();
  late final ZonedClock _clock = locator<ZonedClock>();

  late DateTime _month = DateTime(_today.year, _today.month);

  /// User's moon-sighting adjustment, applied to every Hijri conversion.
  int get _offset => _settings.hijriOffsetDays.value;

  DateTime get _today {
    final location = _settings.location.value;
    final now = location == null ? DateTime.now() : _clock.nowAt(location);
    return DateTime(now.year, now.month, now.day);
  }

  void _shiftMonth(int delta) {
    setState(() {
      _month = DateTime(_month.year, _month.month + delta);
    });
  }

  String _digits(BuildContext context, String text) =>
      LocaleDigits.localize(text, Localizations.localeOf(context).languageCode);

  /// Hijri month-year span of the displayed Gregorian month, e.g.
  /// "Dhul-Qadah – Dhul-Hijjah 1447".
  String _hijriRange(BuildContext context) {
    final l10n = context.l10n;
    final first = HijriDate.fromGregorian(_month, offsetDays: _offset);
    final last = HijriDate.fromGregorian(
      DateTime(_month.year, _month.month + 1, 0),
      offsetDays: _offset,
    );
    final from = l10n.hijriMonthName('m${first.month}');
    final to = l10n.hijriMonthName('m${last.month}');
    final label = first.month == last.month && first.year == last.year
        ? '$from ${first.year}'
        : first.year == last.year
        ? '$from – $to ${first.year}'
        : '$from ${first.year} – $to ${last.year}';
    return _digits(context, label);
  }

  void _openDaySheet(BuildContext context, DateTime day) {
    final location = _settings.location.value;
    final prayerDay = location == null
        ? null
        : _getPrayerDay(
            location: location,
            params: _settings.prayerParams.value,
            date: day,
          ).valueOrNull;
    unawaited(
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (sheetContext) =>
            _DaySheet(day: day, prayerDay: prayerDay, offsetDays: _offset),
      ),
    );
  }

  // Hijri offset and location (today) are signals: rebuild when they change.
  @override
  Widget build(BuildContext context) => SignalBuilder(builder: _build);

  Widget _build(BuildContext context) {
    final l10n = context.l10n;
    final q = context.q;
    final locale = Localizations.localeOf(context);
    final monthLabel = _digits(
      context,
      DateFormat.yMMMM(locale.toString()).format(_month),
    );
    final events = IslamicDates.inGregorianMonth(
      _month.year,
      _month.month,
      offsetDays: _offset,
    );
    final today = _today;
    final onCurrentMonth =
        _month.year == today.year && _month.month == today.month;
    final hasOddNights =
        [
          for (
            var d = 1;
            d <= DateTime(_month.year, _month.month + 1, 0).day;
            d++
          )
            DateTime(_month.year, _month.month, d),
        ].any(
          (d) => IslamicDates.isOddNightEve(
            HijriDate.fromGregorian(d, offsetDays: _offset),
          ),
        );
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.calendarTitle),
        actions: [
          if (!onCurrentMonth)
            TextButton.icon(
              icon: const Icon(Icons.today_outlined),
              label: Text(l10n.todayTab),
              onPressed: () =>
                  setState(() => _month = DateTime(today.year, today.month)),
            ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(QSpace.s5),
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  color: q.ink2,
                  tooltip: MaterialLocalizations.of(
                    context,
                  ).previousPageTooltip,
                  onPressed: () => _shiftMonth(-1),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        monthLabel,
                        textAlign: TextAlign.center,
                        style: QType.title.copyWith(color: q.ink),
                      ),
                      Text(
                        _hijriRange(context),
                        textAlign: TextAlign.center,
                        style: QType.caption.copyWith(color: q.ink2),
                      ),
                      if (_offset != 0)
                        // Tapping jumps to the setting that shifts it.
                        InkWell(
                          borderRadius: BorderRadius.circular(QRadius.sm),
                          onTap: () => context.goNamed(Routes.settings.name),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: QSpace.s1,
                            ),
                            child: Text(
                              _digits(
                                context,
                                '${l10n.hijriAdjustedBy(l10n.hijriOffsetValue(_offset.abs(), _offset > 0 ? '+' : '−'))}'
                                ' · ${l10n.hijriAdjustChange}',
                              ),
                              textAlign: TextAlign.center,
                              style: QType.caption.copyWith(color: q.primary),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  color: q.ink2,
                  tooltip: MaterialLocalizations.of(context).nextPageTooltip,
                  onPressed: () => _shiftMonth(1),
                ),
              ],
            ),
            const SizedBox(height: QSpace.s3),
            _MonthGrid(
              month: _month,
              today: _today,
              offsetDays: _offset,
              onDayTap: (day) => _openDaySheet(context, day),
            ),
            if (events.isNotEmpty) ...[
              const SizedBox(height: QSpace.s5),
              for (final (event, date) in events)
                Padding(
                  padding: const EdgeInsets.only(bottom: QSpace.s3),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: q.accent,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: QSpace.s3),
                      Expanded(
                        child: Text(
                          l10n.islamicDayName(event.name),
                          style: QType.titleSm.copyWith(color: q.ink),
                        ),
                      ),
                      Text(
                        _digits(
                          context,
                          DateFormat.MMMd(locale.toString()).format(date),
                        ),
                        style: QType.num_(QType.label).copyWith(color: q.ink2),
                      ),
                    ],
                  ),
                ),
            ] else
              const SizedBox.shrink(),
            if (hasOddNights)
              Row(
                children: [
                  const _OddNightRing(),
                  const SizedBox(width: QSpace.s3),
                  Expanded(
                    child: Text(
                      l10n.laylatulQadrOddNights,
                      style: QType.caption.copyWith(color: q.ink2),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

final class _MonthGrid extends StatelessWidget {
  const _MonthGrid({
    required this.month,
    required this.today,
    required this.offsetDays,
    required this.onDayTap,
  });

  final DateTime month;
  final DateTime today;
  final int offsetDays;
  final ValueChanged<DateTime> onDayTap;

  @override
  Widget build(BuildContext context) {
    final q = context.q;
    final material = MaterialLocalizations.of(context);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    // Locale's first weekday (0 = Sunday, as narrowWeekdays is indexed).
    final firstDay = material.firstDayOfWeekIndex;
    final leading =
        (DateTime(month.year, month.month).weekday % 7 - firstDay + 7) % 7;
    final cells = <Widget>[
      for (var i = 0; i < 7; i++)
        Center(
          child: Text(
            material.narrowWeekdays[(firstDay + i) % 7],
            style: QType.caption.copyWith(color: q.ink3),
          ),
        ),
      for (var i = 0; i < leading; i++) const SizedBox.shrink(),
      for (var day = 1; day <= daysInMonth; day++)
        _DayCell(
          key: ValueKey('calendar-day-$day'),
          date: DateTime(month.year, month.month, day),
          isToday: DateTime(month.year, month.month, day) == today,
          offsetDays: offsetDays,
          onTap: onDayTap,
        ),
    ];
    return GridView.count(
      crossAxisCount: 7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 0.82 / context.textGrowth,
      children: cells,
    );
  }
}

final class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.date,
    required this.isToday,
    required this.onTap,
    required this.offsetDays,
    super.key,
  });

  final DateTime date;
  final int offsetDays;
  final bool isToday;
  final ValueChanged<DateTime> onTap;

  @override
  Widget build(BuildContext context) {
    final q = context.q;
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context);
    final language = locale.languageCode;
    final hijri = HijriDate.fromGregorian(date, offsetDays: offsetDays);
    final event = IslamicDates.of(hijri);
    final hasEvent = event != null;
    final oddNightEve = IslamicDates.isOddNightEve(hijri);
    final label = LocaleDigits.localize(
      [
        DateFormat.yMMMMEEEEd(locale.toString()).format(date),
        '${hijri.day} ${l10n.hijriMonthName('m${hijri.month}')} ${hijri.year}',
        if (event != null) l10n.islamicDayName(event.name),
        if (oddNightEve && event == null)
          l10n.oddNightBegins('${hijri.day + 1}'),
      ].join(', '),
      language,
    );
    return Semantics(
      button: true,
      selected: isToday,
      label: label,
      excludeSemantics: true,
      onTap: () => onTap(date),
      child: InkWell(
        borderRadius: BorderRadius.circular(QRadius.sm),
        onTap: () => onTap(date),
        child: Container(
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(QRadius.sm),
            border: isToday ? Border.all(color: q.primary, width: 1.5) : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                LocaleDigits.localize('${date.day}', language),
                style: QType.num_(QType.label).copyWith(color: q.ink),
              ),
              Text(
                LocaleDigits.localize('${hijri.day}', language),
                style: QType.caption.copyWith(color: q.ink3),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: hasEvent
                    ? Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: q.accent,
                          shape: BoxShape.circle,
                        ),
                      )
                    : oddNightEve
                    ? const _OddNightRing()
                    : const SizedBox(height: 7),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final class _DaySheet extends StatelessWidget {
  const _DaySheet({
    required this.day,
    required this.prayerDay,
    required this.offsetDays,
  });

  final DateTime day;
  final int offsetDays;
  final PrayerDay? prayerDay;

  String _digits(BuildContext context, String text) =>
      LocaleDigits.localize(text, Localizations.localeOf(context).languageCode);

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
    final locale = Localizations.localeOf(context);
    final hijri = HijriDate.fromGregorian(day, offsetDays: offsetDays);
    final bangla = BanglaDate.fromGregorian(day);
    final event = IslamicDates.of(hijri);
    final oddNightEve = IslamicDates.isOddNightEve(hijri);
    final localPrayerDay = prayerDay;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          QSpace.s5,
          QSpace.s5,
          QSpace.s5,
          QSpace.s4,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _digits(
                context,
                DateFormat.yMMMEd(locale.toString()).format(day),
              ),
              style: QType.title.copyWith(color: q.ink),
            ),
            const SizedBox(height: QSpace.s1),
            Text(
              _digits(
                context,
                '${hijri.day} ${l10n.hijriMonthName('m${hijri.month}')} '
                '${hijri.year}',
              ),
              style: QType.body.copyWith(color: q.ink2),
            ),
            if (locale.languageCode == 'bn')
              Text(
                _digits(
                  context,
                  '${bangla.day} ${l10n.banglaMonthName('m${bangla.month}')} '
                  '${bangla.year}',
                ),
                style: QType.body.copyWith(color: q.ink2),
              ),
            if (event != null) ...[
              const SizedBox(height: QSpace.s3),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: q.accent,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: QSpace.s2),
                  Text(
                    l10n.islamicDayName(event.name),
                    style: QType.titleSm.copyWith(color: q.accentStrong),
                  ),
                ],
              ),
            ],
            if (oddNightEve && event == null) ...[
              const SizedBox(height: QSpace.s3),
              Row(
                children: [
                  const _OddNightRing(),
                  const SizedBox(width: QSpace.s2),
                  Expanded(
                    child: Text(
                      _digits(context, l10n.oddNightBegins('${hijri.day + 1}')),
                      style: QType.body.copyWith(color: q.ink2),
                    ),
                  ),
                ],
              ),
            ],
            if (localPrayerDay != null) ...[
              const SizedBox(height: QSpace.s4),
              for (final prayer in Prayer.values)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: QSpace.s1),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.prayerLabel(prayer),
                          style: QType.body.copyWith(color: q.ink),
                        ),
                      ),
                      Text(
                        _formatTime(context, localPrayerDay.startOf(prayer)),
                        style: QType.num_(QType.body).copyWith(color: q.ink),
                      ),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Hollow accent ring marking a day whose evening begins an odd night of
/// Ramadan's last ten (distinct from the solid event dot).
final class _OddNightRing extends StatelessWidget {
  const _OddNightRing();

  @override
  Widget build(BuildContext context) => Container(
    width: 7,
    height: 7,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      border: Border.all(color: context.q.accent, width: 1.5),
    ),
  );
}
