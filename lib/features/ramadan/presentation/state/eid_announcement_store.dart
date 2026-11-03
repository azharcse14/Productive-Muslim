import 'package:signals_flutter/signals_flutter.dart';

/// App-wide "Eid announced — Ramadan ended after 29 days" state, per Hijri
/// year. The composition root points `HijriDate.shortRamadanYears` at
/// [years], so every Hijri conversion (Ramadan screen, fasting, calendar,
/// home countdown, notifications) follows it.
final class EidAnnouncementStore {
  EidAnnouncementStore({
    required Future<Set<int>> Function() read,
    required Future<void> Function(int hijriYear, {required bool ended}) write,
    void Function()? onChanged,
  }) : _read = read,
       _write = write,
       _onChanged = onChanged;

  final Future<Set<int>> Function() _read;
  final Future<void> Function(int hijriYear, {required bool ended}) _write;

  /// Runs after a change is saved (reschedules notifications, the widget).
  final void Function()? _onChanged;

  /// Hijri years whose Ramadan ended after 29 days.
  late final years = signal(const <int>{});

  Future<void> load() async => years.value = await _read();

  /// Marks (or, with `ended: false`, un-marks) Ramadan of [hijriYear] as
  /// ended after 29 days. Saves first: a failed write throws and changes
  /// nothing.
  Future<void> setEnded(int hijriYear, {required bool ended}) async {
    await _write(hijriYear, ended: ended);
    years.value = ended
        ? {...years.value, hijriYear}
        : years.value.difference({hijriYear});
    _onChanged?.call();
  }
}
