import 'package:flutter_test/flutter_test.dart';
import 'package:productive_muslim/features/my_mosque/data/datasources/mosque_local_data_source.dart';
import 'package:productive_muslim/features/my_mosque/domain/entities/jamaat_config.dart';
import 'package:productive_muslim/features/my_mosque/domain/entities/mosque_profile.dart';
import 'package:productive_muslim/features/my_mosque/domain/entities/mosque_state.dart';
import 'package:productive_muslim/features/settings/domain/entities/prayer_params.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  group('MosqueLocalDataSource', () {
    test('returns defaults when nothing is stored', () async {
      final source = MosqueLocalDataSource(SharedPreferencesAsync());
      expect(await source.read(), const MosqueState());
    });

    test('write → read round-trips', () async {
      final source = MosqueLocalDataSource(SharedPreferencesAsync());
      const state = MosqueState(
        profiles: [
          MosqueProfile(
            id: 'home',
            name: 'Home Mosque',
            entries: {
              Prayer.fajr: FixedJamaat(ClockTime(5, 45)),
              Prayer.maghrib: OffsetJamaat(Duration(minutes: 5)),
              Prayer.isha: NoJamaat(),
            },
          ),
        ],
        activeId: 'home',
      );
      await source.write(state);
      expect(await source.read(), state);
    });

    for (final raw in ['{"profiles": ', '[1]', '"x"']) {
      test('unreadable payload $raw is quarantined before a save', () async {
        final prefs = SharedPreferencesAsync();
        await prefs.setString('mosque_state_v1', raw);
        final source = MosqueLocalDataSource(prefs);
        expect(await source.read(), const MosqueState());
        await source.write(const MosqueState());
        expect(await prefs.getString(MosqueLocalDataSource.unreadableKey), raw);
      });
    }
  });
}
