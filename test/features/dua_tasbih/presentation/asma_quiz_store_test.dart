import 'package:flutter_test/flutter_test.dart';
import 'package:productive_muslim/features/dua_tasbih/domain/entities/dua.dart';
import 'package:productive_muslim/features/dua_tasbih/presentation/state/asma_quiz_store.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

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
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  AsmaQuizStore makeStore({int seed = 1, int questionCount = 5}) =>
      AsmaQuizStore(
        SharedPreferencesAsync(),
        seed: () => seed,
        correctHaptic: () {},
        wrongHaptic: () {},
        questionCount: questionCount,
      );

  group('AsmaQuizStore', () {
    test('start builds the configured number of questions', () async {
      final store = makeStore();
      await store.start(_names(99));

      expect(store.questions.value.length, 5);
      expect(store.index.value, 0);
      expect(store.score.value, 0);
      expect(store.selected.value, isNull);
      expect(store.answered.value, isFalse);
      expect(store.finished.value, isFalse);
    });

    test(
      'answering correctly increments score and locks the question',
      () async {
        final store = makeStore();
        await store.start(_names(99));
        final question = store.current.value!;

        store.answer(question.answerIndex);

        expect(store.score.value, 1);
        expect(store.answered.value, isTrue);
        expect(store.selected.value, question.answerIndex);

        // A second tap is ignored once locked.
        store.answer((question.answerIndex + 1) % 4);
        expect(store.score.value, 1);
      },
    );

    test('a wrong answer locks without scoring', () async {
      final store = makeStore();
      await store.start(_names(99));
      final question = store.current.value!;
      final wrong = (question.answerIndex + 1) % 4;

      store.answer(wrong);

      expect(store.score.value, 0);
      expect(store.answered.value, isTrue);
    });

    test('next advances and requires an answer first', () async {
      final store = makeStore(questionCount: 3);
      await store.start(_names(99));

      await store.next(); // no answer yet — no-op
      expect(store.index.value, 0);

      store.answer(store.current.value!.answerIndex);
      await store.next();
      expect(store.index.value, 1);
      expect(store.selected.value, isNull);
    });

    test('finishing records and persists a new best score', () async {
      final store = makeStore(questionCount: 3);
      await store.start(_names(99));

      for (var i = 0; i < 3; i++) {
        store.answer(store.current.value!.answerIndex);
        await store.next();
      }

      expect(store.finished.value, isTrue);
      expect(store.score.value, 3);
      expect(store.best.value, 3);

      // A fresh store on the same prefs restores the best.
      final restored = makeStore();
      await restored.load();
      expect(restored.best.value, 3);
    });

    test('restart re-rolls a fresh question set and resets progress', () async {
      final store = makeStore(questionCount: 4);
      await store.start(_names(99));
      store.answer(store.current.value!.answerIndex);
      await store.next();
      expect(store.index.value, 1);

      store.restart(_names(99));
      expect(store.index.value, 0);
      expect(store.score.value, 0);
      expect(store.selected.value, isNull);
      expect(store.questions.value.length, 4);
    });
  });
}
