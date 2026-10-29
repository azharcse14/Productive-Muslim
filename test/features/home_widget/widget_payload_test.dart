import 'package:flutter_test/flutter_test.dart';
import 'package:productive_muslim/features/home_widget/domain/widget_payload.dart';
import 'package:productive_muslim/features/prayer_times/domain/entities/prayer_day.dart';
import 'package:productive_muslim/features/settings/domain/entities/prayer_params.dart';

PrayerDay _day(DateTime d) => PrayerDay(
  fajr: DateTime(d.year, d.month, d.day, 4, 30),
  sunrise: DateTime(d.year, d.month, d.day, 5, 50),
  dhuhr: DateTime(d.year, d.month, d.day, 12, 10),
  asr: DateTime(d.year, d.month, d.day, 15, 40),
  maghrib: DateTime(d.year, d.month, d.day, 18, 25),
  isha: DateTime(d.year, d.month, d.day, 19, 45),
  fajrTomorrow: DateTime(d.year, d.month, d.day + 1, 4, 31),
  ishaYesterday: DateTime(d.year, d.month, d.day - 1, 19, 44),
);

/// [count] consecutive days from [from] (calendar steps, DST-safe).
List<PrayerDay> _days(DateTime from, int count) => [
  for (var i = 0; i < count; i++)
    _day(DateTime(from.year, from.month, from.day + i)),
];

String _name(Prayer p, DateTime _) => p.name;
String _fmt(DateTime t) => '${t.hour}:${t.minute.toString().padLeft(2, '0')}';

WidgetPayload _build(
  List<PrayerDay> days, {
  DateTime Function(DateTime)? instantOf,
}) => buildWidgetPayload(
  days: days,
  nextPrayerLabel: 'Next prayer',
  prayerName: _name,
  formatTime: _fmt,
  locationLabel: 'Dhaka, BD',
  setupAction: 'Set up',
  setupHint: 'Open the app to set your location',
  staleTitle: 'Open the app',
  staleHint: 'Prayer times need updating',
  instantOf: instantOf,
);

List<List<String>> _lines(String raw) => [
  for (final l in raw.split('\n')) l.split('\t'),
];

void main() {
  test('no location → unconfigured payload with setup texts', () {
    final payload = _build(const []);
    expect(payload['widget_configured'], '0');
    expect(payload['widget_location'], '');
    expect(payload['widget_schedule'], '');
    expect(payload['widget_strips'], '');
    expect(payload['widget_setup_action'], 'Set up');
    expect(payload['widget_setup_hint'], 'Open the app to set your location');
  });

  test('legacy keys are cleared and stale texts pushed', () {
    final payload = _build(_days(DateTime(2026, 6, 14), 7));
    for (final key in [
      'widget_prayer',
      'widget_time',
      'widget_times',
      'widget_times_next',
      'widget_day_flip',
    ]) {
      expect(payload[key], '', reason: key);
    }
    expect(payload['widget_configured'], '1');
    expect(payload['widget_label'], 'Next prayer');
    expect(payload['widget_location'], 'Dhaka, BD');
    expect(payload['widget_stale_title'], 'Open the app');
    expect(payload['widget_stale_hint'], 'Prayer times need updating');
  });

  test('7 days: every prayer start as instants, in order', () {
    final payload = _build(
      _days(DateTime(2026, 6, 14), 7),
      instantOf: (wall) => wall.add(const Duration(hours: 1)),
    );
    final lines = _lines(payload['widget_schedule']!);
    // Isha before + 5 × 7 days + the Fajr after the last day.
    expect(lines, hasLength(37));
    expect(lines.first.sublist(1), ['isha', '19:44']);
    expect(
      int.parse(lines[1][0]),
      DateTime(2026, 6, 14, 5, 30).millisecondsSinceEpoch,
    );
    expect(lines[1].sublist(1), ['fajr', '4:30']);
    expect(lines[35].sublist(1), ['isha', '19:45']);
    expect(lines.last.sublist(1), ['fajr', '4:31']);
    final millis = [for (final l in lines) int.parse(l[0])];
    expect(millis, orderedEquals([...millis]..sort()));
  });

  test('7 days: one strip per day, back to back, with all five waqts', () {
    final payload = _build(_days(DateTime(2026, 6, 14), 7));
    final strips = _lines(payload['widget_strips']!);
    expect(strips, hasLength(7));
    expect(
      int.parse(strips.first[0]),
      DateTime(2026, 6, 14).millisecondsSinceEpoch,
    );
    expect(
      int.parse(strips.last[1]),
      DateTime(2026, 6, 21).millisecondsSinceEpoch,
    );
    for (var i = 1; i < strips.length; i++) {
      expect(strips[i][0], strips[i - 1][1], reason: 'day $i starts at end');
    }
    for (final p in Prayer.values) {
      expect(strips.first[2], contains(p.name));
    }
  });

  test('DST change: day boundaries follow real instants (23h day)', () {
    // A zone at UTC+1 that springs forward to UTC+2 from Mar 29, 2026.
    DateTime instantOf(DateTime wall) {
      final offset = wall.isBefore(DateTime(2026, 3, 29, 2)) ? 1 : 2;
      return DateTime.utc(
        wall.year,
        wall.month,
        wall.day,
        wall.hour,
        wall.minute,
      ).subtract(Duration(hours: offset));
    }

    final payload = _build(
      _days(DateTime(2026, 3, 27), 7),
      instantOf: instantOf,
    );
    final strips = _lines(payload['widget_strips']!);
    Duration span(List<String> s) => Duration(
      milliseconds: int.parse(s[1]) - int.parse(s[0]),
    );
    expect(span(strips[0]), const Duration(hours: 24)); // Mar 27
    expect(span(strips[2]), const Duration(hours: 23)); // Mar 29
    expect(span(strips[3]), const Duration(hours: 24)); // Mar 30
    expect(
      int.parse(strips[3][0]),
      DateTime.utc(2026, 3, 29, 22).millisecondsSinceEpoch,
    );
    final starts = [
      for (final l in _lines(payload['widget_schedule']!)) int.parse(l[0]),
    ];
    expect(starts, orderedEquals([...starts]..sort()));
  });
}
