import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:productive_muslim/core/settings/settings_store.dart';
import 'package:productive_muslim/core/utils/result.dart';
import 'package:productive_muslim/features/dua_tasbih/presentation/state/dua_store.dart';
import 'package:productive_muslim/features/dua_tasbih/presentation/state/tasbih_store.dart';
import 'package:productive_muslim/features/muhasaba/presentation/state/muhasaba_store.dart';
import 'package:productive_muslim/features/my_mosque/presentation/state/mosque_store.dart';
import 'package:productive_muslim/features/notifications/domain/entities/notification_item.dart';
import 'package:productive_muslim/features/notifications/domain/entities/notification_texts.dart';
import 'package:productive_muslim/features/notifications/domain/repositories/notification_scheduler.dart';
import 'package:productive_muslim/features/notifications/domain/usecases/reschedule_notifications.dart';
import 'package:productive_muslim/features/notifications/presentation/state/notification_controller.dart';
import 'package:productive_muslim/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:productive_muslim/features/onboarding/presentation/state/app_lock_store.dart';
import 'package:productive_muslim/features/prayer_times/data/repositories/prayer_day_repository_impl.dart';
import 'package:productive_muslim/features/prayer_times/domain/usecases/get_prayer_day.dart';
import 'package:productive_muslim/features/prayer_times/presentation/state/home_store.dart';
import 'package:productive_muslim/features/quran/presentation/state/quran_store.dart';
import 'package:productive_muslim/features/settings/data/datasources/timezone_clock.dart';
import 'package:productive_muslim/features/settings/domain/entities/app_settings.dart';
import 'package:productive_muslim/features/settings/domain/entities/city.dart';
import 'package:productive_muslim/features/settings/domain/entities/location_config.dart';
import 'package:productive_muslim/features/settings/domain/repositories/city_repository.dart';
import 'package:productive_muslim/features/settings/domain/repositories/location_repository.dart';
import 'package:productive_muslim/features/settings/domain/repositories/settings_repository.dart';
import 'package:productive_muslim/features/settings/domain/usecases/get_current_location.dart';
import 'package:productive_muslim/features/settings/domain/usecases/get_settings.dart';
import 'package:productive_muslim/features/settings/domain/usecases/save_settings.dart';
import 'package:productive_muslim/features/settings/domain/usecases/search_cities.dart';
import 'package:productive_muslim/main.dart';
import 'package:productive_muslim/shared/reader/reader_text_size.dart';
import 'package:productive_muslim/shared/widgets/countdown_card.dart';

import 'helpers/content_fakes.dart';
import 'helpers/home_store_fakes.dart';
import 'helpers/lock_fakes.dart';
import 'helpers/mosque_fakes.dart';
import 'helpers/muhasaba_fakes.dart';

final class _InMemoryRepo implements SettingsRepository {
  _InMemoryRepo([this.stored = const AppSettings(setupComplete: true)]);

  AppSettings stored;

  @override
  Future<Result<AppSettings>> load() async => Result.success(stored);

  @override
  Future<Result<void>> save(AppSettings settings) async {
    stored = settings;
    return const Result.success(null);
  }
}

const _cairo = City(
  name: 'Cairo',
  countryCode: 'EG',
  latitude: 30.04,
  longitude: 31.24,
  timezone: 'Africa/Cairo',
);

final class _Cities implements CityRepository {
  @override
  Future<Result<List<City>>> search(String query, {int limit = 30}) async =>
      const Result.success([_cairo]);
}

final class _NoGps implements LocationRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Grants everything and records the last plan handed to the OS.
final class _RecordingScheduler implements NotificationScheduler {
  List<NotificationItem>? scheduled;

  @override
  Future<void> initialize(NotificationTexts texts) async {}

  @override
  Future<NotificationPermission> permissionStatus() async =>
      NotificationPermission.granted;

  @override
  Future<NotificationPermission> requestPermission() async =>
      NotificationPermission.granted;

  @override
  Future<bool> canScheduleExactAlarms() async => true;

  @override
  Future<Result<void>> reschedule(
    List<NotificationItem> items,
    NotificationTexts texts,
  ) async {
    scheduled = items;
    return const Result.success(null);
  }

  @override
  Future<void> cancelAll() async => scheduled = const [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// The stores the app shell and Home resolve, as `main()` registers them.
Future<SettingsStore> _registerApp(_InMemoryRepo repo) async {
  TimezoneClock.initialize();
  final settings = SettingsStore(GetSettings(repo), SaveSettings(repo));
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
    ..registerSingleton(ReaderTextSize())
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
  return settings;
}

Future<void> _tap(WidgetTester tester, String text) async {
  await tester.tap(find.text(text).hitTestable());
  await tester.pumpAndSettle();
}

void main() {
  tearDown(() => GetIt.I.reset());

  testHomeWidgets('app boots to the shell with bottom navigation', (
    tester,
  ) async {
    await _registerApp(_InMemoryRepo());
    await tester.pumpWidget(const ProductiveMuslimApp());
    await tester.pump(const Duration(milliseconds: 1300)); // splash timer
    await tester.pumpAndSettle();
    expect(find.text('Quran'), findsOneWidget);
    expect(find.text('Muhasaba'), findsOneWidget);
  });

  // Review fix plan 4.5: fresh install → onboarding with a manual city →
  // Home countdown → a non-empty notification plan reached the scheduler.
  testHomeWidgets('fresh install: onboarding to Home schedules a plan', (
    tester,
  ) async {
    // The active waqt's row pulses forever; without this, pumpAndSettle
    // would time out whenever a waqt is active in Cairo.
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    final repo = _InMemoryRepo(const AppSettings());
    final settings = await _registerApp(repo);
    final scheduler = _RecordingScheduler();
    final clock = TimezoneClock();
    final controller = NotificationController(
      reschedule: RescheduleNotifications(
        getPrayerDay: GetPrayerDay(PrayerDayRepositoryImpl(clock)),
        scheduler: scheduler,
        clock: clock,
      ),
      scheduler: scheduler,
      settings: settings,
      mosque: GetIt.I<MosqueStore>(),
    );
    addTearDown(controller.dispose);
    GetIt.I
      ..registerSingleton<NotificationScheduler>(scheduler)
      ..registerSingleton(SearchCities(_Cities()))
      ..registerSingleton(GetCurrentLocation(_NoGps()))
      ..registerSingleton(controller);
    // As main() does: boot scheduling, then reschedule on settings changes.
    await controller.start();
    expect(scheduler.scheduled ?? const [], isEmpty, reason: 'no location');

    await tester.pumpWidget(const ProductiveMuslimApp());
    await tester.pump(const Duration(milliseconds: 1300)); // splash timer
    await tester.pumpAndSettle();
    expect(find.byType(OnboardingScreen), findsOneWidget);

    await _tap(tester, 'Next'); // welcome → location
    await _tap(tester, 'Choose city manually');
    await tester.enterText(find.byType(TextField), 'Cairo');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cairo').hitTestable().last);
    await tester.pumpAndSettle();
    expect(repo.stored.location, const ManualCityLocation(_cairo));

    await _tap(tester, 'Next'); // location → madhab
    await _tap(tester, 'Next'); // madhab → method
    await _tap(tester, 'Next'); // method → notifications
    await _tap(tester, 'Maybe later');
    await _tap(tester, 'Begin');

    expect(repo.stored.setupComplete, isTrue);
    expect(find.byType(OnboardingScreen), findsNothing);
    expect(find.byType(CountdownCard), findsOneWidget);
    // The location change rescheduled (400 ms debounce) with Cairo's times.
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(scheduler.scheduled, isNotEmpty);
  });
}
