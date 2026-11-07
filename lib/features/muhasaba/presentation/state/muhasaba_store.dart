import 'dart:async';

import 'package:flutter/widgets.dart' show AppLifecycleListener;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../../core/utils/result.dart';
import '../../domain/entities/daily_entry.dart';
import '../../domain/entities/period_stats.dart';
import '../../domain/entities/tracker_item.dart';
import '../../domain/repositories/muhasaba_repository.dart';

enum MuhasabaPeriod { today, week, month, year, custom }

/// App-scoped muhasaba state: today's checklist (with back-fill date
/// switching) and the dashboard aggregates. Shared with Home's
/// prayer-check affordance.
final class MuhasabaStore {
  MuhasabaStore(
    this._repository, {
    DateTime Function()? now,
    Set<String> Function(DateTime date)? lockedSalahOn,
    Duration statsDebounce = const Duration(milliseconds: 300),
    SharedPreferencesAsync? prefs,
  }) : _prefs = prefs,
       _now = now ?? DateTime.now,
       _lockedSalahOn = lockedSalahOn,
       _statsDebounce = statsDebounce;

  final MuhasabaRepository _repository;
  final DateTime Function() _now;

  /// Persists the welcome-banner dismissal; null (tests) = session only.
  final SharedPreferencesAsync? _prefs;
  static const _welcomeKey = 'muhasaba_welcome_dismissed';

  /// The welcome banner was dismissed (persisted across launches).
  late final welcomeDismissed = signal(false);

  /// Bumped each time an entry fails to save (the UI says so once per bump).
  late final saveFailures = signal(0);

  /// Trailing delay before [setValue] recomputes the dashboard: a burst of
  /// stepper taps costs one stats pass (and one achievements refresh), not
  /// one per tap. The tapped value itself updates instantly.
  final Duration _statsDebounce;
  Timer? _statsTimer;

  /// Salah ids whose waqt has not begun yet on a given date (so they can't
  /// be checked off ahead of time). Past dates / no-location → empty.
  /// Null in tests that don't wire prayer times → nothing is locked.
  final Set<String> Function(DateTime date)? _lockedSalahOn;

  /// Salah not yet checkable for [selectedDate] (waqt hasn't started).
  /// Read inside a reactive build to track [selectedDate].
  Set<String> get lockedSalah =>
      _lockedSalahOn?.call(selectedDate.value) ?? const <String>{};

  late final items = signal(const <TrackerItem>[]);
  late final archivedItems = signal(const <TrackerItem>[]);

  /// Date being edited (today by default; back-fill allowed, future not).
  late final selectedDate = signal(_today());

  /// date → (itemId → value) for every day loaded so far: [selectedDate],
  /// plus today and yesterday for Home, which must show the real day's
  /// ticks whatever date the Muhasaba tab is back-filling.
  late final _days = signal(const <DateTime, Map<String, int>>{});

  /// date → (itemId → target stamped on that day's entry), alongside
  /// [_days]. A key without a stamp is judged by the item's current target.
  late final _stamps = signal(const <DateTime, Map<String, int>>{});

  /// Days whose last read failed (their values are unknown).
  final _failedDays = <DateTime>{};

  /// itemId → value for [selectedDate].
  late final entries = computed(
    () => _days.value[selectedDate.value] ?? const <String, int>{},
  );

  /// itemId → value on [day] (empty until that day is loaded). Reactive.
  Map<String, int> entriesOn(DateTime day) =>
      _days.value[DateTime(day.year, day.month, day.day)] ??
      const <String, int>{};

  /// [item] as judged on [day]: against the target stamped on its entry
  /// there, so a later target edit doesn't re-judge a past day. Reactive.
  TrackerItem itemOn(TrackerItem item, DateTime day) => item.judgedBy(
    _stamps.value[DateTime(day.year, day.month, day.day)]?[item.id],
  );

  /// Mean completion of the active items on [day] (0..1), from the cached
  /// entries — independent of the dashboard [period]. Every active item
  /// counts today, so for today this equals the SQL day completion.
  /// Reactive.
  double completionOn(DateTime day) {
    final list = items.value;
    if (list.isEmpty) {
      return 0;
    }
    final values = entriesOn(day);
    return list.fold(
          0.0,
          (sum, i) => sum + itemOn(i, day).fractionOf(values[i.id] ?? 0),
        ) /
        list.length;
  }

