import 'package:flutter_test/flutter_test.dart';
import 'package:productive_muslim/core/utils/result.dart';
import 'package:productive_muslim/features/hadith/domain/entities/hadith.dart';
import 'package:productive_muslim/features/hadith/domain/repositories/hadith_repository.dart';
import 'package:productive_muslim/features/hadith/presentation/state/hadith_store.dart';

Hadith _hadith(String id, {String topic = 'character'}) => Hadith(
  id: id,
  topic: topic,
  grade: 'Sahih',
  arabic: 'ar-$id',
  en: 'en-$id',
  bn: 'bn-$id',
  narrator: 'narrator-$id',
  reference: 'ref-$id',
);

final class _FakeHadithRepository implements HadithRepository {
  _FakeHadithRepository(this._items);

  final List<Hadith> _items;
  Set<String> saved = {};
  bool failSave = false;
  bool failRead = false;

  @override
  Future<Result<List<Hadith>>> all() async => Result.success(_items);

  @override
  Future<Result<Set<String>>> favoriteIds() async => failRead
      ? const Result.failure(UnexpectedFailure('prefs'))
      : Result.success(saved);

  @override
  Future<Result<void>> setFavoriteIds(Set<String> ids) async {
    if (failSave) {
      return const Result.failure(UnexpectedFailure('disk full'));
    }
    saved = ids;
    return const Result.success(null);
  }
}

void main() {
  HadithStore storeWith(List<Hadith> items) =>
      HadithStore(_FakeHadithRepository(items));

  group('HadithStore.load', () {
    test('populates items and marks loaded', () async {
      final store = storeWith([_hadith('h001'), _hadith('h002')]);

      expect(store.loaded.value, isFalse);
      await store.load();

      expect(store.loaded.value, isTrue);
      expect(store.items.value, hasLength(2));
    });
  });

  group('HadithStore favorites', () {
    test('toggle persists, and load restores them', () async {
      final repo = _FakeHadithRepository([_hadith('h001')]);
      final store = HadithStore(repo);
      await store.load();

      expect(await store.toggleFavorite('h001'), isTrue);
      expect(store.favorites.value, {'h001'});
      expect(repo.saved, {'h001'});

      final restored = HadithStore(repo);
      await restored.load();
      expect(restored.favorites.value, {'h001'});

      expect(await store.toggleFavorite('h001'), isTrue);
      expect(repo.saved, isEmpty);
    });

    test('a failed save takes the tap back', () async {
      final repo = _FakeHadithRepository([_hadith('h001')])..failSave = true;
      final store = HadithStore(repo);
      await store.load();

      expect(await store.toggleFavorite('h001'), isFalse);
      expect(store.favorites.value, isEmpty);
    });

    test('a failed favorites read refuses toggles instead of wiping', () async {
      final repo = _FakeHadithRepository([_hadith('h001'), _hadith('h002')])
        ..saved = {'h002'}
        ..failRead = true;
      final store = HadithStore(repo);
      await store.load();

      expect(store.items.value, hasLength(2));
      expect(await store.toggleFavorite('h001'), isFalse);
      expect(repo.saved, {'h002'});
      expect(store.favorites.value, isEmpty);

      // Once the read recovers, the toggle merges into the saved set.
      repo.failRead = false;
      expect(await store.toggleFavorite('h001'), isTrue);
      expect(repo.saved, {'h001', 'h002'});
      expect(store.favorites.value, {'h001', 'h002'});
    });
  });

  group('HadithStore.topics', () {
    test('groups items by topic in first-seen order', () async {
      final store = storeWith([
        _hadith('h001', topic: 'faith'),
        _hadith('h002', topic: 'knowledge'),
        _hadith('h003', topic: 'faith'),
      ]);
      await store.load();

      final topics = store.topics.value;
      expect(topics.map((t) => t.id).toList(), <String>['faith', 'knowledge']);
      expect(topics.first.items, hasLength(2));
      expect(topics.last.items, hasLength(1));
    });

    test('is empty before load', () {
      final store = storeWith([_hadith('h001')]);
      expect(store.topics.value, isEmpty);
    });
  });

  group('HadithStore.ofDay', () {
    test('returns null when the collection is empty', () {
      final store = storeWith(const []);
      expect(store.ofDay(DateTime(2026, 6, 14)), isNull);
    });

    test('is stable for the same date across repeated calls', () async {
      final store = storeWith([for (var i = 0; i < 5; i++) _hadith('h$i')]);
      await store.load();

      final date = DateTime(2026, 6, 14);
      final first = store.ofDay(date);
      final second = store.ofDay(date);

      expect(first, isNotNull);
      expect(identical(first, second), isTrue);
    });

    test('advances one per day, without resetting on January 1st', () {
      final items = [for (var i = 0; i < 5; i++) _hadith('h$i')];
      final store = storeWith(items)..items.value = items;

      final dec31 = items.indexOf(store.ofDay(DateTime(2026, 12, 31))!);
      expect(store.ofDay(DateTime(2027)), items[(dec31 + 1) % 5]);
      expect(store.ofDay(DateTime(2027, 1, 2)), items[(dec31 + 2) % 5]);
    });

    test('different days can map to different hadith', () async {
      final items = [for (var i = 0; i < 7; i++) _hadith('h$i')];
      final store = storeWith(items)..items.value = items;

      expect(
        store.ofDay(DateTime(2026)),
        isNot(store.ofDay(DateTime(2026, 1, 2))),
      );
    });
  });
}
