import 'package:flutter_test/flutter_test.dart';
import 'package:productive_muslim/core/utils/result.dart';
import 'package:productive_muslim/features/daily_content/domain/usecases/pick_daily_content.dart';
import 'package:productive_muslim/features/daily_content/presentation/state/daily_content_store.dart';
import 'package:productive_muslim/features/dua_tasbih/domain/entities/dua.dart';
import 'package:productive_muslim/features/dua_tasbih/domain/repositories/dua_repository.dart';
import 'package:productive_muslim/features/dua_tasbih/presentation/state/dua_store.dart';

Dua _dua(String id) => Dua(
  id: id,
  arabic: 'ar',
  transliteration: 'tr',
  translationEn: 'en',
  translationBn: 'bn',
  reference: 'ref',
  repeat: 1,
);

/// Two categories, five duas total — enough for the pick to rotate.
final class _FakeDuaRepository implements DuaRepository {
  _FakeDuaRepository({this.empty = false, this.failFirst = false});

  final bool empty;
  bool failFirst;
  int calls = 0;

  @override
  Future<Result<List<DuaCategory>>> categories() async {
    calls++;
    if (failFirst) {
      failFirst = false;
      return const Result.failure(UnexpectedFailure('boom'));
    }
    if (empty) {
      return const Result.success([]);
    }
    return Result.success([
      DuaCategory(id: 'a', icon: 'sun', duas: [_dua('a1'), _dua('a2')]),
      DuaCategory(
        id: 'b',
        icon: 'moon',
        duas: [_dua('b1'), _dua('b2'), _dua('b3')],
      ),
    ]);
  }

  @override
  Future<Result<List<AsmaName>>> asmaulHusna() async =>
      const Result.success([]);
}

const _order = ['a1', 'a2', 'b1', 'b2', 'b3'];

String _expectedFor(DateTime date) => _order[(dailySeed(date) + 7) % 5];

void main() {
  group('DailyContentStore', () {
    test('picks from the flattened pool, deterministically per day', () async {
      final store = DailyContentStore(DuaStore(_FakeDuaRepository()));
      final day = DateTime(2026, 6, 14);
      await store.load(day);

      expect(store.duaOfDay.value?.id, _expectedFor(day));

      // A second store for the same day agrees.
      final other = DailyContentStore(DuaStore(_FakeDuaRepository()));
      await other.load(day);
      expect(other.duaOfDay.value?.id, store.duaOfDay.value?.id);
    });

    test('time of day is ignored; date is normalised to midnight', () async {
      final store = DailyContentStore(DuaStore(_FakeDuaRepository()));
      await store.load(DateTime(2026, 6, 14, 0, 1));
      final morning = store.duaOfDay.value?.id;

      await store.load(DateTime(2026, 6, 14, 23, 59, 59));
      expect(store.date.value, DateTime(2026, 6, 14));
      expect(store.duaOfDay.value?.id, morning);
    });

    test('rolls over to the next dua at midnight and wraps around', () async {
      final store = DailyContentStore(DuaStore(_FakeDuaRepository()));
      final start = DateTime(2026, 12, 29);
      await store.load(start);
      final startIndex = _order.indexOf(store.duaOfDay.value!.id);

      // Crosses a year boundary too: the rotation must not reset on Jan 1.
      for (var i = 1; i <= 6; i++) {
        await store.load(DateTime(2026, 12, 29 + i));
        expect(
          store.duaOfDay.value?.id,
          _order[(startIndex + i) % 5],
          reason: 'day +$i',
        );
      }
    });

    test('loads the dua collection only once', () async {
      final repo = _FakeDuaRepository();
      final store = DailyContentStore(DuaStore(repo));
      await store.load(DateTime(2026, 6, 14));
      await store.load(DateTime(2026, 6, 15));
      expect(repo.calls, 1);
    });

    test('concurrent loads share one decode', () async {
      final repo = _FakeDuaRepository();
      final dua = DuaStore(repo);
      await Future.wait([
        dua.load(),
        DailyContentStore(dua).load(DateTime(2026, 6, 14)),
      ]);
      expect(repo.calls, 1);
    });

    test('a failed load is retried on the next call', () async {
      final repo = _FakeDuaRepository(failFirst: true);
      final store = DailyContentStore(DuaStore(repo));
      await store.load(DateTime(2026, 6, 14));
      expect(store.duaOfDay.value, isNull);

      await store.load(DateTime(2026, 6, 14));
      expect(store.duaOfDay.value, isNotNull);
      expect(repo.calls, 2);
    });

    test('empty collection yields no dua of the day', () async {
      final store = DailyContentStore(
        DuaStore(_FakeDuaRepository(empty: true)),
      );
      await store.load(DateTime(2026, 6, 14));
      expect(store.duaOfDay.value, isNull);
    });
  });
}
