import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:productive_muslim/core/utils/time_format.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('en');
    await initializeDateFormatting('bn');
  });

  final evening = DateTime(2026, 3, 1, 19, 5);

  test('12-hour clock by default', () {
    expect(
      formatClockTime(evening, locale: 'en', use24h: false),
      matches(RegExp(r'^7:05\sPM$')),
    );
  });

  test('24-hour clock when the device asks for it', () {
    expect(formatClockTime(evening, locale: 'en', use24h: true), '19:05');
    expect(formatClockTime(evening, locale: 'en_US', use24h: true), '19:05');
  });

  test('digits follow the locale', () {
    expect(formatClockTime(evening, locale: 'bn', use24h: true), '১৯:০৫');
    expect(
      formatClockTime(evening, locale: 'bn', use24h: false),
      contains('৭:০৫'),
    );
  });
}