  late final period = signal(MuhasabaPeriod.week);

  /// The [MuhasabaPeriod.custom] range as picked (date-only, inclusive);
  /// null until one is picked.
  late final customRange = signal<(DateTime, DateTime)?>(null);
  late final stats = signal<PeriodStats?>(null);
  late final loaded = signal(false);

  /// The last [load] couldn't read the tracker list (screens offer a retry).
  late final loadFailed = signal(false);

  /// True until the user logs their very first entry (welcome state).
  late final firstDay = computed(() {
    final s = stats.value;
    if (!loaded.value || s == null) {
      return false;
    }
    // items only cover the selected period; bestStreak covers all history,
    // so it is 0 only for a user who has never completed anything.
    final nothingEver =
        s.bestStreak == 0 &&
        s.items.every((i) => i.totalValue == 0) &&
        entries.value.isEmpty;
    return nothingEver;
  });

  /// The "today" [load] / [rollOverIfNewDay] last synced to (null before
  /// [load]). Not set by [refreshStats], or a tick after midnight would
  /// make the roll-over a no-op.
  DateTime? _day;
  AppLifecycleListener? _lifecycle;

  DateTime _today() {
    final n = _now();
    return DateTime(n.year, n.month, n.day);
  }

  /// The running [load], shared by overlapping callers (start-up, resume).
  Future<void>? _loading;

  Future<void> load() => _loading ??= _load().whenComplete(() {
    _loading = null;
  });

  Future<void> _load() async {
    if (await _prefs?.getBool(_welcomeKey) ?? false) {
      welcomeDismissed.value = true;
    }
    // App-scoped store outlives midnight: re-check the day on every resume
    // (which also retries a failed load or read).
    _lifecycle ??= AppLifecycleListener(
      onResume: () => unawaited(rollOverIfNewDay()),
    );
    // Without the tracker list there is nothing to show: [loaded] stays
    // false and [loadFailed] lets screens offer a retry (a resume retries
    // too).
    loadFailed.value = false;
    final seeded = (await _repository.seedDefaults()).isSuccess;
    if (!seeded || !await _reloadItems()) {
      loadFailed.value = true;
      return;
    }
    _day = _today();
    await selectDate(_day!);
    await _loadYesterday();
    await refreshStats();
    loaded.value = true;
  }

  /// Follows the calendar after midnight: if [selectedDate] was "today" it
  /// moves to the new today (a back-filled past date stays put), and the
  /// dashboard/streak are recomputed. On the same day it only retries what
  /// failed to load earlier.
  Future<void> rollOverIfNewDay() async {
    if (!loaded.value) {
      return load();
    }
    final previous = _day;
    final today = _today();
    if (previous == today) {
      for (final day in {selectedDate.value, today}) {
        if (!_days.value.containsKey(day)) {
          await _loadDay(day);
        }
      }
      if (stats.value == null || _statsStale) {
        await refreshStats();
      }
      return;
    }
    _day = today;
    if (selectedDate.value == previous) {
      await selectDate(today);
    } else {
      await _loadDay(today);
    }
    await _loadYesterday();
    await refreshStats();
  }

  /// Yesterday stays on Home until Fajr (the overnight Isha check-in).
  Future<void> _loadYesterday() {
    final t = _today();
    return _loadDay(DateTime(t.year, t.month, t.day - 1));
  }

