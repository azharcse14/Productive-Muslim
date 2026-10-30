import 'package:flutter_test/flutter_test.dart';
import 'package:productive_muslim/features/my_mosque/domain/entities/jamaat_config.dart';
import 'package:productive_muslim/features/notifications/domain/entities/notification_item.dart';
import 'package:productive_muslim/features/notifications/domain/usecases/build_focus_windows.dart';
import 'package:productive_muslim/features/notifications/domain/usecases/build_notification_plan.dart';
import 'package:productive_muslim/features/prayer_times/domain/entities/prayer_day.dart';
import 'package:productive_muslim/features/settings/domain/entities/notification_matrix.dart';
import 'package:productive_muslim/features/settings/domain/entities/prayer_params.dart';

PrayerDay _day(int day) => PrayerDay(
  ishaYesterday: DateTime(2026, 5, day - 1, 20, 15),
  fajr: DateTime(2026, 5, day, 3, 45),
  sunrise: DateTime(2026, 5, day, 5, 10),
  dhuhr: DateTime(2026, 5, day, 12),
  asr: DateTime(2026, 5, day, 16, 30),
  maghrib: DateTime(2026, 5, day, 18, 45),
  isha: DateTime(2026, 5, day, 20, 15),
  fajrTomorrow: DateTime(2026, 5, day + 1, 3, 45),
);

// Jamaat 15 min into each waqt; no jamaat set for asr.
const _jamaat = JamaatConfig({
  Prayer.fajr: OffsetJamaat(Duration(minutes: 15)),
  Prayer.dhuhr: OffsetJamaat(Duration(minutes: 15)),
  Prayer.maghrib: OffsetJamaat(Duration(minutes: 15)),
  Prayer.isha: OffsetJamaat(Duration(minutes: 15)),
});

const _on = NotificationMatrix(jamaatFocus: true);

List<FocusWindow> _windows(NotificationMatrix matrix, {DateTime? from}) =>
    buildFocusWindows(
      from: from ?? DateTime(2026, 5, 12, 3),
      days: [_day(12), _day(13), _day(14)],
      matrix: matrix,
      jamaat: _jamaat,
      window: const Duration(hours: 24),
    );

