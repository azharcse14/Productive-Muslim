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

String _name(Prayer p) => p.name;
String _fmt(DateTime t) =>
    '${t.hour}:${t.minute.toString().padLeft(2, '0')}';

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
}