  /// Reads [day] into the cache. A failed read leaves the day as it was —
  /// never cached as empty: its values are unknown, and [_setOn] refuses
  /// writes to such a day (a stepper's +1 from a fake 0 would overwrite
  /// the stored value).
  Future<void> _loadDay(DateTime day) async {
    final before = _days.value[day];
    final result = await _repository.entriesOn(day);
    final list = result.valueOrNull;
    if (list == null) {
      _failedDays.add(day);
      return;
    }
    _failedDays.remove(day);
    final fresh = {for (final e in list) e.itemId: e.value};
    final stamps = {
      for (final e in list)
        if (e.target case final t?) e.itemId: t,
    };
    // A _put landed mid-read (the read may predate its write): keep the
    // keys it changed rather than the possibly stale DB values.
    final current = _days.value[day];
    if (current != null && !identical(current, before)) {
      for (final id in {...?before?.keys, ...current.keys}) {
        if (before?[id] != current[id]) {
          if (current[id] case final v?) {
            fresh[id] = v;
          } else {
            fresh.remove(id);
            stamps.remove(id);
          }
        }
      }
    }
    _days.value = {..._days.value, day: fresh};
    _stamps.value = {..._stamps.value, day: stamps};
  }

  /// Sets one cached value (0 removes it), leaving other keys untouched.
  void _put(DateTime day, String itemId, int value) {
    final map = {...?_days.value[day]};
    if (value > 0) {
      map[itemId] = value;
    } else {
      map.remove(itemId);
      // The row is deleted: a re-log stamps the then-current target.
      _dropStamp(day, itemId);
    }
    _days.value = {..._days.value, day: map};
  }

  void _dropStamp(DateTime day, String itemId) {
    if (_stamps.value[day]?.containsKey(itemId) ?? false) {
      _stamps.value = {
        ..._stamps.value,
        day: {..._stamps.value[day]!}..remove(itemId),
      };
    }
  }

  /// False (lists untouched) when the read failed.
  Future<bool> _reloadItems() async {
    final all = await _repository.items(includeArchived: true);
    final list = all.valueOrNull;
    if (list == null) {
      return false;
    }
    items.value = [
      for (final i in list)
        if (!i.archived) i,
    ];
    archivedItems.value = [
      for (final i in list)
        if (i.archived) i,
    ];
    return true;
  }

  bool get selectedIsToday => selectedDate.value == _today();
  bool get canGoForward => selectedDate.value.isBefore(_today());

  Future<void> selectDate(DateTime date) async {
    final clamped = DateTime(date.year, date.month, date.day);
    if (clamped.isAfter(_today())) {
      return;
    }
    selectedDate.value = clamped;
    // Cached per day, so a slower earlier selectDate can't clobber this one.
    await _loadDay(clamped);
  }

  int valueOf(String itemId) => entries.value[itemId] ?? 0;

  Future<void> setValue(String itemId, int value) =>
      _setOn(itemId, selectedDate.value, value, debounceStats: true);

  /// Midnight-normalised "today" per the injected clock.
  DateTime get today => _today();

  /// Sets [itemId] on [day] without moving [selectedDate] (the Health
  /// screen logs today whatever date this tab is back-filling).
  Future<void> setValueOn(String itemId, DateTime day, int value) async {
    final d = DateTime(day.year, day.month, day.day);
    if (d.isAfter(_today())) {
      return;
    }
    await _setOn(itemId, d, value, debounceStats: true);
  }

  Future<void> _setOn(
    String itemId,
    DateTime day,
    int value, {
    bool debounceStats = false,
  }) async {
    // Can't mark a salah whose waqt hasn't started yet (today, or
    // yesterday's after-midnight isha). Other items skip the prayer-time
    // computation.
    if (value > 0 &&
        DefaultTrackers.salahIds.contains(itemId) &&
        (_lockedSalahOn?.call(day) ?? const <String>{}).contains(itemId)) {
      return;
    }
    // A day not read yet (e.g. a fresh today just after midnight) is read
    // first. One whose read failed showed values that aren't real, so
    // [value] may be built on a fake 0: don't write it, re-read so the
    // retry starts from the stored value.
    if (!_days.value.containsKey(day)) {
      final readFailed = _failedDays.contains(day);
      await _loadDay(day);
      if (readFailed || !_days.value.containsKey(day)) {
        saveFailures.value++;
        return;
      }
    }
    final clamped = value < 0 ? 0 : value;
    final previous = entriesOn(day)[itemId] ?? 0;
    _put(day, itemId, clamped);
    final saved = await _repository.setEntry(
      DailyEntry(itemId: itemId, date: day, value: clamped),
    );
    if (!saved.isSuccess) {
      // Don't show a tick the DB doesn't have — roll back only this key, so
      // a later toggle made while this save was in flight survives.
      if ((entriesOn(day)[itemId] ?? 0) == clamped) {
        _put(day, itemId, previous);
      }
      _reportSaveFailure(saved);
      return;
    }
    if (debounceStats && _statsDebounce > Duration.zero) {
      _statsTimer?.cancel();
      _statsTimer = Timer(_statsDebounce, () => unawaited(refreshStats()));
      return;
    }
    await refreshStats();
  }

