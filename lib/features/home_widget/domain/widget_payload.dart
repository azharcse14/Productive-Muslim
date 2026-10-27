import '../../prayer_times/domain/entities/prayer_day.dart';
import '../../settings/domain/entities/prayer_params.dart';
import 'next_prayer.dart';

/// Flat string map handed to the native home-screen widget. Kept pure (no
/// plugin imports) so the formatting is unit-testable. The widget reads
/// these keys from shared storage via the `home_widget` plugin.
typedef WidgetPayload = Map<String, String>;

/// Builds the widget's display strings. All localization/time formatting is
/// done here in Dart so the native side only renders ready strings — no
/// platform l10n needed. [day] is null until a location is configured.
///
/// `widget_schedule` lets the native side pick the next prayer itself while
/// the app isn't running: one `epochMillis<TAB>name<TAB>time` line per
/// prayer start for [day] and [tomorrow] (then tomorrow's next Fajr), in
/// order. [instantOf] maps a location wall-clock time to its real instant.
/// ponytail: `widget_times` (the five-time strip) stays as of the last app
/// run, so after midnight it shows yesterday's times until the app runs;
/// add a per-day strip to the schedule lines if that matters.
WidgetPayload buildWidgetPayload({
  required PrayerDay? day,
  required DateTime now,
  required String nextPrayerLabel,
  required String Function(Prayer) prayerName,
  required String Function(DateTime) formatTime,
  required String locationLabel,
  PrayerDay? tomorrow,
  DateTime Function(DateTime wall)? instantOf,
}) {
  if (day == null) {
    return {
      'widget_configured': '0',
      'widget_label': nextPrayerLabel,
      'widget_prayer': '',
      'widget_time': '',
      'widget_location': '',
      'widget_times': '',
      'widget_schedule': '',
    };
  }
  final toInstant = instantOf ?? (DateTime wall) => wall;
  String line(Prayer prayer, DateTime at) => [
    toInstant(at).millisecondsSinceEpoch,
    prayerName(prayer),
    formatTime(at),
  ].join('\t');
  final schedule = [
    for (final d in [day, ?tomorrow])
      for (final prayer in Prayer.values) line(prayer, d.startOf(prayer)),
    line(Prayer.fajr, (tomorrow ?? day).fajrTomorrow),
  ].join('\n');
  final next = resolveNextPrayer(day, now);
  final strip = [
    for (final prayer in Prayer.values)
      '${prayerName(prayer)} ${formatTime(day.startOf(prayer))}',
  ].join('   ');
  return {
    'widget_configured': '1',
    'widget_label': nextPrayerLabel,
    'widget_prayer': prayerName(next.prayer),
    'widget_time': formatTime(next.at),
    'widget_location': locationLabel,
    'widget_times': strip,
    'widget_schedule': schedule,
  };
}
