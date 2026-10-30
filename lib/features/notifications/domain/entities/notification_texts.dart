/// Localized notification copy, resolved from l10n by the caller and
/// passed down so the scheduler stays free of Flutter/l10n imports.
/// Templates may contain `{prayer}` and `{time}` placeholders.
/// [NotificationTexts.prayerNames] key for the Jumu'ah name.
const jumuahNameKey = 'jumuah';

final class NotificationTexts {
  const NotificationTexts({
    required this.azanTitle,
    required this.azanBody,
    required this.jamaatTitle,
    required this.jamaatBody,
    required this.sahriTitle,
    required this.sahriBody,
    required this.iftarTitle,
    required this.iftarBody,
    required this.muhasabaTitle,
    required this.muhasabaBody,
    required this.dailyReminderTitle,
    required this.dailyReminderBody,
    required this.dailyReminderRoute,
    required this.keepAliveTitle,
    required this.keepAliveBody,
    required this.markAsPrayedAction,
    required this.channelAzanName,
    required this.channelRemindersName,
    required this.channelSilentName,
    required this.channelBeepName,
    required this.prayerNames,
    this.focusTitle = '',
    this.focusBody = '',
    this.focusLockBody = '',
    this.focusLockBodyUntil = '',
    this.focusEndAction = '',
    this.channelFocusName = '',
    this.focusEndTitle = '',
    this.focusEndBody = '',
    this.nafsLockTitle = '',
    this.nafsLockBodyUntil = '',
    this.dailyAyahTitle = '',
    this.dailyAyahBody = '',
    this.dailyHadithTitle = '',
    this.dailyHadithBody = '',
  });

  final String azanTitle;
  final String azanBody;
  final String jamaatTitle;
  final String jamaatBody;
  final String sahriTitle;
  final String sahriBody;
  final String iftarTitle;
  final String iftarBody;
  final String muhasabaTitle;
  final String muhasabaBody;
  final String dailyReminderTitle;
  final String dailyReminderBody;

  /// Deep-link route for the daily reminder, e.g. '/hadith' or '/dua',
  /// chosen from the matrix's content kind by the caller.
  final String dailyReminderRoute;
  final String keepAliveTitle;
  final String keepAliveBody;
  final String markAsPrayedAction;
  final String channelAzanName;
  final String channelRemindersName;
  final String channelSilentName;
  final String channelBeepName;

  /// Jamaat focus: [focusTitle]/[focusBody] are the iOS nudge; the lock
  /// texts are Android's lock screen + ongoing notification, titled
  /// [channelFocusName]. [focusLockBodyUntil] takes `{time}` (session end).
  final String focusTitle;
  final String focusBody;
  final String focusLockBody;
  final String focusLockBodyUntil;
  final String focusEndAction;
  final String channelFocusName;

  /// Session end: "prayed in jamaat?" (`{prayer}`) + after-salah adhkar.
  final String focusEndTitle;
  final String focusEndBody;

  /// Nafs lock screen + ongoing notification; body takes `{time}`.
  final String nafsLockTitle;
  final String nafsLockBodyUntil;

  final String dailyAyahTitle;
  final String dailyAyahBody;
  final String dailyHadithTitle;
  final String dailyHadithBody;

  /// Localized prayer display names keyed by `Prayer.name`, plus
  /// [jumuahNameKey] for Friday's Dhuhr when a Jumu'ah time is set.
  final Map<String, String> prayerNames;

  static String fill(String template, {String prayer = '', String time = ''}) =>
      template.replaceAll('{prayer}', prayer).replaceAll('{time}', time);
}
