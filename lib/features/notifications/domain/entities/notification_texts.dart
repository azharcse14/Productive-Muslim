/// Localized notification copy, resolved from l10n by the caller and
/// passed down so the scheduler stays free of Flutter/l10n imports.
/// Templates may contain `{prayer}` and `{time}` placeholders.
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
    required this.markAsPrayedAction,
    required this.channelAzanName,
    required this.channelRemindersName,
    required this.channelSilentName,
    required this.prayerNames,
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
  final String markAsPrayedAction;
  final String channelAzanName;
  final String channelRemindersName;
  final String channelSilentName;

  /// Localized prayer display names keyed by `Prayer.name`.
  final Map<String, String> prayerNames;

  static String fill(
    String template, {
    String prayer = '',
    String time = '',
  }) =>
      template.replaceAll('{prayer}', prayer).replaceAll('{time}', time);
}
