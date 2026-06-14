import 'package:flutter_test/flutter_test.dart';
import 'package:qalbee/core/utils/result.dart';
import 'package:qalbee/features/hadith/domain/entities/hadith.dart';
import 'package:qalbee/features/hadith/domain/repositories/hadith_repository.dart';
import 'package:qalbee/features/hadith/presentation/state/hadith_store.dart';

Hadith _hadith(String id) => Hadith(
      id: id,
      arabic: 'ar-$id',
      en: 'en-$id',
      bn: 'bn-$id',
      narrator: 'narrator-$id',
      reference: 'ref-$id',
    );

final class _FakeHadithRepository implements HadithRepository {
  _FakeHadithRepository(this._items);

  final List<Hadith> _items;

  @override
  Future<Result<List<Hadith>>> all() async => Result.success(_items);
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

    test('selects by day-of-year modulo the list length', () async {
      final items = [for (var i = 0; i < 5; i++) _hadith('h$i')];
      final store = storeWith(items)..items.value = items;

      // 1 Jan -> dayOfYear 0 -> index 0.
      expect(store.ofDay(DateTime(2026)), items[0]);
      // 3 Jan -> dayOfYear 2 -> index 2.
      expect(store.ofDay(DateTime(2026, 1, 3)), items[2]);
    });

    test('wraps with modulo when day-of-year exceeds the list length',
        () async {
      final items = [for (var i = 0; i < 5; i++) _hadith('h$i')];
      final store = storeWith(items)..items.value = items;

      // 6 Jan -> dayOfYear 5 -> 5 % 5 == 0 -> index 0.
      expect(store.ofDay(DateTime(2026, 1, 6)), items[0]);
      // 7 Jan -> dayOfYear 6 -> 6 % 5 == 1 -> index 1.
      expect(store.ofDay(DateTime(2026, 1, 7)), items[1]);
    });

    test('different days can map to different hadith', () async {
      final items = [for (var i = 0; i < 7; i++) _hadith('h$i')];
      final store = storeWith(items)..items.value = items;

      expect(store.ofDay(DateTime(2026)), isNot(store.ofDay(DateTime(2026, 1, 2))));
    });
  });
}
