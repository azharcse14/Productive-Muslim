import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../../core/di/locator.dart';
import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/qalbee_tokens.dart';
import '../../../../core/theme/qalbee_typography.dart';
import '../../../../core/utils/locale_digits.dart';
import '../../../../shared/extensions/context_ext.dart';
import '../../../../shared/painters/qalb_mark.dart';
import '../../../../shared/widgets/countdown_card.dart';
import '../../../../shared/widgets/q_button.dart';
import '../../../../shared/widgets/q_card.dart';
import '../../../../shared/widgets/q_progress_ring.dart';
import '../../../dua_tasbih/presentation/state/tasbih_store.dart';
import '../../../hadith/domain/entities/hadith.dart';
import '../../../hadith/presentation/state/hadith_store.dart';
import '../../../hadith/presentation/widgets/hadith_card.dart';
import '../../../muhasaba/presentation/state/muhasaba_store.dart';
import '../../../qibla/domain/usecases/compass_math.dart';
import '../../../quran/domain/entities/ayah.dart';
import '../../../quran/presentation/state/quran_store.dart';
import '../../../settings/domain/entities/prayer_params.dart';
import '../../../settings/presentation/widgets/setting_labels.dart';
import '../../domain/entities/countdown_target.dart';
import '../state/home_store.dart';
import '../widgets/daily_ayah_card.dart';
import '../widgets/day_timeline_sheet.dart';
import '../widgets/home_header.dart';
import '../widgets/prayer_detail_sheet.dart';
import '../widgets/prayer_table.dart';
import '../widgets/qibla_mini_chip.dart';
import '../widgets/special_times_card.dart';
import '../widgets/tasbih_quick_card.dart';

/// Home (design §4.3): header, smart-countdown hero, prayer table,
/// sahri & iftar row. Compact adaptation below 700dp height.
final class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

final class _HomeScreenState extends State<HomeScreen> {
  late final HomeStore _store = locator<HomeStore>();
  late final MuhasabaStore _muhasaba = locator<MuhasabaStore>();
  late final QuranStore? _quran = locator.isRegistered<QuranStore>()
      ? locator<QuranStore>()
      : null;
  late final TasbihStore? _tasbih = locator.isRegistered<TasbihStore>()
      ? locator<TasbihStore>()
      : null;
  late final HadithStore? _hadithStore = locator.isRegistered<HadithStore>()
      ? locator<HadithStore>()
      : null;

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

