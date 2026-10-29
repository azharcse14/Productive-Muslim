import 'package:flutter_test/flutter_test.dart';
import 'package:productive_muslim/features/health/presentation/state/health_store.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  final now = DateTime(2026, 10, 29, 9);

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  HealthStore store() => HealthStore(SharedPreferencesAsync(), now: () => now);

  test('logs, edits, removes and persists weight newest first', () async {
    final s = store();
    expect(await s.setWeight(DateTime(2026, 10, 20), 70.04), isTrue);
    expect(await s.setWeight(now, 69.5), isTrue);
    expect(s.history, [
      (DateTime(2026, 10, 29), 69.5),
      (DateTime(2026, 10, 20), 70.0),
    ]);

    final reloaded = store();
    await reloaded.load();
    expect(reloaded.history.length, 2);

    await reloaded.setWeight(now, null);
    expect(reloaded.history, [(DateTime(2026, 10, 20), 70.0)]);
  });

  test('rejects future dates and implausible weights', () async {
    final s = store();
    expect(await s.setWeight(DateTime(2026, 10, 30), 70), isFalse);
    expect(await s.setWeight(now, 0.5), isFalse);
    expect(await s.setWeight(now, 900), isFalse);
    expect(await s.setWeight(now, double.nan), isFalse);
    expect(s.history, isEmpty);
  });
}
