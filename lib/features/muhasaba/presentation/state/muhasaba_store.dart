import 'dart:async';

import 'package:flutter/widgets.dart' show AppLifecycleListener;
import 'package:shared_preferences/shared_preferences.dart';
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

  /// itemId → value for [selectedDate].
  late final entries = computed(
    () => _days.value[selectedDate.value] ?? const <String, int>{},
  );

  /// itemId → value on [day] (empty until that day is loaded). Reactive.
  Map<String, int> entriesOn(DateTime day) =>
      _days.value[DateTime(day.year, day.month, day.day)] ??
      const <String, int>{};

  late final period = signal(MuhasabaPeriod.week);
  late final stats = signal<PeriodStats?>(null);
  late final loaded = signal(false);

  /// True until the user logs their very first entry (welcome state).
  late final firstDay = computed(() {
    final s = stats.value;
    if (!loaded.value || s == null) {
      return false;
    }
    // items only cover the selected period; bestStreak scans ~400 days, so
    // it is 0 only for a user who has (effectively) never logged anything.
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

  Future<void> load() async {
    if (await _prefs?.getBool(_welcomeKey) ?? false) {
      welcomeDismissed.value = true;
    }
    await _repository.seedDefaults();
    await _reloadItems();
    _day = _today();
    await selectDate(_day!);
    await _loadYesterday();
    await refreshStats();
    loaded.value = true;
    // App-scoped store outlives midnight: re-check the day on every resume.
    _lifecycle ??= AppLifecycleListener(
      onResume: () => unawaited(rollOverIfNewDay()),
    );
  }

  /// Follows the calendar after midnight: if [selectedDate] was "today" it
  /// moves to the new today (a back-filled past date stays put), and the
  /// dashboard/streak are recomputed. No-op on the same day.
  Future<void> rollOverIfNewDay() async {
    final previous = _day;
    final today = _today();
    if (previous == null || previous == today) {
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

  Future<void> _loadDay(DateTime day) async {
    final before = _days.value[day];
    final result = await _repository.entriesOn(day);
    final fresh = {
      for (final e in result.valueOrNull ?? const <DailyEntry>[])
        e.itemId: e.value,
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
          }
        }
      }
    }
    _days.value = {..._days.value, day: fresh};
  }

  /// Sets one cached value (0 removes it), leaving other keys untouched.
  void _put(DateTime day, String itemId, int value) {
    final map = {...?_days.value[day]};
    if (value > 0) {
      map[itemId] = value;
    } else {
      map.remove(itemId);
    }
    _days.value = {..._days.value, day: map};
  }

  Future<void> _reloadItems() async {
    final all = await _repository.items(includeArchived: true);
    final list = all.valueOrNull ?? const <TrackerItem>[];
    items.value = [
      for (final i in list)
        if (!i.archived) i,
    ];
    archivedItems.value = [
      for (final i in list)
        if (i.archived) i,
    ];
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
    if (!_days.value.containsKey(d)) {
      await _loadDay(d);
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
      saveFailures.value++;
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
    // An archived tracker takes no new entries (or it would keep streaks
    // and badges alive). Asks the repository: callers may run pre-[load].
    final active = await _repository.items();
    if (!(active.valueOrNull ?? const <TrackerItem>[]).any(
      (i) => i.id == itemId,
    )) {
      return;
    }
    final existing = await _repository.entriesOn(day);
    if ((existing.valueOrNull ?? const <DailyEntry>[]).any(
      (e) => e.itemId == itemId && e.value > 0,
    )) {
      return;
    }
    final saved = await _repository.setEntry(
      DailyEntry(itemId: itemId, date: day, value: 1),
    );
    if (!saved.isSuccess) {
      return;
    }
    if (_days.value.containsKey(day)) {
      _put(day, itemId, 1);
    }
    await refreshStats();
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

  (DateTime, DateTime) _range() {
    final today = _today();
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
    };
  }

  /// Bumped per [refreshStats]; only the latest pass may write [stats].
  int _statsRequest = 0;

  Future<void> refreshStats() async {
    // Anything pending is covered by this pass.
    _statsTimer?.cancel();
    final request = ++_statsRequest;
    final today = _today();
    final (start, end) = _range();
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
    // A target change flips done-days, so the dashboard must follow.
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
