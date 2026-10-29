import '../../prayer_times/domain/entities/prayer_day.dart';
import '../../settings/domain/entities/prayer_params.dart';
import 'next_prayer.dart';

/// Flat string map handed to the native home-screen widget. Kept pure (no
/// plugin imports) so the formatting is unit-testable. The widget reads
/// these keys from shared storage via the `home_widget` plugin.
typedef WidgetPayload = Map<String, String>;

/// Builds the widget's display strings. All localization/time formatting is
/// done here in Dart so the native side only renders ready strings — no
/// platform l10n needed. [day] is null until a location is configured;
/// [setupHint] is then shown by the native "not set up" state.
///
/// `widget_schedule` lets the native side pick the next prayer itself while
/// the app isn't running: one `epochMillis<TAB>name<TAB>time` line per
/// prayer start for [day] and [tomorrow] (then tomorrow's next Fajr), in
/// order. [instantOf] maps a location wall-clock time to its real instant.
/// `widget_times_next` is [tomorrow]'s five-time strip and `widget_day_flip`
/// the instant (epoch millis) its date begins, so the native side swaps
/// strips at midnight without the app.
WidgetPayload buildWidgetPayload({
  required PrayerDay? day,
  required DateTime now,
  required String nextPrayerLabel,
  required String Function(Prayer prayer, DateTime at) prayerName,
  required String Function(DateTime) formatTime,
  required String locationLabel,
  String setupHint = '',
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
      'widget_times_next': '',
      'widget_day_flip': '',
      'widget_setup_hint': setupHint,
    };
  }
  final toInstant = instantOf ?? (DateTime wall) => wall;
  String line(Prayer prayer, DateTime at) => [
    toInstant(at).millisecondsSinceEpoch,
    prayerName(prayer, at),
    formatTime(at),
  ].join('\t');
  final schedule = [
    // Native picks the first line still ahead: covers an after-midnight Isha.
    line(Prayer.isha, day.ishaYesterday),
    for (final d in [day, ?tomorrow])
      for (final prayer in Prayer.values) line(prayer, d.startOf(prayer)),
    line(Prayer.fajr, (tomorrow ?? day).fajrTomorrow),
  ].join('\n');
  final next = resolveNextPrayer(day, now);
  String strip(PrayerDay d) => [
    for (final prayer in Prayer.values)
      '${prayerName(prayer, d.startOf(prayer))} ${formatTime(d.startOf(prayer))}',
  ].join('   ');
  return {
    'widget_configured': '1',
    'widget_label': nextPrayerLabel,
    'widget_prayer': prayerName(next.prayer, next.at),
    'widget_time': formatTime(next.at),
    'widget_location': locationLabel,
    'widget_times': strip(day),
    'widget_schedule': schedule,
    'widget_times_next': tomorrow == null ? '' : strip(tomorrow),
    'widget_day_flip': tomorrow == null
        ? ''
        : '${toInstant(DateTime(tomorrow.fajr.year, tomorrow.fajr.month, tomorrow.fajr.day)).millisecondsSinceEpoch}',
  };
}
