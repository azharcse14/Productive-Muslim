import 'dart:async';
import 'dart:ui' show Locale;

import 'package:flutter/widgets.dart' show AppLifecycleListener;
import 'package:signals_flutter/signals_flutter.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../daily_content/domain/usecases/pick_daily_content.dart';
import '../../../my_mosque/domain/entities/jamaat_config.dart';
import '../../../my_mosque/domain/usecases/resolve_active_mosque.dart';
import '../../../my_mosque/presentation/state/mosque_store.dart';
import '../../../settings/domain/entities/prayer_params.dart';
import '../../../settings/presentation/state/settings_store.dart';
import '../../../settings/presentation/widgets/setting_labels.dart';
import '../../domain/entities/notification_item.dart';
import '../../domain/entities/notification_texts.dart';
import '../../domain/repositories/notification_scheduler.dart';
import '../../domain/usecases/reschedule_notifications.dart';

/// App-scoped: reschedules the plan on app open, on every resume from
/// background, and whenever location / prayer params / matrix / locale
/// change (guide §5).
final class NotificationController {
  NotificationController({
    required RescheduleNotifications reschedule,
    required NotificationScheduler scheduler,
    required SettingsStore settings,
    required MosqueStore mosque,
  })  : _reschedule = reschedule,
        _scheduler = scheduler,
        _settings = settings,
        _mosque = mosque;

  final RescheduleNotifications _reschedule;
  final NotificationScheduler _scheduler;
  final SettingsStore _settings;
  final MosqueStore _mosque;

  EffectCleanup? _stopEffect;
  AppLifecycleListener? _lifecycle;
  Timer? _debounce;
  var _started = false;

  /// The reschedule currently running. Runs are serialized so a stale run
  /// can never schedule after a newer run's cancelAll.
  Future<void>? _inFlight;

  final _scheduledUntil = signal<DateTime?>(null);

  /// Wall-clock time (at the configured location) of the last scheduled
  /// reminder, excluding the keep-alive nudge; null when nothing is planned.
  ReadonlySignal<DateTime?> get scheduledUntil => _scheduledUntil;

  Future<void> start() async {
    if (_started) {
      return;
    }
    _started = true;
    // Init + first run count as in flight, so a change landing meanwhile
    // (picked up by the effect below) queues behind them instead of being
    // lost or racing the plugin init.
    final boot = _inFlight = () async {
      await _scheduler.initialize(_texts());
      await _run();
    }();
    var first = true;
    _stopEffect = effect(() {
      // Subscribe to everything the plan depends on.
      _settings.location.value;
      _settings.prayerParams.value;
      _settings.settings.value.notifications;
      _settings.settings.value.localeCode;
      _settings.settings.value.hijriOffsetDays;
      _mosque.state.value; // profiles, rules, mode, override
      // The first run only subscribes — boot schedules with these values.
      if (first) {
        first = false;
        return;
      }
      _scheduleDebounced();
    });
    // The OS holds a finite schedule; refill it whenever the user returns.
    _lifecycle = AppLifecycleListener(onResume: _scheduleDebounced);
    try {
      await boot;
    } finally {
      if (identical(_inFlight, boot)) {
        _inFlight = null;
      }
    }
  }

  void _scheduleDebounced() {
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 400),
      () => unawaited(_rescheduleNow()),
    );
  }

  Future<void> _rescheduleNow() async {
    for (var running = _inFlight; running != null; running = _inFlight) {
      try {
        await running;
      } on Object catch (_) {
        // A failed earlier run (or boot) is its caller's error; this run
        // still goes ahead with the latest state.
      }
    }
    final run = _inFlight = _run();
    try {
      await run;
    } finally {
      if (identical(_inFlight, run)) {
        _inFlight = null;
      }
    }
  }

  Future<void> _run() async {
    // ponytail: jamaat resolves once for "now", so a schedule rule switching
    // mosques mid-window applies on the next reschedule (resume/edit), not
    // per prayer. Resolve per item in buildNotificationPlan if that matters.
    final result = await _reschedule(
      settings: _settings.settings.value,
      texts: _texts(),
      jamaatAt: (now) =>
          resolveActiveMosque(_mosque.state.value, now).profile?.config ??
          JamaatConfig.none,
    );
    final plan = result.valueOrNull;
    if (plan != null) {
      _scheduledUntil.value = plan
          .where((i) => i.kind != NotificationKind.keepAlive)
          .lastOrNull
          ?.at;
    }
  }

  bool get _isDailyDua =>
      _settings.settings.value.notifications.dailyReminderKind ==
      DailyContentKind.dua;

  NotificationTexts _texts() {
    final l10n = lookupAppLocalizations(
      Locale(_settings.settings.value.localeCode),
    );
    return NotificationTexts(
      azanTitle: l10n.notifAzanTitle('{prayer}', '{time}'),
      azanBody: l10n.notifAzanBody('{prayer}'),
      jamaatTitle: l10n.notifJamaatTitle('{prayer}'),
      jamaatBody: l10n.notifJamaatBody('{time}'),
      sahriTitle: l10n.notifSahriTitle,
      sahriBody: l10n.notifSahriBody('{time}'),
      iftarTitle: l10n.notifIftarTitle,
      iftarBody: l10n.notifIftarBody('{time}'),
      muhasabaTitle: l10n.notifMuhasabaTitle,
      muhasabaBody: l10n.notifMuhasabaBody,
      dailyReminderTitle: _isDailyDua
          ? l10n.notifDailyDuaTitle
          : l10n.notifDailyHadithTitle,
      dailyReminderBody: _isDailyDua
          ? l10n.notifDailyDuaBody
          : l10n.notifDailyHadithBody,
      dailyReminderRoute: _isDailyDua ? '/dua' : '/hadith',
      keepAliveTitle: l10n.notifKeepAliveTitle,
      keepAliveBody: l10n.notifKeepAliveBody,
      markAsPrayedAction: l10n.notifMarkPrayed,
      channelAzanName: l10n.channelAzan,
      channelRemindersName: l10n.channelReminders,
      channelSilentName: l10n.channelSilent,
      prayerNames: {
        for (final prayer in Prayer.values) prayer.name: l10n.prayerLabel(prayer),
      },
    );
  }

  void dispose() {
    _lifecycle?.dispose();
    _debounce?.cancel();
    _stopEffect?.call();
  }
}
