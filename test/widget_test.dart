import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:productive_muslim/core/utils/result.dart';
import 'package:productive_muslim/features/dua_tasbih/presentation/state/dua_store.dart';
import 'package:productive_muslim/features/dua_tasbih/presentation/state/tasbih_store.dart';
import 'package:productive_muslim/features/muhasaba/presentation/state/muhasaba_store.dart';
import 'package:productive_muslim/features/my_mosque/presentation/state/mosque_store.dart';
import 'package:productive_muslim/features/onboarding/presentation/state/app_lock_store.dart';
import 'package:productive_muslim/features/prayer_times/data/repositories/prayer_day_repository_impl.dart';
import 'package:productive_muslim/features/prayer_times/domain/usecases/get_prayer_day.dart';
import 'package:productive_muslim/features/prayer_times/presentation/state/home_store.dart';
import 'package:productive_muslim/features/quran/presentation/state/quran_store.dart';
import 'package:productive_muslim/features/settings/data/datasources/timezone_clock.dart';
import 'package:productive_muslim/features/settings/domain/entities/app_settings.dart';
import 'package:productive_muslim/features/settings/domain/repositories/settings_repository.dart';
import 'package:productive_muslim/features/settings/domain/usecases/get_settings.dart';
import 'package:productive_muslim/features/settings/domain/usecases/save_settings.dart';
import 'package:productive_muslim/features/settings/presentation/state/settings_store.dart';
import 'package:productive_muslim/main.dart';

import 'helpers/content_fakes.dart';
import 'helpers/home_store_fakes.dart';
import 'helpers/lock_fakes.dart';
import 'helpers/mosque_fakes.dart';
import 'helpers/muhasaba_fakes.dart';

final class _InMemoryRepo implements SettingsRepository {
  AppSettings stored = const AppSettings(setupComplete: true);

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

  testHomeWidgets('app boots to the shell with bottom navigation', (tester) async {
    TimezoneClock.initialize();
    final settings =
        SettingsStore(GetSettings(_InMemoryRepo()), SaveSettings(_InMemoryRepo()));
    await settings.load();
    final clock = TimezoneClock();
    final (mosqueStore, _) = await makeMosqueStore();
    final (muhasabaStore, _) = await makeMuhasabaStore();
    final lockStore = await makeAppLockStore();
    final quranStore = await makeQuranStore();
    final duaStore = await makeDuaStore();
    final tasbihStore = await makeTasbihStore();
    GetIt.I
      ..registerSingleton<SettingsStore>(settings)
      ..registerSingleton<MosqueStore>(mosqueStore)
      ..registerSingleton<MuhasabaStore>(muhasabaStore)
      ..registerSingleton<AppLockStore>(lockStore)
      ..registerSingleton<QuranStore>(quranStore)
      ..registerSingleton<DuaStore>(duaStore)
      ..registerSingleton<TasbihStore>(tasbihStore)
      ..registerLazySingleton<HomeStore>(
        () => HomeStore(
          getPrayerDay: GetPrayerDay(PrayerDayRepositoryImpl(clock)),
          clock: clock,
          settings: settings,
          mosque: mosqueStore,
        ),
      );
    await tester.pumpWidget(const ProductiveMuslimApp());
    await tester.pump(const Duration(milliseconds: 1300)); // splash timer
    await tester.pumpAndSettle();
    expect(find.text('Quran'), findsOneWidget);
    expect(find.text('Muhasaba'), findsOneWidget);
  });
}
