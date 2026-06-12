import 'package:flutter_test/flutter_test.dart';
import 'package:qalbee/features/dua_tasbih/presentation/state/tasbih_store.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  var taps = 0;
  var milestones = 0;
  DateTime now = DateTime(2026, 6, 13, 10);

  TasbihStore store() => TasbihStore(
        SharedPreferencesAsync(),
        haptic: () => taps++,
        milestoneHaptic: () => milestones++,
        now: () => now,
      );

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    taps = 0;
    milestones = 0;
    now = DateTime(2026, 6, 13, 10);
  });

  group('TasbihStore', () {
    test('tap increments with haptic; milestone fires once at target',
        () async {
      final s = store();
      await s.load();
      s.setTarget(3);
      s
        ..tap()
        ..tap();
      expect(s.count.value, 2);
      expect(taps, 2);
      expect(milestones, 0);
      s.tap();
      expect(milestones, 1);
      s.tap(); // beyond target — no repeat milestone
      expect(milestones, 1);
    });

    test('reset saves the round into today\'s total and persists',
        () async {
      final s = store();
      await s.load();
      for (var i = 0; i < 5; i++) {
        s.tap();
      }
      await s.reset(saveToHistory: true);
      expect(s.count.value, 0);
      expect(s.totalToday.value, 5);
      final fresh = store();
      await fresh.load();
      expect(fresh.totalToday.value, 5);
    });

    test('date rollover clears today\'s total', () async {
      final s = store();
      await s.load();
      s.tap();
      await s.reset(saveToHistory: true);
      expect(s.totalToday.value, 1);
      now = DateTime(2026, 6, 14, 10);
      final fresh = store();
      await fresh.load();
      expect(fresh.totalToday.value, 0);
    });
  });
}
