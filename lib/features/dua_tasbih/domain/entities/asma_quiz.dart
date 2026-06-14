import 'dua.dart';

/// Quiz direction: show the Arabic name and pick its meaning, or show the
/// meaning and pick the Arabic name. Kept pure so the generator and store
/// stay free of any Flutter or l10n dependency.
enum AsmaQuizMode { nameToMeaning, meaningToName }

/// One multiple-choice question over the 99 names. The prompt is the source
/// name; [options] holds 4 distinct names (the prompt itself among them) and
/// [answerIndex] points at the correct one. Whether the option/prompt text is
/// the Arabic name or the meaning is decided by [mode] at render time — the
/// question stays language-neutral (meanings localize via [AsmaName]).
final class AsmaQuestion {
  const AsmaQuestion({
    required this.mode,
    required this.prompt,
    required this.options,
    required this.answerIndex,
  });

  final AsmaQuizMode mode;

  /// The name being asked about (its number/arabic/meaning drive the prompt).
  final AsmaName prompt;

  /// Exactly 4 names; one equals [prompt]. Render Arabic or meaning per [mode].
  final List<AsmaName> options;

  /// Index into [options] of the correct answer (the one matching [prompt]).
  final int answerIndex;

  AsmaName get answer => options[answerIndex];

  bool isCorrect(int selectedIndex) => selectedIndex == answerIndex;
}

/// Pure, deterministic generator: same [names] + [seed] always yields the same
/// questions, so the whole quiz is unit-testable without mocking randomness.
///
/// Produces up to [count] questions (capped by how many names are available),
/// each with 4 options — 1 correct + 3 distractors drawn from other names. No
/// option repeats within a question, and no name is used as a prompt twice.
abstract final class AsmaQuizGenerator {
  static const optionCount = 4;

  static List<AsmaQuestion> generate(
    List<AsmaName> names, {
    required int seed,
    int count = 10,
    AsmaQuizMode mode = AsmaQuizMode.nameToMeaning,
  }) {
    // Need at least [optionCount] names to fill the choices.
    if (names.length < optionCount) {
      return const [];
    }
    final rng = _Lcg(seed);
    final prompts = _shuffled(names, rng);
    final questionCount = count < prompts.length ? count : prompts.length;

    return [
      for (var i = 0; i < questionCount; i++)
        _buildQuestion(
          prompt: prompts[i],
          pool: names,
          mode: mode,
          rng: rng,
        ),
    ];
  }

  static AsmaQuestion _buildQuestion({
    required AsmaName prompt,
    required List<AsmaName> pool,
    required AsmaQuizMode mode,
    required _Lcg rng,
  }) {
    // Draw distractors from every other name (by number), deterministically.
    final distractors = _shuffled(
      [for (final n in pool) if (n.number != prompt.number) n],
      rng,
    ).take(optionCount - 1).toList();

    final options = [prompt, ...distractors];
    _shuffleInPlace(options, rng);

    return AsmaQuestion(
      mode: mode,
      prompt: prompt,
      options: options,
      answerIndex: options.indexWhere((n) => n.number == prompt.number),
    );
  }

  static List<AsmaName> _shuffled(List<AsmaName> source, _Lcg rng) {
    final copy = List<AsmaName>.of(source);
    _shuffleInPlace(copy, rng);
    return copy;
  }

  /// Deterministic Fisher–Yates using the supplied generator.
  static void _shuffleInPlace(List<AsmaName> list, _Lcg rng) {
    for (var i = list.length - 1; i > 0; i--) {
      final j = rng.nextInt(i + 1);
      final tmp = list[i];
      list[i] = list[j];
      list[j] = tmp;
    }
  }
}

/// Tiny seeded linear-congruential generator (no `dart:math` Random, so the
/// sequence is fully reproducible across platforms and test runs).
final class _Lcg {
  _Lcg(int seed) : _state = (seed ^ 0x5DEECE66D) & _mask;

  static const _mask = 0xFFFFFFFFFFFF; // 48-bit
  int _state;

  int nextInt(int bound) {
    assert(bound > 0, 'bound must be positive');
    _state = (_state * 0x5DEECE66D + 0xB) & _mask;
    final bits = _state >> 16; // top 32 bits
    return bits % bound;
  }
}