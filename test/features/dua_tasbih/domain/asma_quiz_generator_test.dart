import 'package:flutter_test/flutter_test.dart';
import 'package:productive_muslim/features/dua_tasbih/domain/entities/asma_quiz.dart';
import 'package:productive_muslim/features/dua_tasbih/domain/entities/dua.dart';

List<AsmaName> _names(int count) => [
  for (var n = 1; n <= count; n++)
    AsmaName(
      number: n,
      arabic: 'اسم $n',
      transliteration: 'Name $n',
      meaningEn: 'Meaning $n',
      meaningBn: '',
    ),
];

void main() {
  group('AsmaQuizGenerator', () {
    test('never shows two options with the same text', () {
      // Two "Al-Majid"s (#48 and #65 in the bundled list).
      final names = [
        for (final n in _names(4))
          n.number == 2
              ? AsmaName(
                  number: 2,
                  arabic: n.arabic,
                  transliteration: 'Name 1',
                  meaningEn: n.meaningEn,
                  meaningBn: '',
                )
              : n,
        ..._names(6).skip(4),
      ];
      for (var seed = 0; seed < 50; seed++) {
        for (final q in AsmaQuizGenerator.generate(
          names,
          seed: seed,
          mode: AsmaQuizMode.meaningToName,
        )) {
          final labels = q.options.map((o) => o.transliteration).toList();
          expect(labels.toSet().length, labels.length);
        }
      }
    });

    test('is deterministic for the same seed', () {
      final names = _names(99);
      final a = AsmaQuizGenerator.generate(names, seed: 42);
      final b = AsmaQuizGenerator.generate(names, seed: 42);

      expect(a.length, b.length);
      for (var i = 0; i < a.length; i++) {
        expect(a[i].prompt.number, b[i].prompt.number);
        expect(
          a[i].options.map((o) => o.number),
          b[i].options.map((o) => o.number),
        );
        expect(a[i].answerIndex, b[i].answerIndex);
      }
    });

    test('different seeds usually produce different prompt order', () {
      final names = _names(99);
      final a = AsmaQuizGenerator.generate(names, seed: 1);
      final b = AsmaQuizGenerator.generate(names, seed: 2);

      final orderA = a.map((q) => q.prompt.number).toList();
      final orderB = b.map((q) => q.prompt.number).toList();
      expect(orderA, isNot(equals(orderB)));
    });

    test('every question has 4 distinct options with the answer present', () {
      final questions = AsmaQuizGenerator.generate(
        _names(99),
        seed: 7,
        count: 20,
      );

      for (final question in questions) {
        expect(question.options.length, 4);
        final numbers = question.options.map((o) => o.number).toSet();
        expect(numbers.length, 4, reason: 'options must be distinct');
        expect(
          question.options[question.answerIndex].number,
          question.prompt.number,
        );
        expect(question.answer.number, question.prompt.number);
        expect(question.isCorrect(question.answerIndex), isTrue);
      }
    });

    test('no prompt repeats within a run', () {
      final questions = AsmaQuizGenerator.generate(
        _names(99),
        seed: 99,
        count: 30,
      );
      final prompts = questions.map((q) => q.prompt.number).toList();
      expect(prompts.toSet().length, prompts.length);
    });

    test('count is capped by the number of names available', () {
      final questions = AsmaQuizGenerator.generate(_names(6), seed: 3);
      expect(questions.length, 6);
    });

    test('returns empty when fewer than 4 names are available', () {
      expect(AsmaQuizGenerator.generate(_names(3), seed: 1), isEmpty);
    });

    test('both modes are carried onto every question', () {
      final toMeaning = AsmaQuizGenerator.generate(_names(20), seed: 5);
      final toName = AsmaQuizGenerator.generate(
        _names(20),
        seed: 5,
        mode: AsmaQuizMode.meaningToName,
      );

      expect(
        toMeaning.every((q) => q.mode == AsmaQuizMode.nameToMeaning),
        isTrue,
      );
      expect(toName.every((q) => q.mode == AsmaQuizMode.meaningToName), isTrue);
    });
  });
}
