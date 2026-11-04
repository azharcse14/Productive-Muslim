import 'package:flutter_test/flutter_test.dart';
import 'package:productive_muslim/core/settings/settings_store.dart';
import 'package:productive_muslim/core/utils/hijri_date.dart';
import 'package:productive_muslim/core/utils/result.dart';
import 'package:productive_muslim/core/utils/wall_time.dart';
import 'package:productive_muslim/features/my_mosque/domain/entities/jamaat_config.dart';
import 'package:productive_muslim/features/notifications/domain/entities/notification_item.dart';
import 'package:productive_muslim/features/notifications/domain/usecases/build_notification_plan.dart';
import 'package:productive_muslim/features/prayer_times/data/repositories/prayer_day_repository_impl.dart';
import 'package:productive_muslim/features/prayer_times/domain/entities/prayer_day.dart';
import 'package:productive_muslim/features/prayer_times/domain/usecases/get_prayer_day.dart';
import 'package:productive_muslim/features/prayer_times/presentation/state/home_store.dart';
import 'package:productive_muslim/features/settings/data/datasources/timezone_clock.dart';
import 'package:productive_muslim/features/settings/domain/entities/app_settings.dart';
import 'package:productive_muslim/features/settings/domain/entities/city.dart';
import 'package:productive_muslim/features/settings/domain/entities/location_config.dart';
import 'package:productive_muslim/features/settings/domain/entities/notification_matrix.dart';
import 'package:productive_muslim/features/settings/domain/repositories/settings_repository.dart';
import 'package:productive_muslim/features/settings/domain/repositories/zoned_clock.dart';
import 'package:productive_muslim/features/settings/domain/usecases/get_settings.dart';
import 'package:productive_muslim/features/settings/domain/usecases/save_settings.dart';

import '../../helpers/mosque_fakes.dart';

/// Consumers outside the Ramadan feature follow the "Eid announced after
/// 29 days" override through [HijriDate]. Tabular Ramadan 1447 runs
/// 18 Feb – 19 Mar 2026, so 18 Mar is the 29th and 19 Mar the 30th.

final class _Repo implements SettingsRepository {
  _Repo(this.stored);

  AppSettings stored;

  @override
  Future<Result<AppSettings>> load() async => Result.success(stored);

  @override
  Future<Result<void>> save(AppSettings settings) async {
    stored = settings;
    return const Result.success(null);
  }
}

final class _FixedClock implements ZonedClock {
  _FixedClock(this.now);

  final DateTime now;
  final _real = TimezoneClock();

  @override
  DateTime nowAt(LocationConfig location) => now.floating;

  @override
  DateTime instantAt(LocationConfig location, DateTime instant) =>
      _real.instantAt(location, instant);

  @override
  DateTime utcInstantOf(LocationConfig location, DateTime wall) =>
      _real.utcInstantOf(location, wall);
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

PrayerDay _day(int day) => PrayerDay(
  ishaYesterday: DateTime(2026, 3, day - 1, 20, 15),
  fajr: DateTime(2026, 3, day, 3, 45),
  sunrise: DateTime(2026, 3, day, 5, 10),
  dhuhr: DateTime(2026, 3, day, 12),
  asr: DateTime(2026, 3, day, 16, 30),
  maghrib: DateTime(2026, 3, day, 18, 45),
  isha: DateTime(2026, 3, day, 20, 15),
  fajrTomorrow: DateTime(2026, 3, day + 1, 3, 45),
);

void main() {
  setUpAll(TimezoneClock.initialize);
  setUp(() => HijriDate.shortRamadanYears = () => const {1447});
  tearDown(() => HijriDate.shortRamadanYears = () => const {});

  test('notification plan: no sahri/iftar on the tabular 30th, still on '
      'the 29th', () {
    List<NotificationItem> ramadanItems(int day) =>
        buildNotificationPlan(
              from: DateTime(2026, 3, day),
              days: [_day(day)],
              matrix: const NotificationMatrix(),
              jamaat: JamaatConfig.none,
            )
            .where(
              (i) =>
                  i.kind == NotificationKind.sahriWarning ||
                  i.kind == NotificationKind.iftar,
            )
            .toList();

    expect(ramadanItems(18), hasLength(2));
    expect(ramadanItems(19), isEmpty);
  });

  test('home: Ramadan mode is off on the tabular 30th (Eid)', () async {
    final settings = SettingsStore(
      GetSettings(_Repo(const AppSettings(location: _dhaka))),
      SaveSettings(_Repo(const AppSettings())),
    );
    await settings.load();
    final (mosque, _) = await makeMosqueStore();
    final store = HomeStore(
      getPrayerDay: GetPrayerDay(PrayerDayRepositoryImpl(TimezoneClock())),
      clock: _FixedClock(DateTime(2026, 3, 19, 3)),
      settings: settings,
      mosque: mosque,
    );
    expect(store.hijriDate.value, const HijriDate(1447, 10, 1));
    expect(store.ramadanMode.value, isFalse);
    store.dispose();
  });
}
