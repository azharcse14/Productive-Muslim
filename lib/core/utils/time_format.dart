import 'package:intl/intl.dart';

import 'locale_digits.dart';

/// One formatter per (locale, clock): Home formats countdown labels every
/// second.
final _formatters = <String, DateFormat>{};

/// Wall-clock time of [time] for [locale] (an intl tag such as `en_US` or
/// `bn`): "7:15 PM" on a 12-hour clock, "19:15" when [use24h], with digits in
/// the locale's digit set. Callers pass the device setting:
/// `MediaQuery.alwaysUse24HourFormatOf(context)` in widgets (see
/// `context.clockTime`), `PlatformDispatcher.instance.alwaysUse24HourFormat`
/// without a context.
String formatClockTime(
  DateTime time, {
  required String locale,
  required bool use24h,
}) {
  final format = _formatters['$locale|$use24h'] ??= use24h
      ? DateFormat.Hm(locale)
      : DateFormat.jm(locale);
  return LocaleDigits.localize(
    format.format(time),
    locale.split(RegExp('[_-]')).first,
  );
}
