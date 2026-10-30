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
    this.dailyAyahReminder = false,
    this.dailyAyahMinute = 8 * 60,
    this.dailyHadithReminder = false,
    this.dailyHadithMinute = 18 * 60,
    this.jamaatFocus = false,
    this.jamaatFocusLead = const Duration(minutes: 5),
    this.jamaatFocusDuration = const Duration(minutes: 20),
    this.jamaatFocusPrayers = const {...Prayer.values},
    this.jamaatFocusBlock = true,
    this.jamaatFocusStrict = false,
    this.nafsLock = false,
    this.nafsLockDuration = const Duration(minutes: 5),
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

  /// Daily morning Quran Ayah reminder toggle (default 08:00 AM).
  final bool dailyAyahReminder;
  final int dailyAyahMinute;

  /// Daily evening Hadith reminder toggle (default 06:00 PM / 18:00).
  final bool dailyHadithReminder;
  final int dailyHadithMinute;

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

  /// Android: 5 hard shakes lock the phone (strict, apps blocked) for
  /// [nafsLockDuration].
  final bool nafsLock;
  final Duration nafsLockDuration;

  AzanMode modeFor(Prayer prayer) => prayerModes[prayer] ?? AzanMode.azan;

  /// What a strict session with no length runs for instead: "until I end
  /// it" can't be ended in strict mode.
  static const strictFallbackDuration = Duration(minutes: 20);

  /// [jamaatFocusDuration] as sessions use it: strict always has a length,
  /// however the matrix was built.
  Duration get effectiveFocusDuration =>
      jamaatFocusStrict && jamaatFocusDuration == Duration.zero
      ? strictFallbackDuration
      : jamaatFocusDuration;

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
    bool? dailyAyahReminder,
    int? dailyAyahMinute,
    bool? dailyHadithReminder,
    int? dailyHadithMinute,
    bool? jamaatFocus,
    Duration? jamaatFocusLead,
    Duration? jamaatFocusDuration,
    Set<Prayer>? jamaatFocusPrayers,
    bool? jamaatFocusBlock,
    bool? jamaatFocusStrict,
    bool? nafsLock,
    Duration? nafsLockDuration,
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
      dailyAyahReminder: dailyAyahReminder ?? this.dailyAyahReminder,
      dailyAyahMinute: dailyAyahMinute ?? this.dailyAyahMinute,
      dailyHadithReminder: dailyHadithReminder ?? this.dailyHadithReminder,
      dailyHadithMinute: dailyHadithMinute ?? this.dailyHadithMinute,
      jamaatFocus: jamaatFocus ?? this.jamaatFocus,
      jamaatFocusLead: jamaatFocusLead ?? this.jamaatFocusLead,
      // Strict + "until I end it" would never end: fall back to 20 min.
      jamaatFocusDuration: strict && duration == Duration.zero
          ? strictFallbackDuration
          : duration,
      jamaatFocusPrayers: jamaatFocusPrayers ?? this.jamaatFocusPrayers,
      jamaatFocusBlock: jamaatFocusBlock ?? this.jamaatFocusBlock,
      jamaatFocusStrict: strict,
      nafsLock: nafsLock ?? this.nafsLock,
      nafsLockDuration: nafsLockDuration ?? this.nafsLockDuration,
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
        other.dailyAyahReminder != dailyAyahReminder ||
        other.dailyAyahMinute != dailyAyahMinute ||
        other.dailyHadithReminder != dailyHadithReminder ||
        other.dailyHadithMinute != dailyHadithMinute ||
        other.jamaatFocus != jamaatFocus ||
        other.jamaatFocusLead != jamaatFocusLead ||
        other.jamaatFocusDuration != jamaatFocusDuration ||
        other.jamaatFocusBlock != jamaatFocusBlock ||
        other.jamaatFocusStrict != jamaatFocusStrict ||
        other.nafsLock != nafsLock ||
        other.nafsLockDuration != nafsLockDuration ||
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
    dailyAyahReminder,
    dailyAyahMinute,
    dailyHadithReminder,
    dailyHadithMinute,
    Object.hash(
      jamaatFocus,
      jamaatFocusLead,
      jamaatFocusDuration,
      jamaatFocusBlock,
      jamaatFocusStrict,
      Object.hashAllUnordered(jamaatFocusPrayers),
      nafsLock,
      nafsLockDuration,
    ),
    Object.hashAllUnordered(
      prayerModes.entries.map((e) => Object.hash(e.key, e.value)),
    ),
  );
}