  /// Marks [itemId] done on [date] (no un-mark) without moving the
  /// selected date — e.g. a notification action for a prayer whose azan
  /// already fired, so no waqt lock applies.
  Future<void> markDoneOn(String itemId, DateTime date) async {
    final day = DateTime(date.year, date.month, date.day);
    if (day.isAfter(_today())) {
      return;
    }
    final existing = await _repository.entriesOn(day);
    if (!existing.isSuccess) {
      // Unknown current value: writing 1 could lower a count (sadaqah 3).
      saveFailures.value++;
      return;
    }
    if (existing.valueOrNull!.any((e) => e.itemId == itemId && e.value > 0)) {
      return;
    }
    // An archived tracker is refused by the repository (callers may run
    // pre-[load], so the store's item list can't be trusted here).
    final saved = await _repository.setEntry(
      DailyEntry(itemId: itemId, date: day, value: 1),
    );
    if (!saved.isSuccess) {
      _reportSaveFailure(saved);
      return;
    }
    if (_days.value.containsKey(day)) {
      _put(day, itemId, 1);
    }
    await refreshStats();
  }

  /// Bumps [saveFailures] unless the write was refused for an archived
  /// tracker (a rule, not an error the user should hear about).
  void _reportSaveFailure(Result<void> saved) {
    if (saved case FailureResult(failure: ArchivedTrackerFailure())) {
      return;
    }
    saveFailures.value++;
  }

  /// Home's prayer check: toggles [salahId] on [day] (today, or yesterday
  /// for Isha before Fajr) without moving the Muhasaba tab's [selectedDate].
  Future<void> togglePrayerOn(String salahId, DateTime day) async {
    final d = DateTime(day.year, day.month, day.day);
    if (d.isAfter(_today())) {
      return;
    }
    if (!_days.value.containsKey(d)) {
      await _loadDay(d);
    }
    await _setOn(salahId, d, (entriesOn(d)[salahId] ?? 0) > 0 ? 0 : 1);
  }

  Future<void> setPeriod(MuhasabaPeriod p) async {
    period.value = p;
    await refreshStats();
  }

  /// Longest custom range, in days (bounds the heatmap and day loops).
  static const maxCustomDays = 366;

  /// Shows [start]..[end] (inclusive) on the dashboard. Days after today
  /// are cut off (the range never extends into the future); a span over
  /// [maxCustomDays] keeps its last [maxCustomDays] days.
  Future<void> setCustomRange(DateTime start, DateTime end) async {
    final e = DateTime(end.year, end.month, end.day);
    final earliest = DateTime(e.year, e.month, e.day - (maxCustomDays - 1));
    final s = DateTime(start.year, start.month, start.day);
    customRange.value = (s.isBefore(earliest) ? earliest : s, e);
    period.value = MuhasabaPeriod.custom;
    await refreshStats();
  }

  /// The dashboard's current range (date-only, inclusive, never past
  /// today).
  (DateTime, DateTime) get range {
    final today = _today();
    if (period.value == MuhasabaPeriod.custom) {
      if (customRange.value case (final s, final e)) {
        // Re-clamped on every read: the wall clock can move back (a manual
        // city behind the one the range was picked in).
        final end = e.isAfter(today) ? today : e;
        return (s.isAfter(end) ? end : s, end);
      }
    }
    return switch (period.value) {
      MuhasabaPeriod.today => (today, today),
      MuhasabaPeriod.week => (
        DateTime(today.year, today.month, today.day - 6),
        today,
      ),
      MuhasabaPeriod.month => (
        DateTime(today.year, today.month, today.day - 29),
        today,
      ),
      MuhasabaPeriod.year => (
        DateTime(today.year, today.month, today.day - 364),
        today,
      ),
      // Not picked yet: the week.
      MuhasabaPeriod.custom => (
        DateTime(today.year, today.month, today.day - 6),
        today,
      ),
    };
  }

