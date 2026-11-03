import 'package:flutter_test/flutter_test.dart';
import 'package:productive_muslim/features/ramadan/data/datasources/eid_announcement_local_data_source.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  test('save → load, undo → empty', () async {
    final source = EidAnnouncementLocalDataSource(SharedPreferencesAsync());
    expect(await source.load(), isEmpty);
    await source.save(1447, ended: true);
    expect(await source.load(), {1447});
    await source.save(1447, ended: false);
    expect(await source.load(), isEmpty);
  });

  test('ignores foreign and malformed keys', () async {
    final prefs = SharedPreferencesAsync();
    await prefs.setBool('ramadan_ended_29_abc', true);
    await prefs.setBool('ramadan_ended_29_', true);
    await prefs.setString('fasting_log_v1', '1447');
    await prefs.setBool('ramadan_ended_29_1446', true);
    expect(await EidAnnouncementLocalDataSource(prefs).load(), {1446});
  });
}