void main() {
  test('off → nothing', () {
    expect(_windows(const NotificationMatrix()), isEmpty);
  });

  test('starts lead before jamaat, ends after duration; skips no-jamaat', () {
    final w = _windows(_on);
    // 24h from 12th 03:00: 4 prayers on the 12th; the 13th's fajr focus
    // (03:55) is past the window.
    expect(w.map((e) => e.prayer), [
      Prayer.fajr,
      Prayer.dhuhr,
      Prayer.maghrib,
      Prayer.isha,
    ]);
    // Fajr 03:45 + 15 = jamaat 04:00; default lead 5 → 03:55, 20 min long.
    expect(w.first.start, DateTime(2026, 5, 12, 3, 55));
    expect(w.first.end, DateTime(2026, 5, 12, 4, 15));
  });

  test('no session for a jamaat after its waqt ends', () {
    final w = buildFocusWindows(
      from: DateTime(2026, 5, 12, 3),
      days: [_day(12)],
      matrix: _on,
      // Asr ends at maghrib 18:45: a stale 19:00 jamaat is skipped.
      jamaat: const JamaatConfig({
        Prayer.asr: FixedJamaat(ClockTime(19, 0)),
        Prayer.dhuhr: FixedJamaat(ClockTime(13, 15)),
      }),
      window: const Duration(hours: 24),
    );
    expect(w.map((e) => e.prayer), [Prayer.dhuhr]);
    // ...so no "prayed in jamaat?" end item for it either.
    final plan = buildNotificationPlan(
      from: DateTime(2026, 5, 12, 3),
      days: [_day(12)],
      matrix: _on,
      jamaat: JamaatConfig.none,
      focusWindows: w,
    );
    expect(
      plan
          .where((i) => i.kind == NotificationKind.focusEnd)
          .map((i) => i.prayer),
      [Prayer.dhuhr],
    );
  });

  test("invariant: every focus window's jamaat lies within its waqt", () {
    final days = [_day(12), _day(13), _day(14)];
    final w = buildFocusWindows(
      from: DateTime(2026, 5, 12, 3),
      days: days,
      matrix: _on,
      jamaat: const JamaatConfig({
        Prayer.fajr: FixedJamaat(ClockTime(5, 30)), // past sunrise 05:10
        Prayer.dhuhr: OffsetJamaat(Duration(minutes: 20)),
        Prayer.asr: FixedJamaat(ClockTime(17, 0)),
        Prayer.maghrib: OffsetJamaat(Duration(hours: 2)), // past isha
        Prayer.isha: FixedJamaat(ClockTime(0, 15)), // after midnight
      }),
    );
    for (final f in w) {
      final jamaatAt = f.start.add(_on.jamaatFocusLead);
      final day = days.lastWhere((d) => !d.startOf(f.prayer).isAfter(jamaatAt));
      expect(jamaatAt.isBefore(day.endOf(f.prayer)), isTrue, reason: '$f');
    }
    expect(w.map((e) => e.prayer).toSet(), {
      Prayer.dhuhr,
      Prayer.asr,
      Prayer.isha,
    });
  });

  test('zero duration = until the user ends it', () {
    final w = _windows(_on.copyWith(jamaatFocusDuration: Duration.zero));
    expect(w.every((e) => e.end == null), isTrue);
  });

  test('strict never keeps "until I end it"', () {
    final m = _on
        .copyWith(jamaatFocusDuration: Duration.zero)
        .copyWith(jamaatFocusStrict: true);
    expect(m.jamaatFocusDuration, const Duration(minutes: 20));
  });

  test('a strict matrix built with no length still gets timed sessions', () {
    const m = NotificationMatrix(
      jamaatFocus: true,
      jamaatFocusStrict: true,
      jamaatFocusDuration: Duration.zero,
    );
    final w = _windows(m).first;
    expect(w.end, w.start.add(NotificationMatrix.strictFallbackDuration));
  });

  test('only selected prayers', () {
    final w = _windows(_on.copyWith(jamaatFocusPrayers: {Prayer.isha}));
    expect(w.map((e) => e.prayer), [Prayer.isha]);
  });

  test('a session running at `from` is kept', () {
    final w = _windows(_on, from: DateTime(2026, 5, 12, 4, 5));
    expect(w.first.start, DateTime(2026, 5, 12, 3, 55));
  });

  test('"until I end it" is kept through the native late-start grace', () {
    final manual = _on.copyWith(jamaatFocusDuration: Duration.zero);
    // Fajr focus starts 03:55; still startable until 04:25.
    expect(
      _windows(manual, from: DateTime(2026, 5, 12, 4, 20)).first.start,
      DateTime(2026, 5, 12, 3, 55),
    );
    expect(
      _windows(manual, from: DateTime(2026, 5, 12, 4, 25)).first.prayer,
      Prayer.dhuhr,
    );
  });

  test('iOS: each focus window becomes a nudge in the plan', () {
    final from = DateTime(2026, 5, 12, 3);
    final windows = _windows(_on);
    final nudges = buildNotificationPlan(
      from: from,
      days: [_day(12), _day(13)],
      matrix: const NotificationMatrix(
        prayerModes: {
          Prayer.fajr: AzanMode.off,
          Prayer.dhuhr: AzanMode.off,
          Prayer.asr: AzanMode.off,
          Prayer.maghrib: AzanMode.off,
          Prayer.isha: AzanMode.off,
        },
      ),
      jamaat: _jamaat,
      window: const Duration(hours: 24),
      focusWindows: windows,
      focusStartNudges: true,
    ).where((i) => i.kind == NotificationKind.jamaatFocus);
    expect(nudges.map((i) => i.at), windows.map((w) => w.start));
  });

  test('each timed session ends with a "prayed in jamaat?" item', () {
    final windows = _windows(_on);
    final plan = buildNotificationPlan(
      from: DateTime(2026, 5, 12, 3),
      days: [_day(12), _day(13)],
      matrix: const NotificationMatrix(),
      jamaat: _jamaat,
      window: const Duration(hours: 24),
      focusWindows: windows,
    );
    // Android: no start nudge (the phone really goes silent).
    expect(plan.where((i) => i.kind == NotificationKind.jamaatFocus), isEmpty);
    final ends = plan.where((i) => i.kind == NotificationKind.focusEnd);
    expect(ends.map((i) => i.at), windows.map((w) => w.end));
    expect(ends.first.prayer, Prayer.fajr);
    expect(ends.first.prayerDay, DateTime(2026, 5, 12));
  });

  test('"until I end it" sessions get no end item', () {
    final plan = buildNotificationPlan(
      from: DateTime(2026, 5, 12, 3),
      days: [_day(12), _day(13)],
      matrix: const NotificationMatrix(),
      jamaat: _jamaat,
      window: const Duration(hours: 24),
      focusWindows: _windows(_on.copyWith(jamaatFocusDuration: Duration.zero)),
    );
    expect(plan.where((i) => i.kind == NotificationKind.focusEnd), isEmpty);
  });
}
