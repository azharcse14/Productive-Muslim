import '../../../daily_content/domain/usecases/pick_daily_content.dart';
import 'prayer_params.dart';

/// Per-prayer alert mode (Settings notification matrix, design §12).
enum AzanMode { azan, beep, silent, off }

/// User notification preferences. Defined here in Phase 2 (persisted with
/// settings); the scheduler consumes it in Phase 4.
final class NotificationMatrix {
  const NotificationMatrix({
    this.prayerModes = const {},
    this.sahriAlert = true,
    this.sahriLead = const Duration(minutes: 30),
    this.iftarAlert = true,
    this.jamaatReminder = false,
    this.jamaatLead = const Duration(minutes: 15),
    this.muhasabaEveningReminder = false,
    this.dailyReminder = false,
    this.dailyReminderMinute = 9 * 60,
    this.dailyReminderKind = DailyContentKind.hadith,
    this.jamaatFocus = false,
    this.jamaatFocusLead = const Duration(minutes: 5),
    this.jamaatFocusDuration = const Duration(minutes: 20),
    this.jamaatFocusPrayers = const {...Prayer.values},
    this.jamaatFocusBlock = true,
    this.jamaatFocusStrict = false,
  });

  /// Missing key = [AzanMode.azan] (sound on by default).
  final Map<Prayer, AzanMode> prayerModes;
  final bool sahriAlert;
  final Duration sahriLead;
  final bool iftarAlert;
  final bool jamaatReminder;
  final Duration jamaatLead;
  final bool muhasabaEveningReminder;

  /// "Hadith/Dua of the day" daily reminder toggle.
  final bool dailyReminder;

  /// Fire time as minutes past local midnight (0..1439). Default 09:00.
  final int dailyReminderMinute;

  /// Which content the daily reminder surfaces (drives copy + deep link).
  final DailyContentKind dailyReminderKind;

  /// Jamaat focus: silence (and on Android, lock) the phone around jamaat.
  final bool jamaatFocus;

  /// How long before jamaat the focus session starts.
  final Duration jamaatFocusLead;

  /// Session length from its start; [Duration.zero] = until the user ends
  /// it. Strict mode always has a length (see [copyWith]).
  final Duration jamaatFocusDuration;

  /// Prayers the session runs for (each still needs a jamaat time).
  final Set<Prayer> jamaatFocusPrayers;

  /// Android: block other apps behind a full-screen jamaat screen.
  final bool jamaatFocusBlock;

  /// No "end" button, DND re-applied if switched off, settings frozen
  /// while a session runs.
  final bool jamaatFocusStrict;

  AzanMode modeFor(Prayer prayer) => prayerModes[prayer] ?? AzanMode.azan;

  NotificationMatrix copyWith({
    Map<Prayer, AzanMode>? prayerModes,
    bool? sahriAlert,
    Duration? sahriLead,
    bool? iftarAlert,
    bool? jamaatReminder,
    Duration? jamaatLead,
    bool? muhasabaEveningReminder,
    bool? dailyReminder,
    int? dailyReminderMinute,
    DailyContentKind? dailyReminderKind,
    bool? jamaatFocus,
    Duration? jamaatFocusLead,
    Duration? jamaatFocusDuration,
    Set<Prayer>? jamaatFocusPrayers,
    bool? jamaatFocusBlock,
    bool? jamaatFocusStrict,
  }) {
    final strict = jamaatFocusStrict ?? this.jamaatFocusStrict;
    final duration = jamaatFocusDuration ?? this.jamaatFocusDuration;
    return NotificationMatrix(
      prayerModes: prayerModes ?? this.prayerModes,
      sahriAlert: sahriAlert ?? this.sahriAlert,
      sahriLead: sahriLead ?? this.sahriLead,
      iftarAlert: iftarAlert ?? this.iftarAlert,
      jamaatReminder: jamaatReminder ?? this.jamaatReminder,
      jamaatLead: jamaatLead ?? this.jamaatLead,
      muhasabaEveningReminder:
          muhasabaEveningReminder ?? this.muhasabaEveningReminder,
      dailyReminder: dailyReminder ?? this.dailyReminder,
      dailyReminderMinute: dailyReminderMinute ?? this.dailyReminderMinute,
      dailyReminderKind: dailyReminderKind ?? this.dailyReminderKind,
      jamaatFocus: jamaatFocus ?? this.jamaatFocus,
      jamaatFocusLead: jamaatFocusLead ?? this.jamaatFocusLead,
      // Strict + "until I end it" would never end: fall back to 20 min.
      jamaatFocusDuration: strict && duration == Duration.zero
          ? const Duration(minutes: 20)
          : duration,
      jamaatFocusPrayers: jamaatFocusPrayers ?? this.jamaatFocusPrayers,
      jamaatFocusBlock: jamaatFocusBlock ?? this.jamaatFocusBlock,
      jamaatFocusStrict: strict,
    );
  }

  @override
  bool operator ==(Object other) {
    if (other is! NotificationMatrix ||
        other.sahriAlert != sahriAlert ||
        other.sahriLead != sahriLead ||
        other.iftarAlert != iftarAlert ||
        other.jamaatReminder != jamaatReminder ||
        other.jamaatLead != jamaatLead ||
        other.muhasabaEveningReminder != muhasabaEveningReminder ||
        other.dailyReminder != dailyReminder ||
        other.dailyReminderMinute != dailyReminderMinute ||
        other.dailyReminderKind != dailyReminderKind ||
        other.jamaatFocus != jamaatFocus ||
        other.jamaatFocusLead != jamaatFocusLead ||
        other.jamaatFocusDuration != jamaatFocusDuration ||
        other.jamaatFocusBlock != jamaatFocusBlock ||
        other.jamaatFocusStrict != jamaatFocusStrict ||
        !other.jamaatFocusPrayers.containsAll(jamaatFocusPrayers) ||
        other.jamaatFocusPrayers.length != jamaatFocusPrayers.length ||
        other.prayerModes.length != prayerModes.length) {
      return false;
    }
    for (final entry in prayerModes.entries) {
      if (other.prayerModes[entry.key] != entry.value) {
        return false;
      }
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
        sahriAlert,
        sahriLead,
        iftarAlert,
        jamaatReminder,
        jamaatLead,
        muhasabaEveningReminder,
        dailyReminder,
        dailyReminderMinute,
        dailyReminderKind,
        Object.hash(
          jamaatFocus,
          jamaatFocusLead,
          jamaatFocusDuration,
          jamaatFocusBlock,
          jamaatFocusStrict,
          Object.hashAllUnordered(jamaatFocusPrayers),
        ),
        Object.hashAllUnordered(
          prayerModes.entries.map((e) => Object.hash(e.key, e.value)),
        ),
      );
}
