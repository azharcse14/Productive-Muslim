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
}

/// One planned local notification, semantic only — text is resolved
/// against l10n by the scheduler at schedule time.
final class NotificationItem {
  const NotificationItem({
    required this.kind,
    required this.at,
    this.prayer,
    this.silent = false,
    this.beepOnly = false,
  });

  final NotificationKind kind;

  /// Absolute wall-clock moment at the configured location.
  final DateTime at;

  /// Set for azan/jamaat items.
  final Prayer? prayer;

  /// Matrix mode [AzanMode.silent]: show without sound.
  final bool silent;

  /// Matrix mode [AzanMode.beep]: short tone instead of azan audio.
  final bool beepOnly;

  /// Deterministic id so rescheduling replaces rather than duplicates:
  /// derived from kind, prayer, and the minute it fires.
  int get id =>
      Object.hash(kind.index, prayer?.index ?? -1, at.year, at.month, at.day,
          at.hour, at.minute) &
      0x7FFFFFFF;

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
