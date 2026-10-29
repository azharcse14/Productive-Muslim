import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../../core/utils/haptics.dart';
import '../../domain/entities/asma_quiz.dart';
import '../../domain/entities/dua.dart';

/// Drives one Asmaul Husna quiz run: builds a deterministic question set from
/// the 99 names, tracks the current index / score / locked selection, and
/// persists a best-score per mode (one int key each, like [TasbihStore]).
final class AsmaQuizStore {
  AsmaQuizStore(
    this._prefs, {
    int Function()? seed,
    void Function()? correctHaptic,
    void Function()? wrongHaptic,
    this.questionCount = 10,
  })  : _seed = seed ?? (() => DateTime.now().millisecondsSinceEpoch),
        _correctHaptic = correctHaptic ?? _defaultCorrectHaptic,
        _wrongHaptic = wrongHaptic ?? _defaultWrongHaptic;

  static const _bestKeyPrefix = 'asma_quiz_best_';

  final SharedPreferencesAsync _prefs;
  final int Function() _seed;
  final void Function() _correctHaptic;
  final void Function() _wrongHaptic;
  final int questionCount;

  late final mode = signal(AsmaQuizMode.nameToMeaning);
  late final questions = signal(const <AsmaQuestion>[]);
  late final index = signal(0);
  late final score = signal(0);

  /// Index into the current question's options, or null until the user taps.
  late final selected = signal<int?>(null);

  /// Best score recorded for the active [mode] (persisted), 0 until loaded.
  late final best = signal(0);

  /// Derived: a tap has locked the current question.
  late final answered = computed(() => selected.value != null);

  /// Derived: every question has been answered.
  late final finished = computed(
    () => questions.value.isNotEmpty && index.value >= questions.value.length,
  );

  /// Derived: the question on screen, or null when finished / empty.
  late final current = computed(() {
    final all = questions.value;
    final i = index.value;
    return i >= 0 && i < all.length ? all[i] : null;
  });

  static void _defaultCorrectHaptic() =>
      Haptics.light();

  static void _defaultWrongHaptic() =>
      Haptics.medium();

  String _bestKey(AsmaQuizMode mode) => '$_bestKeyPrefix${mode.name}';

  /// Restores the persisted best score for the current [mode].
  Future<void> load() async {
    final m = mode.value;
    final stored = await _prefs.getInt(_bestKey(m));
    // A quicker mode switch since: its own load owns [best].
    if (mode.value == m) {
      best.value = stored ?? 0;
    }
  }

  /// Begins a fresh run for [names] in the given [mode]. The seed is captured
  /// once so a run is stable across rebuilds; [restart] re-seeds.
  Future<void> start(List<AsmaName> names, {AsmaQuizMode? mode}) async {
    if (mode != null && mode != this.mode.value) {
      this.mode.value = mode;
      await load();
    }
    _build(names, _seed());
  }

  void _build(List<AsmaName> names, int seed) {
    questions.value = AsmaQuizGenerator.generate(
      names,
      seed: seed,
      count: questionCount,
      mode: mode.value,
    );
    index.value = 0;
    score.value = 0;
    selected.value = null;
  }

  /// Locks in [optionIndex] for the current question, scores it, and fires
  /// the matching haptic. No-op once already answered or finished.
  void answer(int optionIndex) {
    if (selected.value != null) {
      return;
    }
    final question = current.value;
    if (question == null) {
      return;
    }
    selected.value = optionIndex;
    if (question.isCorrect(optionIndex)) {
      score.value = score.value + 1;
      _correctHaptic();
    } else {
      _wrongHaptic();
    }
  }

  /// Advances to the next question; when the last is consumed, records the
  /// best score and persists it if it improved.
  Future<void> next() async {
    if (selected.value == null) {
      return; // must answer first
    }
    index.value = index.value + 1;
    selected.value = null;
    if (index.value >= questions.value.length) {
      await _recordBest();
    }
  }

  Future<void> _recordBest() async {
    if (score.value > best.value) {
      best.value = score.value;
      await _prefs.setInt(_bestKey(mode.value), score.value);
    }
  }

  /// Re-rolls a new question set (fresh seed) over the same names.
  void restart(List<AsmaName> names) => _build(names, _seed());
}