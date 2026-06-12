import 'package:signals_flutter/signals_flutter.dart';

import '../../domain/entities/daily_entry.dart';
import '../../domain/entities/period_stats.dart';
import '../../domain/entities/tracker_item.dart';
import '../../domain/repositories/muhasaba_repository.dart';

enum MuhasabaPeriod { today, week, month, year }

/// App-scoped muhasaba state: today's checklist (with back-fill date
/// switching) and the dashboard aggregates. Shared with Home's
/// prayer-check affordance.
final class MuhasabaStore {
  MuhasabaStore(this._repository, {DateTime Function()? now})
      : _now = now ?? DateTime.now;

  final MuhasabaRepository _repository;
  final DateTime Function() _now;

  late final items = signal(const <TrackerItem>[]);
  late final archivedItems = signal(const <TrackerItem>[]);

  /// Date being edited (today by default; back-fill allowed, future not).
  late final selectedDate = signal(_today());

  /// itemId → value for [selectedDate].
  late final entries = signal(const <String, int>{});

  late final period = signal(MuhasabaPeriod.week);
  late final stats = signal<PeriodStats?>(null);
  late final loaded = signal(false);

  /// True until the user logs their very first entry (welcome state).
  late final firstDay = computed(() {
    final s = stats.value;
    if (!loaded.value || s == null) {
      return false;
    }
    final nothingEver =
        s.items.every((i) => i.totalValue == 0) && entries.value.isEmpty;
    return nothingEver;
  });

  DateTime _today() {
    final n = _now();
    return DateTime(n.year, n.month, n.day);
  }

  Future<void> load() async {
    await _repository.seedDefaultsIfEmpty();
    await _reloadItems();
    await selectDate(_today());
    await refreshStats();
    loaded.value = true;
  }

  Future<void> _reloadItems() async {
    final all = await _repository.items(includeArchived: true);
    final list = all.valueOrNull ?? const <TrackerItem>[];
    items.value = [for (final i in list) if (!i.archived) i];
    archivedItems.value = [for (final i in list) if (i.archived) i];
  }

  bool get selectedIsToday => selectedDate.value == _today();
  bool get canGoForward => selectedDate.value.isBefore(_today());

  Future<void> selectDate(DateTime date) async {
    final clamped = DateTime(date.year, date.month, date.day);
    if (clamped.isAfter(_today())) {
      return;
    }
    selectedDate.value = clamped;
    final result = await _repository.entriesOn(clamped);
    entries.value = {
      for (final e in result.valueOrNull ?? const <DailyEntry>[])
        e.itemId: e.value,
    };
  }

  int valueOf(String itemId) => entries.value[itemId] ?? 0;

  Future<void> setValue(String itemId, int value) async {
    final clamped = value < 0 ? 0 : value;
    entries.value = {
      ...entries.value,
      if (clamped > 0) itemId: clamped,
    }..removeWhere((k, v) => clamped == 0 && k == itemId);
    await _repository.setEntry(
      DailyEntry(itemId: itemId, date: selectedDate.value, value: clamped),
    );
    await refreshStats();
  }

  /// Convenience for Home's prayer check: toggles today's salah entry.
  Future<void> togglePrayerToday(String salahId) async {
    if (!selectedIsToday) {
      await selectDate(_today());
    }
    await setValue(salahId, valueOf(salahId) > 0 ? 0 : 1);
  }

  Future<void> setPeriod(MuhasabaPeriod p) async {
    period.value = p;
    await refreshStats();
  }

  (DateTime, DateTime) _range() {
    final today = _today();
    return switch (period.value) {
      MuhasabaPeriod.today => (today, today),
      MuhasabaPeriod.week => (
          today.subtract(const Duration(days: 6)),
          today,
        ),
      MuhasabaPeriod.month => (
          today.subtract(const Duration(days: 29)),
          today,
        ),
      MuhasabaPeriod.year => (
          today.subtract(const Duration(days: 364)),
          today,
        ),
    };
  }

  Future<void> refreshStats() async {
    final (start, end) = _range();
    final result = await _repository.periodStats(
      start: start,
      end: end,
      today: _today(),
    );
    if (result.valueOrNull case final value?) {
      stats.value = value;
    }
  }

  Future<void> addItem({
    required String name,
    required TrackerKind kind,
    int? dailyTarget,
    required String icon,
    required int colorIndex,
  }) async {
    final item = TrackerItem(
      id: 'custom_${_now().millisecondsSinceEpoch}',
      name: name,
      kind: kind,
      dailyTarget: dailyTarget,
      icon: icon,
      colorIndex: colorIndex,
      sortOrder: 100 + items.value.length,
    );
    await _repository.upsertItem(item);
    await _reloadItems();
  }

  Future<void> updateItem(TrackerItem item) async {
    await _repository.upsertItem(item);
    await _reloadItems();
  }

  Future<void> setArchived(String id, {required bool archived}) async {
    await _repository.setArchived(id, archived: archived);
    await _reloadItems();
    await refreshStats();
  }
}