  /// Bumped per [refreshStats]; only the latest pass may write [stats].
  int _statsRequest = 0;

  /// The latest [refreshStats] failed: [stats] is stale, and
  /// [rollOverIfNewDay] (on resume) retries it.
  bool _statsStale = false;

  Future<void> refreshStats() async {
    // Anything pending is covered by this pass.
    _statsTimer?.cancel();
    final request = ++_statsRequest;
    final today = _today();
    final (start, end) = range;
    final result = await _repository.periodStats(
      start: start,
      end: end,
      today: today,
    );
    // A slower earlier pass must not overwrite a newer one's result.
    if (request != _statsRequest) {
      return;
    }
    if (result.valueOrNull case final value?) {
      stats.value = value;
      _statsStale = false;
    } else {
      _statsStale = true;
    }
  }

  /// Adds a custom tracker; false when it couldn't be saved.
  Future<bool> addItem({
    required String name,
    required TrackerKind kind,
    int? dailyTarget,
    required String icon,
    required int colorIndex,
  }) async {
    // After every existing one, archived included (a count would collide
    // once something is archived). Custom items start at 100.
    final last = [
      ...items.value,
      ...archivedItems.value,
    ].fold(99, (m, i) => i.sortOrder > m ? i.sortOrder : m);
    final item = TrackerItem(
      id: 'custom_${_now().millisecondsSinceEpoch}',
      name: name,
      kind: kind,
      dailyTarget: dailyTarget,
      icon: icon,
      colorIndex: colorIndex,
      sortOrder: last + 1,
    );
    if (!(await _repository.upsertItem(item)).isSuccess) {
      return false;
    }
    await _reloadItems();
    // A new active item changes the completion denominator.
    await refreshStats();
    return true;
  }

  /// False when the edit couldn't be saved.
  Future<bool> updateItem(TrackerItem item) async {
    if (!(await _repository.upsertItem(item)).isSuccess) {
      return false;
    }
    await _reloadItems();
    // A target change applies from today on (the repository re-stamps
    // those entries; past ones keep the target they were logged against),
    // so today's cached stamps give way to the new target.
    for (final day in _stamps.value.keys.toList()) {
      if (!day.isBefore(_today())) {
        _dropStamp(day, item.id);
      }
    }
    await refreshStats();
    return true;
  }

  /// Hides the welcome banner for good.
  Future<void> dismissWelcome() async {
    welcomeDismissed.value = true;
    await _prefs?.setBool(_welcomeKey, true);
  }

  /// New checklist order for the active items ([ids] = all active ids).
  Future<void> reorder(List<String> ids) async {
    final byId = {for (final i in items.value) i.id: i};
    // Optimistic: the list moves under the finger, then persists.
    items.value = [
      for (final (i, id) in ids.indexed)
        if (byId[id] case final item?) item.copyWith(sortOrder: i),
    ];
    // Archived items keep trailing slots so a restore lands at the end.
    await _repository.reorder([
      ...ids,
      for (final a in archivedItems.value) a.id,
    ]);
    await _reloadItems();
  }

  /// False when the change couldn't be saved.
  Future<bool> setArchived(String id, {required bool archived}) async {
    if (!(await _repository.setArchived(id, archived: archived)).isSuccess) {
      return false;
    }
    await _reloadItems();
    await refreshStats();
    return true;
  }

  /// Restores every archived health default (Health screen opt-in);
  /// false when any couldn't be saved.
  Future<bool> enableHealthHabits() async {
    var ok = true;
    for (final i in archivedItems.value) {
      if (DefaultTrackers.healthIds.contains(i.id)) {
        ok &= (await _repository.setArchived(i.id, archived: false)).isSuccess;
      }
    }
    await _reloadItems();
    await refreshStats();
    return ok;
  }

  void dispose() {
    _statsTimer?.cancel();
    _lifecycle?.dispose();
  }
}
