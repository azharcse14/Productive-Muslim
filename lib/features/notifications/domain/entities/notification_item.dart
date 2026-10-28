import '../../../settings/domain/entities/prayer_params.dart';

/// Notification categories (design §15). Each maps to a channel and a
/// localized title/body template at schedule time.
enum NotificationKind {
  /// Waqt start. Channel depends on the matrix mode (azan/beep/silent).
  azan,

  /// Lead-time reminder before configured jamaat.
  jamaat,

  /// Warning before sahri ends (default 30 min before Fajr).
  sahriWarning,

  /// Iftar moment — celebratory tone.
  iftar,

  /// Evening muhasaba nudge — max one per day.
  muhasabaEvening,

  /// Daily content reminder ("Hadith/Dua of the day") at a user-chosen time —
  /// max one per day. Deep-links to the chosen content screen.
  dailyReminder,

  /// Low-priority nudge at the end of the planned window: the OS only
  /// holds a finite schedule, so opening the app refills it.
  keepAlive,

  /// iOS only: jamaat focus start — "put your phone on silent". The OS
  /// lets no app silence or lock the phone, so a nudge is all iOS gets.
  jamaatFocus,

  /// Jamaat focus end: "prayed in jamaat?" with "mark as prayed", and a
  /// tap opens the after-salah duas.
  focusEnd,
}

/// One planned local notification, semantic only — text is resolved
/// against l10n by the scheduler at schedule time.
final class NotificationItem {
  const NotificationItem({
    required this.kind,
    required this.at,
    this.prayer,
    this.prayerDay,
    this.silent = false,
    this.beepOnly = false,
  });

  final NotificationKind kind;

  /// Absolute wall-clock moment at the configured location.
  final DateTime at;

  /// Set for azan/jamaat items.
  final Prayer? prayer;

  /// Azan only: the prayer day (date of its fajr) [at] belongs to — differs
  /// from [at]'s date when isha falls after midnight (high latitudes).
  final DateTime? prayerDay;

  /// Matrix mode [AzanMode.silent]: show without sound.
  final bool silent;

  /// Matrix mode [AzanMode.beep]: short tone instead of azan audio.
  final bool beepOnly;

  /// Deterministic id so rescheduling replaces rather than duplicates:
  /// derived from kind, prayer, and the minute it fires. Plain arithmetic,
  /// not Object.hash (seeded per run), and kept within 31 bits: the minute
  /// wraps every ~85 years, far beyond any planned window.
  int get id {
    final minute =
        DateTime.utc(
          at.year,
          at.month,
          at.day,
          at.hour,
          at.minute,
        ).millisecondsSinceEpoch ~/
        Duration.millisecondsPerMinute;
    // kind × prayer slot (< 6): sized from the enum so a new kind can't
    // spill into the next minute's ids.
    final perMinute = NotificationKind.values.length * 6;
    final slot = kind.index * 6 + (prayer?.index ?? -1) + 1;
    return (minute % (0x7FFFFFFF ~/ perMinute)) * perMinute + slot;
  }

  @override
  bool operator ==(Object other) =>
      other is NotificationItem &&
      other.kind == kind &&
      other.at == at &&
      other.prayer == prayer &&
      other.silent == silent &&
      other.beepOnly == beepOnly;

  @override
  int get hashCode => Object.hash(kind, at, prayer, silent, beepOnly);
}
