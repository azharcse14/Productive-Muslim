import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:productive_muslim/core/l10n/gen/app_localizations.dart';
import 'package:productive_muslim/core/settings/settings_store.dart';
import 'package:productive_muslim/core/theme/app_theme.dart';
import 'package:productive_muslim/core/utils/bangla_date.dart';
import 'package:productive_muslim/core/utils/hijri_date.dart';
import 'package:productive_muslim/core/utils/locale_digits.dart';
import 'package:productive_muslim/core/utils/result.dart';
import 'package:productive_muslim/features/calendar/presentation/screens/calendar_screen.dart';
import 'package:productive_muslim/features/prayer_times/data/repositories/prayer_day_repository_impl.dart';
import 'package:productive_muslim/features/prayer_times/domain/usecases/get_prayer_day.dart';
import 'package:productive_muslim/features/settings/data/datasources/timezone_clock.dart';
import 'package:productive_muslim/features/settings/domain/entities/app_settings.dart';
import 'package:productive_muslim/features/settings/domain/entities/city.dart';
import 'package:productive_muslim/features/settings/domain/entities/location_config.dart';
import 'package:productive_muslim/features/settings/domain/repositories/settings_repository.dart';
import 'package:productive_muslim/features/settings/domain/repositories/zoned_clock.dart';
import 'package:productive_muslim/features/settings/domain/usecases/get_settings.dart';
import 'package:productive_muslim/features/settings/domain/usecases/save_settings.dart';
import '../../helpers/layout_matrix.dart';

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

/// "Today" is 2 Nov 2026 — November 2026 starts on a Sunday.
final class _FixedClock implements ZonedClock {
  final _real = TimezoneClock();

  @override
  DateTime nowAt(LocationConfig location) => DateTime.utc(2026, 11, 2, 10);

  @override
  DateTime instantAt(LocationConfig location, DateTime instant) =>
      _real.instantAt(location, instant);

  @override
  DateTime utcInstantOf(LocationConfig location, DateTime wall) =>
      _real.utcInstantOf(location, wall);
}

/// Material strings with a chosen first weekday (0 = Sunday).
final class _FirstDay extends LocalizationsDelegate<MaterialLocalizations> {
  const _FirstDay(this.index);

  final int index;

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<MaterialLocalizations> load(Locale locale) =>
      SynchronousFuture(_Strings(index));

  @override
  bool shouldReload(_FirstDay old) => old.index != index;
}

final class _Strings extends DefaultMaterialLocalizations {
  const _Strings(this.firstDayOfWeekIndex);

  @override
  final int firstDayOfWeekIndex;
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
  setUpAll(TimezoneClock.initialize);

  setUp(() async {
    final settings = SettingsStore(
      GetSettings(_Repo(const AppSettings(location: _dhaka))),
      SaveSettings(_Repo(const AppSettings())),
    );
    await settings.load();
    GetIt.I
      ..registerSingleton<SettingsStore>(settings)
      ..registerSingleton<ZonedClock>(_FixedClock())
      ..registerSingleton(
        GetPrayerDay(PrayerDayRepositoryImpl(TimezoneClock())),
      );
  });

  tearDown(() => GetIt.I.reset());

  /// Empty cells before day 1 of the displayed month.
  Future<int> leadingCells(WidgetTester tester, int firstDay) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        localizationsDelegates: [
          _FirstDay(firstDay),
          ...AppLocalizations.localizationsDelegates,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: const CalendarScreen(),
      ),
    );
    await tester.pumpAndSettle();
    final grid = tester.widget<GridView>(find.byType(GridView));
    final cells = (grid.childrenDelegate as SliverChildListDelegate).children;
    final first = cells.indexWhere(
      (c) => c.key == const ValueKey('calendar-day-1'),
    );
    return first - 7; // after the weekday header row
  }

  testWidgets('Saturday-first week pads one cell before Sunday the 1st', (
    tester,
  ) async {
    expect(await leadingCells(tester, DateTime.saturday), 1);
  });

  testWidgets('Monday-first week pads six cells before Sunday the 1st', (
    tester,
  ) async {
    expect(await leadingCells(tester, DateTime.monday), 6);
  });

  /// Texts inside the cell for [day] of November 2026.
  List<String> cellTexts(WidgetTester tester, int day) => tester
      .widgetList<Text>(
        find.descendant(
          of: find.byKey(ValueKey('calendar-day-$day')),
          matching: find.byType(Text),
        ),
      )
      .map((t) => t.data!)
      .toList();

  Future<void> pumpAt(
    WidgetTester tester,
    Locale locale, {
    double width = 360,
    double textScale = 1.3,
  }) async {
    tester.view
      ..physicalSize = Size(width, 780)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const CalendarScreen(),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('bn: cells add the Bangla day in Bangla digits, no overflow '
      'at 360dp and 1.3x text', (tester) async {
    await pumpAt(tester, const Locale('bn'));
    expect(tester.takeException(), isNull);
    for (var day = 1; day <= 30; day++) {
      final bangla = BanglaDate.fromGregorian(DateTime(2026, 11, day)).day;
      final texts = cellTexts(tester, day);
      expect(texts, hasLength(3));
      expect(texts.last, LocaleDigits.localize('$bangla', 'bn'));
    }
  });

  for (final scale in [1.0, 1.3]) {
    testWidgets('bn: three-line cells fit at 320dp and ${scale}x text', (
      tester,
    ) async {
      await pumpAt(tester, const Locale('bn'), width: 320, textScale: scale);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('en: cells show no Bangla day', (tester) async {
    await pumpAt(tester, const Locale('en'));
    expect(tester.takeException(), isNull);
    expect(cellTexts(tester, 1), hasLength(2));
  });

  testWidgets('Shab-e-Barat sheet: begins at sunset, scholars differ', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(360, 1400)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const CalendarScreen(),
      ),
    );
    await tester.pumpAndSettle();
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    // 14 Sha'ban 1448 (the eve of the 15th), months after pinned Nov 2026.
    final eve = const HijriDate(1448, 8, 14).toGregorian();
    final months = (eve.year - 2026) * 12 + eve.month - 11;
    expect(months, inInclusiveRange(1, 4), reason: 'fixture assumption');
    for (var i = 0; i < months; i++) {
      await tester.fling(find.byType(GridView), const Offset(-250, 0), 1000);
      await tester.pumpAndSettle();
    }
    await tester.tap(find.text(l10n.islamicDayName('nisfShaban')));
    await tester.pumpAndSettle();
    expect(find.text(l10n.calendarNightBeginsAtSunset), findsOneWidget);
    expect(find.text(l10n.calendarObservanceDiffers), findsOneWidget);
  });

  layoutMatrix(
    'CalendarScreen',
    screen: () => const CalendarScreen(),
    // The pixel sampler misreads the antialiased one-letter weekday
    // headers (ink3 on bg is 5.0:1 light, 5.7:1 dark by token).
    contrast: false,
  );
}
