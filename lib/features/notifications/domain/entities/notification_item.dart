import '../../../settings/domain/entities/prayer_params.dart';

/// Notification categories (design §15). Each maps to a channel and a
/// localized title/body template at schedule time.
enum NotificationKind {
  /// Waqt start. Channel depends on the matrix mode (azan/beep/silent).
  azan(0),

  /// Lead-time reminder before configured jamaat.
  jamaat(1),

  /// Warning before sahri ends (default 30 min before Fajr).
  sahriWarning(2),

  /// Iftar moment — celebratory tone.
  iftar(3),

  /// Evening muhasaba nudge — max one per day.
  muhasabaEvening(4),

  /// Daily content reminder ("Hadith/Dua of the day") at a user-chosen time —
  /// max one per day. Deep-links to the chosen content screen.
  dailyReminder(5),

  /// Low-priority nudge at the end of the planned window: the OS only
  /// holds a finite schedule, so opening the app refills it.
  keepAlive(6),

  /// iOS only: jamaat focus start — "put your phone on silent". The OS
  /// lets no app silence or lock the phone, so a nudge is all iOS gets.
  jamaatFocus(7),

  /// Jamaat focus end: "prayed in jamaat?" with "mark as prayed", and a
  /// tap opens the after-salah duas.
  focusEnd(8),

  /// Daily morning Quran Ayah reminder.
  dailyAyah(9),

  /// Daily evening Hadith reminder.
  dailyHadith(10);

  const NotificationKind(this.code);

  /// Stable code for notification ids (the OS keeps pending ids across app
  /// updates): never reuse or renumber; must stay below [kindCapacity].
  final int code;

  /// Room for kinds in the id layout; raising it changes every id.
  static const kindCapacity = 16;
}

/// One planned local notification, semantic only — text is resolved
/// against l10n by the scheduler at schedule time.
final class NotificationItem {
  const NotificationItem({
    required this.kind,
    required this.at,
    this.prayer,
    this.prayerDay,
    this.eventAt,
    this.silent = false,
    this.beepOnly = false,
    this.jumuah = false,
  });

  final NotificationKind kind;

  /// Absolute wall-clock moment at the configured location.
  final DateTime at;

  /// Set for azan/jamaat items.
  final Prayer? prayer;

  /// Azan only: the prayer day (date of its fajr) [at] belongs to — differs
  /// from [at]'s date when isha falls after midnight (high latitudes).
  final DateTime? prayerDay;

  /// Jamaat/sahri reminders: the moment the text announces (the jamaat,
  /// sahri end), which [at] precedes by the lead time. Null = [at].
  final DateTime? eventAt;

  /// Matrix mode [AzanMode.silent]: show without sound.
  final bool silent;

  /// Matrix mode [AzanMode.beep]: short tone instead of azan audio.
  final bool beepOnly;

  /// Friday's Dhuhr with a Jumu'ah time set: the text names Jumu'ah.
  final bool jumuah;

  /// Deterministic id so rescheduling replaces rather than duplicates:
  /// derived from kind, prayer, and the minute it fires. Plain arithmetic,
  /// not Object.hash (seeded per run), and kept within 31 bits: the minute
  /// counter wraps every ~42.5 years (next in 2055). Harmless: a wrap only
  /// collides ids ~42 years apart, far beyond any planned window.
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
    // kind × prayer slot (< 6), from stable codes (never `.index`): a new
    // or reordered enum value can't shift the ids of pending notifications.
    const perMinute = NotificationKind.kindCapacity * 6;
    final slot = kind.code * 6 + _prayerSlot(prayer);
    return (minute % (0x7FFFFFFF ~/ perMinute)) * perMinute + slot;
  }

  static int _prayerSlot(Prayer? prayer) => switch (prayer) {
    null => 0,
    Prayer.fajr => 1,
    Prayer.dhuhr => 2,
    Prayer.asr => 3,
    Prayer.maghrib => 4,
    Prayer.isha => 5,
  };

  @override
  bool operator ==(Object other) =>
      other is NotificationItem &&
      other.kind == kind &&
      other.at == at &&
      other.prayer == prayer &&
      other.eventAt == eventAt &&
      other.silent == silent &&
      other.beepOnly == beepOnly &&
      other.jumuah == jumuah;

  @override
  int get hashCode =>
      Object.hash(kind, at, prayer, eventAt, silent, beepOnly, jumuah);
}
