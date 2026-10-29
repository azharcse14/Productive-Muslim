import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../../core/di/locator.dart';
import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/productive_muslim_tokens.dart';
import '../../../../core/utils/locale_digits.dart';
import '../../../../shared/extensions/context_ext.dart';
import '../../../../shared/widgets/countdown_card.dart';
import '../../../../shared/widgets/q_banner.dart';
import '../../../../shared/widgets/q_seg_control.dart';
import '../../../../shared/widgets/q_skeleton.dart';
import '../../../../shared/widgets/staggered_entrance.dart';
import '../../../daily_content/domain/usecases/pick_daily_content.dart';
import '../../../daily_content/presentation/state/daily_content_store.dart';
import '../../../daily_content/presentation/widgets/dua_of_day_card.dart';
import '../../../dua_tasbih/domain/entities/dua.dart';
import '../../../dua_tasbih/presentation/screens/tasbih_screen.dart';
import '../../../dua_tasbih/presentation/state/tasbih_store.dart';
import '../../../hadith/domain/entities/hadith.dart';
import '../../../hadith/presentation/state/hadith_store.dart';
import '../../../hadith/presentation/widgets/hadith_card.dart';
import '../../../muhasaba/presentation/state/muhasaba_store.dart';
import '../../../nearby_mosques/domain/usecases/open_nearby_mosques.dart';
import '../../../notifications/domain/repositories/notification_scheduler.dart';
import '../../../qibla/domain/usecases/compass_math.dart';
import '../../../quran/domain/entities/ayah.dart';
import '../../../quran/presentation/state/quran_store.dart';
import '../../../settings/domain/entities/app_settings.dart';
import '../../../settings/domain/entities/location_config.dart';
import '../../../settings/domain/entities/prayer_params.dart';
import '../../../settings/domain/usecases/get_current_location.dart';
import '../../../settings/presentation/state/settings_store.dart';
import '../../domain/entities/prayer_day.dart';
import '../state/home_store.dart';
import '../widgets/continue_reading_card.dart';
import '../widgets/daily_ayah_card.dart';
import '../widgets/day_timeline_sheet.dart';
import '../widgets/home_empty_location.dart';
import '../widgets/home_header.dart';
import '../widgets/home_muhasaba_card.dart';
import '../widgets/mosque_switcher_sheet.dart';
import '../widgets/prayer_detail_sheet.dart';
import '../widgets/prayer_table.dart';
import '../widgets/qibla_mini_chip.dart';
import '../widgets/quick_actions_row.dart';
import '../widgets/sahri_iftar_card.dart';
import '../widgets/special_times_card.dart';
import '../widgets/tasbih_quick_card.dart';
import 'home_formatting.dart';

/// Home (design §4.3): header, smart-countdown hero, quick actions, prayer
/// table, sahri & iftar (under the countdown during Ramadan), then the
/// daily cards. Compact adaptation below 700dp height.
final class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

final class _HomeScreenState extends State<HomeScreen> {
  late final HomeStore _store = locator<HomeStore>();
  late final AppLifecycleListener _lifecycle;
  late final MuhasabaStore _muhasaba = locator<MuhasabaStore>();
  late final SettingsStore _settings = locator<SettingsStore>();
  late final QuranStore? _quran = locator.isRegistered<QuranStore>()
      ? locator<QuranStore>()
      : null;
  late final TasbihStore? _tasbih = locator.isRegistered<TasbihStore>()
      ? locator<TasbihStore>()
      : null;
  late final HadithStore? _hadithStore = locator.isRegistered<HadithStore>()
      ? locator<HadithStore>()
      : null;
  late final DailyContentStore? _daily =
      locator.isRegistered<DailyContentStore>()
      ? locator<DailyContentStore>()
      : null;
  late final NotificationScheduler? _scheduler =
      locator.isRegistered<NotificationScheduler>()
      ? locator<NotificationScheduler>()
      : null;

  /// Android 12+: false while exact alarms are denied (azan may run late).
  bool _exactAlarms = true;

  /// The 1s tick runs only while the app is shown AND Home is on screen
  /// (not under another shell tab or a pushed route).
  bool _appShown = true;
  bool _onScreen = true;

  void _syncTicker() =>
      _appShown && _onScreen ? _store.resume() : _store.pause();

  Future<void> _checkExactAlarms() async {
    final ok = await _scheduler?.canScheduleExactAlarms() ?? true;
    if (mounted && ok != _exactAlarms) {
      setState(() => _exactAlarms = ok);
    }
  }

