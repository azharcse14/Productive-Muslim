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

String _name(Prayer p, DateTime _) => p.name;
String _fmt(DateTime t) => '${t.hour}:${t.minute.toString().padLeft(2, '0')}';

void main() {
  test('no location → unconfigured payload, empty fields', () {
    final payload = buildWidgetPayload(
      day: null,
      now: DateTime(2026, 6, 14, 10),
      nextPrayerLabel: 'Next prayer',
      prayerName: _name,
      formatTime: _fmt,
      locationLabel: '',
    );
    expect(payload['widget_configured'], '0');
    expect(payload['widget_prayer'], '');
    expect(payload['widget_time'], '');
  });

  test('configured payload carries next prayer + full strip', () {
    final day = _day(DateTime(2026, 6, 14));
    final payload = buildWidgetPayload(
      day: day,
      now: DateTime(2026, 6, 14, 13),
      nextPrayerLabel: 'Next prayer',
      prayerName: _name,
      formatTime: _fmt,
      locationLabel: 'Dhaka, BD',
    );
    expect(payload['widget_configured'], '1');
    expect(payload['widget_label'], 'Next prayer');
    expect(payload['widget_prayer'], 'asr');
    expect(payload['widget_time'], '15:40');
    expect(payload['widget_location'], 'Dhaka, BD');
    // Strip lists all five waqts.
    for (final p in Prayer.values) {
      expect(payload['widget_times'], contains(p.name));
    }
  });

  test("tomorrow's strip and its midnight instant are pushed", () {
    final payload = buildWidgetPayload(
      day: _day(DateTime(2026, 6, 14)),
      tomorrow: _day(DateTime(2026, 6, 15)),
      now: DateTime(2026, 6, 14, 13),
      nextPrayerLabel: 'Next prayer',
      prayerName: _name,
      formatTime: _fmt,
      locationLabel: 'Dhaka, BD',
      instantOf: (wall) => wall.add(const Duration(hours: 1)),
    );
    expect(payload['widget_times_next'], contains('fajr'));
    expect(
      int.parse(payload['widget_day_flip']!),
      DateTime(2026, 6, 15, 1).millisecondsSinceEpoch,
    );
  });

  test('schedule lists every prayer start as instants, in order', () {
    final day = _day(DateTime(2026, 6, 14));
    final tomorrow = _day(DateTime(2026, 6, 15));
    final payload = buildWidgetPayload(
      day: day,
      tomorrow: tomorrow,
      now: DateTime(2026, 6, 14, 13),
      nextPrayerLabel: 'Next prayer',
      prayerName: _name,
      formatTime: _fmt,
      locationLabel: 'Dhaka, BD',
      instantOf: (wall) => wall.add(const Duration(hours: 1)),
    );
    final lines = payload['widget_schedule']!.split('\n');
    // Yesterday's Isha + 5 today + 5 tomorrow + next Fajr.
    expect(lines, hasLength(12));
    expect(lines.first.split('\t').sublist(1), ['isha', '19:44']);
    final first = lines[1].split('\t');
    expect(
      int.parse(first[0]),
      DateTime(2026, 6, 14, 5, 30).millisecondsSinceEpoch,
    );
    expect(first.sublist(1), ['fajr', '4:30']);
    expect(lines[6].split('\t').sublist(1), ['fajr', '4:30']);
    expect(lines.last.split('\t').sublist(1), ['fajr', '4:31']);
    final millis = [for (final l in lines) int.parse(l.split('\t')[0])];
    expect(millis, orderedEquals([...millis]..sort()));
  });
}
