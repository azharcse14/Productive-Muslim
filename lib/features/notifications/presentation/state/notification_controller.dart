import 'dart:async';
import 'dart:ui' show Locale;

import 'package:signals_flutter/signals_flutter.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../daily_content/domain/usecases/pick_daily_content.dart';
import '../../../my_mosque/presentation/state/mosque_store.dart';
import '../../../settings/domain/entities/prayer_params.dart';
import '../../../settings/presentation/state/settings_store.dart';
import '../../../settings/presentation/widgets/setting_labels.dart';
import '../../domain/entities/notification_texts.dart';
import '../../domain/repositories/notification_scheduler.dart';
import '../../domain/usecases/reschedule_notifications.dart';

/// App-scoped: reschedules the ~48h plan on app open and whenever
/// location / prayer params / matrix / locale change (guide §5).
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
  Timer? _debounce;
  var _started = false;

  Future<void> start() async {
    if (_started) {
      return;
    }
    _started = true;
    await _scheduler.initialize(_texts());
    await _rescheduleNow();
    _stopEffect = effect(() {
      // Subscribe to everything the plan depends on.
      _settings.location.value;
      _settings.prayerParams.value;
      _settings.settings.value.notifications;
      _settings.settings.value.localeCode;
      _mosque.activeConfig.value;
      _debounce?.cancel();
      _debounce = Timer(
        const Duration(milliseconds: 400),
        () => unawaited(_rescheduleNow()),
      );
    });
  }

  Future<void> _rescheduleNow() async {
    await _reschedule(
      settings: _settings.settings.value,
      texts: _texts(),
      jamaat: _mosque.activeConfig.value,
    );
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
    _debounce?.cancel();
    _stopEffect?.call();
  }
}
