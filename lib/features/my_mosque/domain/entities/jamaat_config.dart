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
  const JamaatConfig([this.entries = const {}]);

  static const none = JamaatConfig();

  final Map<Prayer, JamaatEntry> entries;

  /// Resolved jamaat moment for [prayer] whose waqt begins at [waqtStart]
  /// (wall clock), or null when not configured.
  DateTime? timeFor(Prayer prayer, DateTime waqtStart) =>
      switch (entries[prayer]) {
        null || NoJamaat() => null,
        FixedJamaat(:final time) => DateTime(
            waqtStart.year,
            waqtStart.month,
            waqtStart.day,
            time.hour,
            time.minute,
          ),
        OffsetJamaat(:final offset) => waqtStart.add(offset),
      };
}
