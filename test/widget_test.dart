import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:qalbee/core/utils/result.dart';
import 'package:qalbee/features/muhasaba/presentation/state/muhasaba_store.dart';
import 'package:qalbee/features/my_mosque/presentation/state/mosque_store.dart';
import 'package:qalbee/features/prayer_times/data/repositories/prayer_day_repository_impl.dart';
import 'package:qalbee/features/prayer_times/domain/usecases/get_prayer_day.dart';
import 'package:qalbee/features/prayer_times/presentation/state/home_store.dart';
import 'package:qalbee/features/settings/data/datasources/timezone_clock.dart';
import 'package:qalbee/features/settings/domain/entities/app_settings.dart';
import 'package:qalbee/features/settings/domain/repositories/settings_repository.dart';
import 'package:qalbee/features/settings/domain/usecases/get_settings.dart';
import 'package:qalbee/features/settings/domain/usecases/save_settings.dart';
import 'package:qalbee/features/settings/presentation/state/settings_store.dart';
import 'package:qalbee/main.dart';

import 'helpers/mosque_fakes.dart';
import 'helpers/muhasaba_fakes.dart';

final class _InMemoryRepo implements SettingsRepository {
  AppSettings stored = const AppSettings();

  @override
  Future<Result<AppSettings>> load() async => Result.success(stored);

  @override
  Future<Result<void>> save(AppSettings settings) async {
    stored = settings;
    return const Result.success(null);
  }
}

void main() {
  tearDown(() => GetIt.I.reset());

  testWidgets('app boots to the shell with bottom navigation', (tester) async {
    TimezoneClock.initialize();
    final settings =
        SettingsStore(GetSettings(_InMemoryRepo()), SaveSettings(_InMemoryRepo()));
    await settings.load();
    final clock = TimezoneClock();
    final (mosqueStore, _) = await makeMosqueStore();
    final (muhasabaStore, _) = await makeMuhasabaStore();
    GetIt.I
      ..registerSingleton<SettingsStore>(settings)
      ..registerSingleton<MosqueStore>(mosqueStore)
      ..registerSingleton<MuhasabaStore>(muhasabaStore)
      ..registerFactory<HomeStore>(
        () => HomeStore(
          getPrayerDay: GetPrayerDay(PrayerDayRepositoryImpl(clock)),
          clock: clock,
          settings: settings,
          mosque: mosqueStore,
        ),
      );
    await tester.pumpWidget(const QalbeeApp());
    await tester.pumpAndSettle();
    expect(find.text('Quran'), findsOneWidget);
    expect(find.text('Muhasaba'), findsOneWidget);
  });
}
