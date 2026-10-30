import '../../../settings/domain/entities/prayer_params.dart';

/// Wall-clock time of day, Flutter-free (domain stays pure Dart).
final class ClockTime {
  const ClockTime(this.hour, this.minute)
    : assert(hour >= 0 && hour < 24, 'hour out of range'),
      assert(minute >= 0 && minute < 60, 'minute out of range');

  final int hour;
  final int minute;

  @override
  bool operator ==(Object other) =>
      other is ClockTime && other.hour == hour && other.minute == minute;

  @override
  int get hashCode => Object.hash(hour, minute);
}

/// Per-prayer jamaat setting (guide §5): fixed time, offset from waqt
/// start, or none. Maghrib conventionally uses offset (+5 default).
sealed class JamaatEntry {
  const JamaatEntry();
}

final class FixedJamaat extends JamaatEntry {
  const FixedJamaat(this.time);

  final ClockTime time;

  @override
  bool operator ==(Object other) => other is FixedJamaat && other.time == time;

  @override
  int get hashCode => time.hashCode;
}

final class OffsetJamaat extends JamaatEntry {
  const OffsetJamaat(this.offset);

  final Duration offset;

  @override
  bool operator ==(Object other) =>
      other is OffsetJamaat && other.offset == offset;

  @override
  int get hashCode => offset.hashCode;
}

final class NoJamaat extends JamaatEntry {
  const NoJamaat();

  @override
  bool operator ==(Object other) => other is NoJamaat;

  @override
  int get hashCode => (NoJamaat).hashCode;
}

/// The active mosque's jamaat times. Phase 5 adds named profiles; the
/// countdown state machine only needs [timeFor].
final class JamaatConfig {
  const JamaatConfig([this.entries = const {}, this.jumuah]);

  static const none = JamaatConfig();

  final Map<Prayer, JamaatEntry> entries;

  /// Friday's Jumu'ah jamaat, replacing Dhuhr's entry on Fridays when set.
  final ClockTime? jumuah;

  /// Resolved jamaat moment for [prayer] whose waqt begins at [waqtStart]
  /// (wall clock), or null when not configured.
  DateTime? timeFor(Prayer prayer, DateTime waqtStart) => switch (jumuah) {
    final j?
        when prayer == Prayer.dhuhr && waqtStart.weekday == DateTime.friday =>
      _near(waqtStart, j),
    _ => _entryTime(prayer, waqtStart),
  };

  DateTime? _entryTime(Prayer prayer, DateTime waqtStart) =>
      switch (entries[prayer]) {
        null || NoJamaat() => null,
        FixedJamaat(:final time) => _near(waqtStart, time),
        OffsetJamaat(:final offset) => waqtStart.add(offset),
      };

  /// [time] on the calendar day within 12 h of [waqtStart]: an isha that
  /// starts after midnight keeps a 23:45 jamaat on the same night, and an
  /// evening isha puts a 00:15 jamaat after it.
  static DateTime _near(DateTime waqtStart, ClockTime time) {
    DateTime on(int day) => DateTime(
      waqtStart.year,
      waqtStart.month,
      waqtStart.day + day,
      time.hour,
      time.minute,
    );
    final gap = on(0).difference(waqtStart);
    if (gap > const Duration(hours: 12)) {
      return on(-1);
    }
    if (gap < const Duration(hours: -12)) {
      return on(1);
    }
    return on(0);
  }
}
