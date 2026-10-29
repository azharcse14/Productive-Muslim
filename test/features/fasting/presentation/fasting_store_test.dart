import 'package:flutter_test/flutter_test.dart';
import 'package:productive_muslim/features/fasting/presentation/state/fasting_store.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // A Monday so "today" carries a recommended fast.
  DateTime now = DateTime(2026, 6, 15, 10);

  FastingStore store() =>
      FastingStore(SharedPreferencesAsync(), now: () => now);

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    now = DateTime(2026, 6, 15, 10);
  });

  group('FastingStore — log toggle & persistence', () {
    test(
      'toggle adds then removes a date, and persists across loads',
      () async {
        final s = store();
        await s.load();
        final day = DateTime(2026, 6, 15);
        expect(s.isLogged(day), isFalse);

        await s.toggle(day);
        expect(s.isLogged(day), isTrue);

        final fresh = store();
        await fresh.load();
        expect(fresh.isLogged(day), isTrue);

        await s.toggle(day);
        expect(s.isLogged(day), isFalse);
      },
    );

    test('a failed write puts the log back and rethrows', () async {
      SharedPreferencesAsyncPlatform.instance = _FailingPrefs();
      final s = store();
      await s.load();
      final day = DateTime(2026, 6, 15);
      await expectLater(s.toggle(day), throwsStateError);
      expect(s.isLogged(day), isFalse);
    });

    test('logging ignores time-of-day', () async {
      final s = store();
      await s.load();
      await s.toggle(DateTime(2026, 6, 15, 23, 59));
      expect(s.isLogged(DateTime(2026, 6, 15)), isTrue);
    });

    test('future and forbidden days cannot be logged', () async {
      final s = store();
      await s.load();
      await s.toggle(DateTime(2026, 6, 16)); // tomorrow
      expect(s.isLogged(DateTime(2026, 6, 16)), isFalse);
      // Eid al-Adha 1447 (tabular) — in the past relative to `now`.
      await s.toggle(DateTime(2026, 5, 27));
      expect(s.isLogged(DateTime(2026, 5, 27)), isFalse);
      expect(s.isForbidden(DateTime(2026, 5, 27)), isTrue);
    });
  });

  group('FastingStore — stats', () {
    test('total, this-month and this-hijri-month counts', () async {
      final s = store();
      await s.load();
      await s.toggle(DateTime(2026, 6, 15)); // this Gregorian + hijri month
      await s.toggle(DateTime(2026, 6, 11)); // same month
      await s.toggle(DateTime(2026, 1, 5)); // a different month

      final stats = s.stats();
      expect(stats.total, 3);
      expect(stats.thisMonth, 2);
      expect(stats.thisHijriMonth, greaterThanOrEqualTo(1));
    });
  });

  group('FastingStore — qaza', () {
    test(
      'qaza days persist, leave the nafl total, and unlog cleanly',
      () async {
        final s = store();
        await s.load();
        await s.toggle(DateTime(2026, 6, 11), asQaza: true);
        await s.toggle(DateTime(2026, 6, 12));
        // ~12 Ramadan 1447: a Ramadan fast, never qaza, not nafl either.
        await s.toggle(DateTime(2026, 3, 2), asQaza: true);
        expect(s.isQaza(DateTime(2026, 6, 11)), isTrue);
        expect(s.isQaza(DateTime(2026, 3, 2)), isFalse);
        expect(s.stats().total, 1, reason: 'only Jun 12 is nafl');

        await s.setQazaOwed(5);
        final fresh = store();
        await fresh.load();
        expect(fresh.qaza.value, {20260611});
        expect(fresh.qazaOwed.value, 5);
        // Old logs (no qaza key) read as nafl; achievements see every fast.
        expect(fresh.logged.value, hasLength(3));

        await fresh.toggle(DateTime(2026, 6, 11));
        expect(fresh.isLogged(DateTime(2026, 6, 11)), isFalse);
        expect(fresh.qaza.value, isEmpty);
        await fresh.setQazaOwed(0);
        expect(fresh.qazaOwed.value, isNull);
      },
    );

    test('heatmapDate maps cells to days of the month', () {
      final s = store();
      // June 2026 starts on a Monday: one Sunday pad cell.
      expect(s.heatmapDate(0, 0), isNull);
      expect(s.heatmapDate(0, 1), DateTime(2026, 6));
      expect(s.heatmapDate(4, 2), DateTime(2026, 6, 30));
      expect(s.heatmapDate(4, 3), isNull);
    });
  });

  group('FastingStore — recommended passthrough', () {
    test('today (a Monday) is recommended', () {
      final s = store();
      expect(s.recommendedOn(s.today), isNotEmpty);
    });

    test('upcoming returns the requested number of days', () {
      final s = store();
      expect(s.upcoming(count: 4), hasLength(4));
    });
  });

  group('FastingStore — month heatmap', () {
    test('every row has 7 cells and a logged day reads level 4', () async {
      final s = store();
      await s.load();
      await s.toggle(DateTime(2026, 6, 15));
      final weeks = s.monthHeatmap();
      expect(weeks, isNotEmpty);
      for (final week in weeks) {
        expect(week, hasLength(7));
      }
      expect(weeks.expand((w) => w), contains(4));
    });
  });
}

base class _FailingPrefs extends InMemorySharedPreferencesAsync {
  _FailingPrefs() : super.empty();

  @override
  Future<bool> setStringList(
    String key,
    List<String> value,
    SharedPreferencesOptions options,
  ) async => throw StateError('disk full');
}