  @override
  void initState() {
    super.initState();
    unawaited(_loadDailyAyah());
    unawaited(_loadHadith());
    final tasbih = _tasbih;
    if (tasbih != null) {
      unawaited(tasbih.load());
    }
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

  Future<void> _loadDailyAyah() async {
    final quran = _quran;
    if (quran == null) {
      return;
    }
    if (!quran.loaded.value) {
      await quran.load();
    }
    final dayOfYear = _store.dateKey.value
        .difference(DateTime(_store.dateKey.value.year))
        .inDays;
    final (surah, number) = _dailyVerses[dayOfYear % _dailyVerses.length];
    final ayahs = await quran.ayahsOf(surah);
    Ayah? match;
    for (final a in ayahs) {
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

  /// Streak lengths worth a small on-card celebration (design §4.7 nudge).
  static bool _isStreakMilestone(int streak) =>
      streak == 7 ||
      streak == 30 ||
      streak == 100 ||
      streak == 365 ||
      (streak > 0 && streak % 100 == 0);

  @override
  void dispose() {
    _store.dispose();
    super.dispose();
  }

  String _formatTime(BuildContext context, DateTime time) {
    final locale = Localizations.localeOf(context);
    return LocaleDigits.localize(
      DateFormat.jm(locale.toString()).format(time),
      locale.languageCode,
    );
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

  String _formatCountdown(BuildContext context, Duration d) {
    String two(int v) => v.toString().padLeft(2, '0');
    final text =
        '${two(d.inHours)}:${two(d.inMinutes % 60)}:${two(d.inSeconds % 60)}';
    return LocaleDigits.localize(
      text,
      Localizations.localeOf(context).languageCode,
    );
  }

  (String eyebrow, String sub) _countdownLabels(
    AppLocalizations l10n,
    BuildContext context,
    CountdownTarget target,
  ) {
    final prayerName = l10n.prayerLabel(target.prayer);
    final timeText = _formatTime(context, target.at);
    return switch (target.kind) {
      CountdownKind.waqtStart => (
        l10n.countdownStartsIn(prayerName),
        l10n.subAt(prayerName, timeText),
      ),
      CountdownKind.jamaat => (
        l10n.countdownJamaatIn,
        l10n.subAt(l10n.jamaatLabel, timeText),
      ),
      CountdownKind.waqtEnd => (
        l10n.countdownEndsIn(prayerName),
        l10n.subAt(prayerName, timeText),
      ),
      CountdownKind.sahriEnd => (
        l10n.countdownSahriEnds,
        l10n.subAt(l10n.prayerLabel(target.prayer), timeText),
      ),
      CountdownKind.iftar => (
        l10n.countdownIftarIn,
        l10n.subAt(l10n.iftarLabel, timeText),
      ),
    };
  }

  CountdownState _cardState(CountdownUrgency urgency) => switch (urgency) {
    CountdownUrgency.calm => CountdownState.calm,
    CountdownUrgency.amber => CountdownState.amber,
    CountdownUrgency.urgent => CountdownState.urgent,
    CountdownUrgency.sahri => CountdownState.sahri,
    CountdownUrgency.iftar => CountdownState.iftar,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      body: SafeArea(
        child: SignalBuilder(
          builder: (context) {
            final day = _store.prayerDay.value;
            if (day == null) {
              return _EmptyLocation(l10n: l10n);
            }
            final compact = MediaQuery.sizeOf(context).height < 700;
            final locale = Localizations.localeOf(context);
            final hijri = _store.hijriDate.value;
            final bangla = _store.banglaDate.value;
            final gregorian = DateFormat.yMMMEd(
              locale.toString(),
            ).format(_store.dateKey.value);
            final dates = [
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

            final location = _store.location.value;
            final qiblaBearing = location == null
                ? null
                : CompassMath.qiblaBearing(
                    location.latitude,
                    location.longitude,
                  );

            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                padding: EdgeInsets.zero,
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  HomeHeader(
                    locationName: switch (location?.displayName) {
                      null || '' => l10n.locationCurrent,
                      final name => name,
                    },
                    dates: dates,
                    onLocationTap: () =>
                        context.pushNamed(Routes.locationPicker.name),
                    onQiblaTap: () => context.pushNamed(Routes.qibla.name),
                    onNotificationsTap: () =>
                        context.pushNamed(Routes.notificationSettings.name),
                  ),
                  Padding(
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
                        final (eyebrow, sub) = _countdownLabels(
                          l10n,
                          context,
                          target,
                        );
                        return GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => unawaited(
                            showDayTimelineSheet(
                              context,
                              day: day,
                              now: _store.now.value,
                              formatTime: (t) => _formatTime(context, t),
                              activePrayer: _store.activeWaqt.value?.prayer,
                            ),
                          ),
                          child: CountdownCard(
                            state: _cardState(_store.urgency.value),
                            eyebrow: eyebrow,
                            big: _formatCountdown(
                              context,
                              _store.remaining.value,
                            ),
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
                                    '${l10n.sunriseLabel} ${_formatTime(context, day.sunrise)}',
                              ),
                              (
                                icon: Icons.wb_twilight_outlined,
                                text:
                                    '${l10n.sunsetLabel} ${_formatTime(context, day.maghrib)}',
                              ),
                            ],
                            compact: compact,
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      QSpace.s5,
                      QSpace.s4,
                      QSpace.s5,
                      0,
                    ),
                    child: SignalBuilder(
                      builder: (context) {
                        final muhasaba = _muhasaba;
                        final entries = muhasaba.entries.value;
                        return PrayerTable(
                          day: day,
                          activePrayer: _store.activeWaqt.value?.prayer,
                          jamaat: _store.jamaatConfig.value,
                          formatTime: (t) => _formatTime(context, t),
                          dense: compact,
                          locked: _store.lockedPrayers.value,
                          onLockedTap: (_) => _showLockedToast(context),
                          onSetJamaat: () =>
                              context.pushNamed(Routes.myMosque.name),
                          prayed: {
                            for (final prayer in Prayer.values)
                              if (muhasaba.selectedIsToday &&
                                  (entries['salah_${prayer.name}'] ?? 0) > 0)
                                prayer,
                          },
                          onTogglePrayed: (prayer) => unawaited(
                            muhasaba.togglePrayerToday('salah_${prayer.name}'),
                          ),
                          onPrayerTap: (prayer) => unawaited(
                            showPrayerDetailSheet(
                              context,
                              prayer: prayer,
                              range:
                                  '${_formatTime(context, day.startOf(prayer))} – ${_formatTime(context, day.endOf(prayer))}',
                              jamaatTime: switch (_store.jamaatConfig.value
                                  .timeFor(prayer, day.startOf(prayer))) {
                                null => null,
                                final t => _formatTime(context, t),
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      QSpace.s5,
                      QSpace.s4,
                      QSpace.s5,
                      0,
                    ),
                    child: SignalBuilder(
                      builder: (context) {
                        final stats = _muhasaba.stats.value;
                        if (stats == null) {
                          return const SizedBox.shrink();
                        }
                        // The period range always ends today, so the last day
                        // completion is today's.
                        final today = stats.days.isEmpty
                            ? 0.0
                            : stats.days.last.completion;
                        final items = _muhasaba.items.value;
                        final entries = _muhasaba.entries.value;
                        final doneToday = _muhasaba.selectedIsToday
                            ? items
                                  .where((i) => i.isDone(entries[i.id] ?? 0))
                                  .length
                            : (today * items.length).round();
                        return _MuhasabaCard(
                          completion: today,
                          doneToday: doneToday,
                          totalItems: items.length,
                          streak: stats.currentStreak,
                          onTap: () => context.goNamed(Routes.muhasaba.name),
                          milestone: _isStreakMilestone(stats.currentStreak),
                        );
                      },
                    ),
                  ),
                  if (_tasbih case final tasbih?)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        QSpace.s5,
                        QSpace.s4,
                        QSpace.s5,
                        0,
                      ),
                      child: SignalBuilder(
                        builder: (context) => TasbihQuickCard(
                          count: tasbih.count.value,
                          target: tasbih.target.value,
                          onTap: tasbih.tap,
                          onReset: tasbih.count.value > 0
                              ? () =>
                                    unawaited(tasbih.reset(saveToHistory: true))
                              : null,
                          onOpen: () => context.goNamed(Routes.dua.name),
                        ),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      QSpace.s5,
                      QSpace.s4,
                      QSpace.s5,
                      0,
                    ),
                    child: QCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: QSpace.s5,
                        vertical: QSpace.s4,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _MealTime(
                              label: l10n.sahriEndsLabel,
                              time: _formatTime(context, day.sahriEnd),
                              icon: Icons.nightlight_outlined,
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 36,
                            color: context.q.line,
                          ),
                          const SizedBox(width: QSpace.s4),
                          Expanded(
                            child: _MealTime(
                              label: l10n.iftarLabel,
                              time: _formatTime(context, day.iftar),
                              icon: Icons.wb_twilight_outlined,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(QSpace.s5),
                    child: SignalBuilder(
                      builder: (context) {
                        final windows = _store.specialWindows.value;
                        if (windows.isEmpty) {
                          return const SizedBox.shrink();
                        }
                        return SpecialTimesCard(
                          windows: windows,
                          active: _store.activeSpecial.value,
                          formatTime: (t) => _formatTime(context, t),
                          onTap: (kind) => context.pushNamed(
                            Routes.specialTimes.name,
                            extra: (
                              kind,
                              windows.where((w) => w.kind == kind).toList(),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  if (_ayah != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        QSpace.s5,
                        0,
                        QSpace.s5,
                        0,
                      ),
                      child: DailyAyahCard(
                        arabic: _ayah!.arabic,
                        translation: _ayah!.translationFor(locale.languageCode),
                        surahName: _surahName(_ayah!.surah),
                        ayahNumber: LocaleDigits.localize(
                          '${_ayah!.number}',
                          locale.languageCode,
                        ),
                        onTap: () => context.goNamed(
                          Routes.quranAyah.name,
                          pathParameters: {
                            'surah': '${_ayah!.surah}',
                            'ayah': '${_ayah!.number}',
                          },
                        ),
                      ),
                    ),
                  if (_hadithOfDay != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        QSpace.s5,
                        QSpace.s4,
                        QSpace.s5,
                        QSpace.s5,
                      ),
                      child: HadithCard(
                        text: _hadithOfDay!.translationFor(locale.languageCode),
                        narrator: _hadithOfDay!.narrator,
                        reference: _hadithOfDay!.reference,
                        onTap: () => context.pushNamed(Routes.hadith.name),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Minimal home summary of today's muhasaba track (design §4.3 hand-off
/// to §4.7): completion ring + done/total count, with a compact streak,
/// tappable into the dashboard.
final class _MuhasabaCard extends StatelessWidget {
  const _MuhasabaCard({
    required this.completion,
    required this.doneToday,
    required this.totalItems,
    required this.streak,
    required this.onTap,
    this.milestone = false,
  });

  /// Today's completion across active items, 0..1.
  final double completion;

  /// Items completed today and the active-item total (the "3/8 done" line).
  final int doneToday;
  final int totalItems;
  final int streak;
  final VoidCallback onTap;

  /// The streak just hit a celebratory length — show a small accent badge.
  final bool milestone;

  @override
  Widget build(BuildContext context) {
    final q = context.q;
    final l10n = context.l10n;
    final languageCode = Localizations.localeOf(context).languageCode;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: QCard(
        padding: const EdgeInsets.symmetric(
          horizontal: QSpace.s5,
          vertical: QSpace.s4,
        ),
        child: Row(
          children: [
            QProgressRing(
              progress: completion,
              size: 44,
              strokeWidth: 5,
              child: Text(
                LocaleDigits.localize(
                  '${(completion * 100).round()}%',
                  languageCode,
                ),
                style: QType.num_(
                  QType.caption,
                ).copyWith(fontSize: 11, color: q.ink),
              ),
            ),
            const SizedBox(width: QSpace.s4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.muhasabaTitle,
                    style: QType.titleSm.copyWith(color: q.ink),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    LocaleDigits.localize(
                      l10n.muhasabaDoneCount(doneToday, totalItems),
                      languageCode,
                    ),
                    style: QType.num_(QType.caption).copyWith(color: q.ink2),
                  ),
                  if (milestone) ...[
                    const SizedBox(height: QSpace.s2),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: QSpace.s2,
                        vertical: QSpace.s1,
                      ),
                      decoration: BoxDecoration(
                        color: q.accentSoft,
                        borderRadius: BorderRadius.circular(QRadius.full),
                      ),
                      child: Text(
                        LocaleDigits.localize(
                          l10n.streakMilestone(streak),
                          languageCode,
                        ),
                        style: QType.caption.copyWith(
                          color: q.onAccentSoft,
                          fontVariations: const [FontVariation('wght', 600)],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (streak > 0) ...[
              Icon(
                Icons.local_fire_department_outlined,
                size: 16,
                color: q.primary,
              ),
              const SizedBox(width: 2),
              Text(
                LocaleDigits.localize('$streak', languageCode),
                style: QType.num_(QType.titleSm).copyWith(color: q.ink),
              ),
              const SizedBox(width: QSpace.s2),
            ],
            Icon(Icons.chevron_right, size: 20, color: q.ink3),
          ],
        ),
      ),
    );
  }
}

final class _MealTime extends StatelessWidget {
  const _MealTime({
    required this.label,
    required this.time,
    required this.icon,
  });

  final String label;
  final String time;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final q = context.q;
    return Row(
      children: [
        Icon(icon, size: 19, color: q.ink2),
        const SizedBox(width: QSpace.s3),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: QType.caption.copyWith(color: q.ink2)),
            Text(time, style: QType.num_(QType.titleSm).copyWith(color: q.ink)),
          ],
        ),
      ],
    );
  }
}

final class _EmptyLocation extends StatelessWidget {
  const _EmptyLocation({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final q = context.q;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(QSpace.s8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            QalbMark(size: 72, color: q.ink3, accent: q.primary),
            const SizedBox(height: QSpace.s5),
            Text(
              l10n.homeSetLocationTitle,
              style: QType.title.copyWith(color: q.ink),
            ),
            const SizedBox(height: QSpace.s2),
            Text(
              l10n.homeSetLocationBody,
              textAlign: TextAlign.center,
              style: QType.body.copyWith(color: q.ink2),
            ),
            const SizedBox(height: QSpace.s6),
            QButton(
              label: l10n.homeSetLocationCta,
              icon: Icons.place_outlined,
              onPressed: () => context.pushNamed(Routes.locationPicker.name),
            ),
          ],
        ),
      ),
    );
  }
}
