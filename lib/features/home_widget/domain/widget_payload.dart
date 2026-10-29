import '../../prayer_times/domain/entities/prayer_day.dart';
import '../../settings/domain/entities/prayer_params.dart';

/// Flat string map handed to the native home-screen widget. Kept pure (no
/// plugin imports) so the formatting is unit-testable.
typedef WidgetPayload = Map<String, String>;

/// Keys earlier app versions pushed; sent empty so they don't linger. Native
/// still reads them until the first push after an upgrade.
const _legacyKeys = [
  'widget_prayer',
  'widget_time',
  'widget_times',
  'widget_times_next',
  'widget_day_flip',
];

/// Builds the widget's display strings. All localization/time formatting is
/// done here in Dart so the native side only renders ready strings. [days]
/// are consecutive civil days from today (empty until a location is
/// configured — native then shows the "not set up" state).
///
/// The native side picks what to show while the app isn't running:
///  - `widget_schedule`: one `epochMillis<TAB>name<TAB>time` line per prayer
///    start across [days] (plus the Isha before and the Fajr after), in
///    order. Native shows the first line still ahead.
///  - `widget_strips`: one `startMillis<TAB>endMillis<TAB>strip` line per
///    day — native shows the five-time strip of the day containing now.
///  - Past the last start, native shows [staleTitle] / [staleHint] ("open
///    the app") instead of stale times.
///
/// [instantOf] maps a location wall-clock time to its real instant.
WidgetPayload buildWidgetPayload({
  required List<PrayerDay> days,
  required String nextPrayerLabel,
  required String Function(Prayer prayer, DateTime at) prayerName,
  required String Function(DateTime) formatTime,
  required String locationLabel,
  String setupAction = '',
  String setupHint = '',
  String staleTitle = '',
  String staleHint = '',
  DateTime Function(DateTime wall)? instantOf,
}) {
  final toInstant = instantOf ?? (DateTime wall) => wall;
  int millis(DateTime wall) => toInstant(wall).millisecondsSinceEpoch;
  String line(Prayer prayer, DateTime at) =>
      [millis(at), prayerName(prayer, at), formatTime(at)].join('\t');
  String strip(PrayerDay d) => [
    for (final prayer in Prayer.values)
      '${prayerName(prayer, d.startOf(prayer))} ${formatTime(d.startOf(prayer))}',
  ].join('   ');
  // Dhuhr (solar noon) always falls on the day's own civil date.
  String stripLine(PrayerDay d) {
    final noon = d.dhuhr;
    return [
      millis(DateTime(noon.year, noon.month, noon.day)),
      // Calendar +1, not +24h: a DST day is 23h or 25h long.
      millis(DateTime(noon.year, noon.month, noon.day + 1)),
      strip(d),
    ].join('\t');
  }

  final schedule = days.isEmpty
      ? ''
      : [
          // Covers an after-midnight Isha from the day before.
          line(Prayer.isha, days.first.ishaYesterday),
          for (final d in days)
            for (final prayer in Prayer.values) line(prayer, d.startOf(prayer)),
          line(Prayer.fajr, days.last.fajrTomorrow),
        ].join('\n');

  return {
    for (final key in _legacyKeys) key: '',
    'widget_configured': days.isEmpty ? '0' : '1',
    'widget_label': nextPrayerLabel,
    'widget_location': days.isEmpty ? '' : locationLabel,
    'widget_schedule': schedule,
    'widget_strips': days.map(stripLine).join('\n'),
    'widget_setup_action': setupAction,
    'widget_setup_hint': setupHint,
    'widget_stale_title': staleTitle,
    'widget_stale_hint': staleHint,
  };
}
