import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:productive_muslim/features/home_widget/data/prayer_widget_service.dart';
import 'package:productive_muslim/features/my_mosque/domain/entities/jamaat_config.dart';
import 'package:productive_muslim/features/my_mosque/domain/entities/mosque_profile.dart';
import 'package:productive_muslim/features/my_mosque/domain/entities/mosque_schedule.dart';
import 'package:productive_muslim/features/my_mosque/domain/entities/mosque_state.dart';
import 'package:productive_muslim/features/prayer_times/data/repositories/prayer_day_repository_impl.dart';
import 'package:productive_muslim/features/prayer_times/domain/usecases/get_prayer_day.dart';
import 'package:productive_muslim/features/settings/data/datasources/timezone_clock.dart';
import 'package:productive_muslim/features/settings/domain/entities/app_settings.dart';
import 'package:productive_muslim/features/settings/domain/entities/city.dart';
import 'package:productive_muslim/features/settings/domain/entities/location_config.dart';
import 'package:productive_muslim/features/settings/domain/repositories/zoned_clock.dart';

import '../../helpers/mosque_fakes.dart';
import '../../helpers/settings_fakes.dart';

final class _FixedClock implements ZonedClock {
  _FixedClock(this.now);

  final DateTime now;
  final real = TimezoneClock();

  @override
  DateTime nowAt(LocationConfig location) => now;

  @override
  DateTime instantAt(LocationConfig location, DateTime instant) =>
      real.instantAt(location, instant);

  @override
  DateTime utcInstantOf(LocationConfig location, DateTime wall) =>
      real.utcInstantOf(location, wall);
}

const _dhaka = ManualCityLocation(
  City(
    name: 'Dhaka',
    countryCode: 'BD',
    latitude: 23.7104,
    longitude: 90.4074,
    timezone: 'Asia/Dhaka',
  ),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    TimezoneClock.initialize();
    await initializeDateFormatting('en');
  });

  test("Jumu'ah follows the mosque active on Friday, not today's", () async {
    const channel = MethodChannel('com.productivemuslim.app/widget');
    Map<Object?, Object?>? pushed;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          pushed = call.arguments as Map<Object?, Object?>;
          return null;
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null),
    );

    // Default mosque has a Jumu'ah time; on Fridays the schedule switches
    // to one without.
    final (mosque, _) = await makeMosqueStore(
      const MosqueState(
        profiles: [
          MosqueProfile(id: 'a', name: 'A', jumuah: ClockTime(13, 30)),
          MosqueProfile(id: 'b', name: 'B'),
        ],
        mode: ScheduleMode.auto,
        defaultId: 'a',
        rules: [
          MosqueRule(
            mosqueId: 'b',
            start: ClockTime(0, 0),
            end: ClockTime(0, 0),
            days: {DateTime.friday},
          ),
        ],
      ),
    );
    final clock = _FixedClock(DateTime(2026, 6, 11, 10)); // a Thursday
    final service = PrayerWidgetService(
      getPrayerDay: GetPrayerDay(PrayerDayRepositoryImpl(clock)),
      clock: clock,
      settings: await makeSettingsStore(const AppSettings(location: _dhaka)),
      mosque: mosque,
    );

    await service.update();
    expect(pushed!['widget_strips'], isNot(contains("Jumu'ah")));
  });
}