  /// A small rotation of short, well-known verses; the day picks one so the
  /// "Ayah of the day" is stable for the whole day but varies day to day.
  static const _dailyVerses = <(int surah, int ayah)>[
    (2, 152), // remember Me, I will remember you
    (2, 153), // seek help in patience and prayer
    (2, 286), // Allah burdens no soul beyond capacity
    (3, 8), // do not let our hearts deviate
    (3, 139), // do not lose heart, you will be superior
    (13, 28), // in the remembrance of Allah hearts find rest
    (29, 69), // those who strive for Us, We guide
    (39, 53), // do not despair of the mercy of Allah
    (65, 3), // Allah is sufficient for whoever relies on Him
    (94, 5), // with hardship comes ease
    (94, 6), // indeed, with hardship comes ease
  ];

  Ayah? _ayah;
  Hadith? _hadithOfDay;
  Dua? _duaOfDay;

  /// True until the first ayah/hadith/dua load settles, so the card's
  /// space is held by a skeleton instead of popping in late.
  bool _dailyPending = true;

  /// (Re)loads the "of the day" cards now and whenever the day flips.
  late final EffectCleanup _dayWatcher;

  static const _gpsCheckInterval = Duration(minutes: 30);
  DateTime? _lastGpsCheck;

  /// A GPS location is fixed once at setup; after travel, re-fix on resume
  /// (never prompting) so prayer times follow the device, not the old spot.
  Future<void> _refreshGps() async {
    final saved = _settings.location.value;
    if (saved is! GpsLocation || !locator.isRegistered<GetCurrentLocation>()) {
      return;
    }
    // A GPS fix costs battery; travel is not a minute-scale event.
    final now = DateTime.now();
    if (_lastGpsCheck case final last?
        when now.difference(last) < _gpsCheckInterval) {
      return;
    }
    _lastGpsCheck = now;
    final moved = await locator<GetCurrentLocation>().movedFrom(saved);
    // Skip if the user picked another location while the fix was pending.
    if (moved != null && _settings.location.value == saved) {
      await _settings.setLocation(moved);
    }
  }

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      onHide: () {
        _appShown = false;
        _syncTicker();
      },
      onShow: () {
        _appShown = true;
        _syncTicker();
      },
      onResume: () {
        unawaited(_refreshGps());
        // Back from the exact-alarm settings page.
        unawaited(_checkExactAlarms());
      },
    );
    unawaited(_checkExactAlarms());
    _dayWatcher = effect(() {
      _store.dateKey.value;
      untracked(() {
        // Roll muhasaba's/tasbih's "today" over if the app stayed open past
        // midnight.
        unawaited(_muhasaba.rollOverIfNewDay());
        _tasbih?.rollOverDay();
        unawaited(
          Future.wait([
            _loadDailyAyah(),
            _loadHadith(),
            _loadDuaOfDay(),
          ]).whenComplete(() {
            if (mounted && _dailyPending) {
              setState(() => _dailyPending = false);
            }
          }),
        );
        // Re-reads today's tasbih total (zero on a new day).
        final tasbih = _tasbih;
        if (tasbih != null) {
          unawaited(tasbih.load());
        }
      });
    });
  }

  Future<void> _loadHadith() async {
    final store = _hadithStore;
    if (store == null) {
      return;
    }
    if (!store.loaded.value) {
      await store.load();
    }
    final hadith = store.ofDay(_store.dateKey.value);
    if (mounted && hadith != null) {
      setState(() => _hadithOfDay = hadith);
    }
  }

  Future<void> _loadDuaOfDay() async {
    final daily = _daily;
    if (daily == null) {
      return;
    }
    await daily.load(_store.dateKey.value);
    final dua = daily.duaOfDay.value;
    if (mounted && dua != null) {
      setState(() => _duaOfDay = dua);
    }
  }

  Future<void> _loadDailyAyah() async {
    final quran = _quran;
    if (quran == null) {
      return;
    }
    if (!quran.loaded.value) {
      await quran.load();
    }
    // Days since epoch, not day-of-year: no jump back to verse 0 on Jan 1.
    final seed = dailySeed(_store.dateKey.value);
    final (surah, number) = _dailyVerses[seed % _dailyVerses.length];
    final ayahs = await quran.ayahsOf(surah);
    Ayah? match;
    for (final a in ayahs ?? const <Ayah>[]) {
      if (a.number == number) {
        match = a;
        break;
      }
    }
    if (mounted && match != null) {
      setState(() => _ayah = match);
    }
  }

  Future<void> _refresh() async {
    final tasbih = _tasbih;
    await Future.wait([
      if (tasbih != null) tasbih.load(),
      _loadDailyAyah(),
      _loadHadith(),
      _loadDuaOfDay(),
    ]);
  }

  String _surahName(int surahId) {
    final quran = _quran;
    if (quran == null) {
      return '';
    }
    for (final s in quran.surahs.value) {
      if (s.id == surahId) {
        return s.transliteration;
      }
    }
    return '';
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final onScreen = TickerMode.valuesOf(context).enabled;
    if (onScreen != _onScreen) {
      _onScreen = onScreen;
      _syncTicker();
    }
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _dayWatcher();
    // App-wide singleton: other screens still read dateKey/prayerDay, so
    // keep the slow tick rather than freezing `now`.
    _store.pause();
    super.dispose();
  }

  void _showLockedToast(BuildContext context) {
    final messenger = ScaffoldMessenger.of(context)..clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Text(context.l10n.salahLockedToast),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Opens Google Maps searching for mosques near the user's location.
  /// Reuses the saved location when available; otherwise asks for a GPS fix.
  /// Any failure (no maps app, or no resolvable location) surfaces a snackbar.
  Future<void> _openNearbyMosques(BuildContext context) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context)..clearSnackBars();
    final result = await locator<OpenNearbyMosques>()();
    final message = result.fold(
      (_) => null,
      (failure) => failure is MapsLaunchFailed
          ? l10n.nearbyMosquesLaunchError
          : l10n.nearbyMosquesLocationError,
    );
    if (message == null) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Standard horizontal inset + gap above each home section.
  static Widget _section(Widget child) => Padding(
    padding: const EdgeInsets.fromLTRB(QSpace.s5, QSpace.s4, QSpace.s5, 0),
    child: child,
  );

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      body: SafeArea(
        child: SignalBuilder(
          builder: (context) {
            final day = _store.prayerDay.value;
            if (day == null) {
              return HomeEmptyLocation(
                l10n: l10n,
                failed: _store.location.value != null,
              );
            }
            final compact = MediaQuery.sizeOf(context).height < 700;
            final locale = Localizations.localeOf(context);
            final location = _store.location.value;
            final sahriIftar = _section(_sahriIftarSection(context, day));
            // Ramadan (offset-aware): sahri/iftar is the day's focus, so it
            // sits right under the countdown; otherwise under the table.
            final ramadan = _store.ramadanMode.value;
            final hidden = _settings.settings.value.hiddenHomeCards;
            bool shows(HomeCard card) => !hidden.contains(card);
            final sections = <Widget>[
              if (!_exactAlarms) _section(_exactAlarmBanner(context)),
              _countdownSection(context, day, compact: compact),
              if (ramadan) sahriIftar,
              if (shows(HomeCard.quickActions))
                _section(_quickActions(context)),
              _section(_prayerTableSection(context, day, compact: compact)),
              // Forbidden/makruh windows are a practical warning: keep them
              // by the times they qualify, not below the fold.
              if (shows(HomeCard.specialTimes))
                _section(_specialTimesSection(context)),
              if (!ramadan) sahriIftar,
              if (shows(HomeCard.muhasaba)) _section(_muhasabaSection(context)),
              if (_quran case final quran? when shows(HomeCard.continueReading))
                _section(_continueReadingSection(context, quran, locale)),
              if (_tasbih case final tasbih? when shows(HomeCard.tasbih))
                _section(_tasbihSection(context, tasbih)),
              if (shows(HomeCard.reflection))
                if (_reflectionSection(context, locale) case final reflection?)
                  _section(reflection),
            ];
            return RefreshIndicator(
              onRefresh: _refresh,
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    HomeHeader(
                      greeting: greetingFor(l10n, _store.daypart.value),
                      locationName: formatLocationName(location, locale, l10n),
                      dates: _headerDates(l10n, locale),
                      onLocationTap: () =>
                          context.pushNamed(Routes.locationPicker.name),
                      onQiblaTap: () => context.pushNamed(Routes.qibla.name),
                      onNotificationsTap: () =>
                          context.pushNamed(Routes.notifications.name),
                    ),
                    for (final (i, section) in sections.indexed)
                      // Isolates per-second / pulsing repaints to one card.
                      RepaintBoundary(
                        child: StaggeredEntrance(index: i, child: section),
                      ),
                    const SizedBox(height: QSpace.s5),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// Gregorian · Hijri (offset-adjusted) · Bangla (bn only) header dates.
  List<String> _headerDates(AppLocalizations l10n, Locale locale) {
    final hijri = _store.hijriDate.value;
    final bangla = _store.banglaDate.value;
    final gregorian = DateFormat.yMMMEd(
      locale.toString(),
    ).format(_store.dateKey.value);
    return [
      LocaleDigits.localize(gregorian, locale.languageCode),
      LocaleDigits.localize(
        '${hijri.day} ${l10n.hijriMonthName('m${hijri.month}')} ${hijri.year}',
        locale.languageCode,
      ),
      if (locale.languageCode == 'bn')
        LocaleDigits.localize(
          '${bangla.day} ${l10n.banglaMonthName('m${bangla.month}')} ${bangla.year}',
          locale.languageCode,
        ),
    ];
  }

  /// Smart countdown hero, tinted by the time of day.
  /// Ayah, hadith and dua of the day share one card with a switcher,
  /// instead of three stacked cards at the foot of Home.
  Widget? _reflectionSection(BuildContext context, Locale locale) {
    final l10n = context.l10n;
    final options = <(String, Widget)>[
      if (_ayah case final ayah?)
        (l10n.dailyKindAyah, _dailyAyahCard(context, ayah, locale)),
      if (_hadithOfDay case final hadith?)
        (l10n.notifDailyKindHadith, _hadithCard(context, hadith, locale)),
      if (_duaOfDay case final dua?)
        (l10n.notifDailyKindDua, _duaCard(context, dua, locale)),
    ];
    if (options.isEmpty) {
      return _dailyPending
          ? const QSkeleton(height: 180, radius: QRadius.lg)
          : null;
    }
    return DailyReflectionSection(options: options);
  }

  Widget _countdownSection(
    BuildContext context,
    PrayerDay day, {
    required bool compact,
  }) {
    final l10n = context.l10n;
    final location = _store.location.value;
    final qiblaBearing = location == null
        ? null
        : CompassMath.qiblaBearing(location.latitude, location.longitude);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        QSpace.s5,
        compact ? QSpace.s3 : QSpace.s4,
        QSpace.s5,
        0,
      ),
      child: SignalBuilder(
        builder: (context) {
          final target = _store.countdownTarget.value;
          if (target == null) {
            return const SizedBox.shrink();
          }
          final (eyebrow, sub) = countdownLabels(l10n, context, target);
          // The timeline is otherwise invisible: a footer cue plus a
          // screen-reader tap hint make the card read as tappable.
          return Semantics(
            button: true,
            onTapHint: l10n.countdownSeeDay,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => unawaited(
                showDayTimelineSheet(
                  context,
                  day: day,
                  now: _store.now.value,
                  formatTime: (t) => formatHomeTime(context, t),
                  activePrayer: _store.activeWaqt.value?.prayer,
                ),
              ),
              child: CountdownCard(
                state: countdownCardState(_store.urgency.value),
                skyPhase: skyPhaseFor(_store.now.value, day),
                eyebrow: eyebrow,
                big: formatCountdown(context, _store.remaining.value),
                sub: sub,
                progress: _store.progress.value,
                corner: (fg) => QiblaMiniChip(
                  bearing: qiblaBearing,
                  heading: null,
                  hasLocation: location != null,
                  foreground: fg,
                  onTap: () => context.pushNamed(Routes.qibla.name),
                ),
                footer: [
                  (
                    icon: Icons.wb_sunny_outlined,
                    text:
                        '${l10n.sunriseLabel} ${formatHomeTime(context, day.sunrise)}',
                  ),
                  (
                    icon: Icons.wb_twilight_outlined,
                    text:
                        '${l10n.sunsetLabel} ${formatHomeTime(context, day.maghrib)}',
                  ),
                  (
                    icon: Icons.view_timeline_outlined,
                    text: l10n.countdownSeeDay,
                  ),
                ],
                compact: compact,
              ),
            ),
          );
        },
      ),
    );
  }

  /// Shown while Android denies exact alarms; tapping opens the OS consent.
  Widget _exactAlarmBanner(BuildContext context) => Semantics(
    button: true,
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => unawaited(
        _scheduler?.requestExactAlarmPermission().then(
          (_) => _checkExactAlarms(),
        ),
      ),
      child: QBanner(
        text: context.l10n.prayerTimesExactAlarmBanner,
        icon: Icons.alarm_outlined,
        tone: context.q.warnSoft,
        foreground: context.q.warn,
      ),
    ),
  );

  /// Tools hub: shortcuts to features that aren't a bottom-nav tab and
  /// don't already have their own home affordance (qibla lives in the
  /// header and the countdown chip).
  Widget _quickActions(BuildContext context) {
    final l10n = context.l10n;
    return QuickActionsRow(
      actions: [
        QuickAction(
          icon: Icons.mosque_outlined,
          label: l10n.nearbyMosquesLabel,
          onTap: () => _openNearbyMosques(context),
        ),
        QuickAction(
          icon: Icons.format_quote_outlined,
          label: l10n.hadithTitle,
          onTap: () => context.pushNamed(Routes.hadith.name),
        ),
        QuickAction(
          icon: Icons.calendar_month_outlined,
          label: l10n.calendarTitle,
          onTap: () => context.pushNamed(Routes.calendar.name),
        ),
        QuickAction(
          icon: Icons.shield_outlined,
          label: l10n.ruqyahTitle,
          onTap: () => context.pushNamed(Routes.ruqyah.name),
        ),
      ],
    );
  }

  /// Today's prayer table.
  Widget _prayerTableSection(
    BuildContext context,
    PrayerDay day, {
    required bool compact,
  }) {
    final l10n = context.l10n;
    return SignalBuilder(
      builder: (context) {
        final muhasaba = _muhasaba;
        final resolution = _store.mosqueResolution.value;
        final profiles = _store.mosqueProfiles.value;
        return PrayerTable(
          day: day,
          activePrayer: _store.activeWaqt.value?.prayer,
          jamaat: _store.jamaatConfig.value,
          formatTime: (t) => formatHomeTime(context, t),
          dense: compact,
          locked: _store.lockedPrayers.value,
          onLockedTap: (_) => _showLockedToast(context),
          onSetJamaat: () => context.pushNamed(Routes.myMosque.name),
          mosqueName: resolution.profile?.name,
          mosqueBadge: !resolution.isAuto
              ? null
              : (resolution.isOverride
                    ? l10n.mosqueOverrideBadge
                    : l10n.mosqueAutoBadge),
          onSwitchMosque: profiles.isEmpty
              ? null
              : () => unawaited(
                  showMosqueSwitcherSheet(
                    context,
                    mosques: [
                      for (final p in profiles) (id: p.id, name: p.name),
                    ],
                    currentId: resolution.profile?.id,
                    isAuto: resolution.isAuto,
                    isOverride: resolution.isOverride,
                    onSelect: (id) => unawaited(_store.selectMosque(id)),
                    onResetToAuto: () =>
                        unawaited(_store.clearMosqueOverride()),
                    onManage: () => context.pushNamed(Routes.myMosque.name),
                  ),
                ),
          // The real day's ticks, whatever date the Muhasaba tab is on.
          prayed: {
            for (final prayer in Prayer.values)
              if ((muhasaba.entriesOn(
                        _store.salahDate(prayer),
                      )['salah_${prayer.name}'] ??
                      0) >
                  0)
                prayer,
          },
          onTogglePrayed: (prayer) => unawaited(
            muhasaba.togglePrayerOn(
              'salah_${prayer.name}',
              _store.salahDate(prayer),
            ),
          ),
          onPrayerTap: (prayer) => unawaited(
            showPrayerDetailSheet(
              context,
              prayer: prayer,
              range:
                  '${formatHomeTime(context, day.startOf(prayer))} – ${formatHomeTime(context, day.endOf(prayer))}',
              jamaatTime: switch (_store.jamaatConfig.value.timeFor(
                prayer,
                day.startOf(prayer),
              )) {
                null => null,
                final t => formatHomeTime(context, t),
              },
            ),
          ),
        );
      },
    );
  }

  Widget _sahriIftarSection(BuildContext context, PrayerDay day) =>
      SahriIftarCard(
        sahriEnd: formatHomeTime(
          context,
          _store.nextSahriEnd.value ?? day.sahriEnd,
        ),
        iftar: formatHomeTime(context, day.iftar),
      );

  /// Muhasaba (daily-deeds) summary.
  Widget _muhasabaSection(BuildContext context) => SignalBuilder(
    builder: (context) {
      final stats = _muhasaba.stats.value;
      if (stats == null) {
        return const SizedBox.shrink();
      }
      // The period range always ends today, so the last day completion is
      // today's.
      final today = stats.days.isEmpty ? 0.0 : stats.days.last.completion;
      final items = _muhasaba.items.value;
      final entries = _muhasaba.entriesOn(_store.dateKey.value);
      final doneToday = items.where((i) => i.isDone(entries[i.id] ?? 0)).length;
      return HomeMuhasabaCard(
        completion: today,
        doneToday: doneToday,
        totalItems: items.length,
        streak: stats.currentStreak,
        onTap: () => context.goNamed(Routes.muhasaba.name),
        milestone: isStreakMilestone(stats.currentStreak),
      );
    },
  );

  /// Continue reading the Quran from the last position.
  Widget _continueReadingSection(
    BuildContext context,
    QuranStore quran,
    Locale locale,
  ) {
    final l10n = context.l10n;
    return SignalBuilder(
      builder: (context) {
        final pos = quran.lastRead.value;
        if (pos == null) {
          return const SizedBox.shrink();
        }
        return ContinueReadingCard(
          title: l10n.continueReading,
          surahName: _surahName(pos.surah),
          ayahLabel: l10n.continueReadingAyah(
            LocaleDigits.localize('${pos.ayah}', locale.languageCode),
          ),
          onTap: () => context.goNamed(
            Routes.quranAyah.name,
            pathParameters: {'surah': '${pos.surah}', 'ayah': '${pos.ayah}'},
          ),
        );
      },
    );
  }

  Widget _tasbihSection(BuildContext context, TasbihStore tasbih) =>
      SignalBuilder(
        builder: (context) => TasbihQuickCard(
          count: tasbih.count.value,
          target: tasbih.target.value,
          onTap: tasbih.tap,
          onReset: tasbih.count.value > 0
              ? () => unawaited(confirmTasbihReset(context, tasbih))
              : null,
          onOpen: () => context.goNamed(Routes.dua.name),
        ),
      );

  /// Forbidden & nafl windows.
  Widget _specialTimesSection(BuildContext context) => SignalBuilder(
    builder: (context) {
      final windows = _store.specialWindows.value;
      if (windows.isEmpty) {
        return const SizedBox.shrink();
      }
      return SpecialTimesCard(
        windows: windows,
        active: _store.activeSpecial.value,
        formatTime: (t) => formatHomeTime(context, t),
        onTap: (kind) => context.pushNamed(
          Routes.specialTimes.name,
          extra: (kind, windows.where((w) => w.kind == kind).toList()),
        ),
      );
    },
  );

  Widget _dailyAyahCard(BuildContext context, Ayah ayah, Locale locale) =>
      DailyAyahCard(
        arabic: ayah.arabic,
        translation: ayah.translationFor(locale.languageCode),
        surahName: _surahName(ayah.surah),
        ayahNumber: LocaleDigits.localize(
          '${ayah.number}',
          locale.languageCode,
        ),
        onTap: () => context.goNamed(
          Routes.quranAyah.name,
          pathParameters: {'surah': '${ayah.surah}', 'ayah': '${ayah.number}'},
        ),
      );

  /// Opens this very hadith, not just the collection.
  Widget _hadithCard(BuildContext context, Hadith hadith, Locale locale) =>
      HadithCard(
        text: hadith.translationFor(locale.languageCode),
        narrator: hadith.narrator,
        reference: hadith.reference,
        onTap: () => context.pushNamed(
          Routes.hadithItem.name,
          pathParameters: {'id': hadith.id},
        ),
      );

  Widget _duaCard(BuildContext context, Dua dua, Locale locale) => DuaOfDayCard(
    arabic: dua.arabic,
    translation: dua.translationFor(locale.languageCode),
    reference: dua.reference,
    onTap: () => context.goNamed(Routes.dua.name),
  );
}

final class DailyReflectionSection extends StatefulWidget {
  const DailyReflectionSection({required this.options, super.key});

  final List<(String, Widget)> options;

  @override
  State<DailyReflectionSection> createState() => _DailyReflectionSectionState();
}

final class _DailyReflectionSectionState extends State<DailyReflectionSection> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    if (widget.options.isEmpty) {
      return const SizedBox.shrink();
    }
    final index = _selectedIndex.clamp(0, widget.options.length - 1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.options.length > 1) ...[
          QSegControl(
            options: [for (final o in widget.options) o.$1],
            activeIndex: index,
            onChanged: (i) => setState(() => _selectedIndex = i),
          ),
          const SizedBox(height: QSpace.s3),
        ],
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: SizeTransition(sizeFactor: animation, child: child),
            );
          },
          child: KeyedSubtree(
            key: ValueKey(index),
            child: widget.options[index].$2,
          ),
        ),
      ],
    );
  }
}
