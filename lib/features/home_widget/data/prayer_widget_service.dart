import 'dart:async';

import 'package:flutter/widgets.dart' show Locale;
import 'package:intl/intl.dart';

import '../../../config/app_config.dart';
import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/utils/locale_digits.dart';
import '../../my_mosque/domain/usecases/resolve_active_mosque.dart';
import '../../my_mosque/presentation/state/mosque_store.dart';
import '../../prayer_times/domain/entities/prayer_day.dart';
import '../../prayer_times/domain/usecases/get_prayer_day.dart';
import '../../prayer_times/presentation/screens/home_formatting.dart';
import '../../settings/domain/entities/prayer_params.dart';
import '../../settings/domain/repositories/zoned_clock.dart';
import '../../settings/presentation/state/settings_store.dart';
import '../../settings/presentation/widgets/setting_labels.dart';
import '../domain/next_prayer.dart';
import '../domain/widget_payload.dart';
import 'widget_bridge.dart';

/// Pushes the next-prayer snapshot to the native home-screen widgets via
/// [WidgetBridge] (plugin-free platform channel — Android AppWidget + iOS
/// WidgetKit). Updates are best-effort: a widget failure must never crash
/// the app.
final class PrayerWidgetService {
  PrayerWidgetService({
    required GetPrayerDay getPrayerDay,
    required ZonedClock clock,
    required SettingsStore settings,
    MosqueStore? mosque,
    WidgetBridge bridge = const WidgetBridge(),
  }) : _getPrayerDay = getPrayerDay,
       _clock = clock,
       _settings = settings,
       _mosque = mosque,
       _bridge = bridge;

  final GetPrayerDay _getPrayerDay;
  final ZonedClock _clock;
  final SettingsStore _settings;
  final MosqueStore? _mosque;
  final WidgetBridge _bridge;

  /// Fires [update] at the next prayer start or midnight, whichever first,
  /// so the snapshot doesn't go stale while the app stays open.
  Timer? _boundary;

  /// Recomputes the snapshot for the configured location and locale and
  /// repaints the widget. Safe to call on app open, resume, and on any
  /// location/params/locale change; re-arms itself for the next boundary.
  Future<void> update() async {
    _boundary?.cancel();
    try {
      final appSettings = _settings.settings.value;
      final code = appSettings.localeCode;
      final l10n = lookupAppLocalizations(Locale(code));
      final location = _settings.location.value;

      final days = <PrayerDay>[];
      DateTime now;
      var locationLabel = '';
      if (location != null) {
        now = _clock.nowAt(location);
        final today = DateTime(now.year, now.month, now.day);
        // The same window notifications cover; past it the widget asks the
        // user to open the app instead of showing stale times.
        final windowDays = AppConfig.notificationSchedulingWindow.inDays;
        for (var i = 0; i < windowDays; i++) {
          final d = _getPrayerDay(
            location: location,
            params: appSettings.prayerParams,
            // Calendar +i, not +24h·i: a DST day is 23h or 25h long.
            date: DateTime(today.year, today.month, today.day + i),
          ).valueOrNull;
          if (d == null) break; // Keep the days consecutive.
          days.add(d);
        }
        locationLabel = formatLocationName(location, Locale(code), l10n);
      } else {
        now = DateTime.now();
      }

      String formatTime(DateTime t) =>
          LocaleDigits.localize(DateFormat.jm(code).format(t), code);

      // Same rule as Home: Friday Dhuhr reads Jumu'ah only when the mosque
      // active at that Dhuhr has a Jumu'ah time (resolved for it alone).
      final mosqueState = _mosque?.state.value;
      bool jumuahAt(Prayer p, DateTime at) =>
          p == Prayer.dhuhr &&
          at.weekday == DateTime.friday &&
          mosqueState != null &&
          resolveActiveMosque(mosqueState, at).profile?.config.jumuah != null;

      final payload = buildWidgetPayload(
        days: days,
        nextPrayerLabel: l10n.widgetNextPrayerLabel,
        prayerName: (p, at) =>
            l10n.prayerLabelOn(p, at, jumuah: jumuahAt(p, at)),
        formatTime: formatTime,
        locationLabel: locationLabel,
        setupAction: l10n.widgetSetupAction,
        setupHint: l10n.widgetSetupHint,
        staleTitle: l10n.widgetStaleTitle,
        staleHint: l10n.widgetStaleHint,
        instantOf: location == null
            ? null
            : (wall) => _clock.utcInstantOf(location, wall),
      );

      if (days.firstOrNull case final day?) {
        final next = resolveNextPrayer(day, now).at;
        final midnight = DateTime(now.year, now.month, now.day + 1);
        // A past `next` would re-arm with zero delay in a tight loop.
        final at = next.isAfter(now) && next.isBefore(midnight)
            ? next
            : midnight;
        // Real instants: wall times across a DST shift aren't 1:1.
        final wait = location == null
            ? at.difference(now)
            : _clock
                  .utcInstantOf(location, at)
                  .difference(_clock.utcInstantOf(location, now));
        _boundary = Timer(
          wait + const Duration(seconds: 1),
          () => unawaited(update()),
        );
      }

      await _bridge.push(payload);
    } on Object {
      // Best-effort: never let a widget update surface as an app error.
    }
  }
}
