import 'dart:async';

import 'package:flutter/widgets.dart' show Locale;
import 'package:intl/intl.dart';

import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/utils/locale_digits.dart';
import '../../prayer_times/domain/entities/prayer_day.dart';
import '../../prayer_times/domain/usecases/get_prayer_day.dart';
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
    WidgetBridge bridge = const WidgetBridge(),
  })  : _getPrayerDay = getPrayerDay,
        _clock = clock,
        _settings = settings,
        _bridge = bridge;

  final GetPrayerDay _getPrayerDay;
  final ZonedClock _clock;
  final SettingsStore _settings;
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

      PrayerDay? day;
      DateTime now;
      var locationLabel = '';
      if (location != null) {
        now = _clock.nowAt(location);
        final today = DateTime(now.year, now.month, now.day);
        day = _getPrayerDay(
          location: location,
          params: appSettings.prayerParams,
          date: today,
        ).valueOrNull;
        locationLabel = location.displayName;
      } else {
        now = DateTime.now();
      }

      String formatTime(DateTime t) => LocaleDigits.localize(
            DateFormat.jm(code).format(t),
            code,
          );

      final payload = buildWidgetPayload(
        day: day,
        now: now,
        nextPrayerLabel: l10n.widgetNextPrayerLabel,
        prayerName: l10n.prayerLabel,
        formatTime: formatTime,
        locationLabel: locationLabel,
      );

      if (day != null) {
        final next = resolveNextPrayer(day, now).at;
        final midnight = DateTime(now.year, now.month, now.day + 1);
        // A past `next` would re-arm with zero delay in a tight loop.
        final at = next.isAfter(now) && next.isBefore(midnight)
            ? next
            : midnight;
        _boundary = Timer(
          at.difference(now) + const Duration(seconds: 1),
          () => unawaited(update()),
        );
      }

      await _bridge.push(payload);
    } on Object {
      // Best-effort: never let a widget update surface as an app error.
    }
  }
}
