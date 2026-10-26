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
    test('toggle adds then removes a date, and persists across loads',
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