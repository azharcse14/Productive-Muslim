import '../../../../core/utils/result.dart';
import '../../../my_mosque/domain/entities/jamaat_config.dart';
import '../../../prayer_times/domain/entities/prayer_day.dart';
import '../../../prayer_times/domain/usecases/get_prayer_day.dart';
import '../../../settings/domain/entities/app_settings.dart';
import '../../../settings/domain/repositories/zoned_clock.dart';
import '../entities/notification_item.dart';
import '../entities/notification_texts.dart';
import '../repositories/notification_scheduler.dart';
import 'build_notification_plan.dart';

/// Orchestrates a full reschedule: compute the prayer days covering
/// [window], build the plan (capped at [maxItems], ending with a keep-alive
/// nudge), and hand it to the scheduler. Called on app open/resume and
/// whenever settings/location/jamaat change (guide §5).
final class RescheduleNotifications {
  const RescheduleNotifications({
    required GetPrayerDay getPrayerDay,
    required NotificationScheduler scheduler,
    required ZonedClock clock,
    Duration window = const Duration(hours: 48),
    int? maxItems,
  })  : _getPrayerDay = getPrayerDay,
        _scheduler = scheduler,
        _clock = clock,
        _window = window,
        _maxItems = maxItems;

  final GetPrayerDay _getPrayerDay;
  final NotificationScheduler _scheduler;
  final ZonedClock _clock;
  final Duration _window;
  final int? _maxItems;

  /// Returns the scheduled plan (empty when there is no location).
  /// [jamaatAt], when given, resolves the jamaat config for the location's
  /// current wall clock and takes precedence over [jamaat].
  Future<Result<NotificationPlan>> call({
    required AppSettings settings,
    required NotificationTexts texts,
    JamaatConfig jamaat = JamaatConfig.none,
    JamaatConfig Function(DateTime now)? jamaatAt,
  }) async {
    final location = settings.location;
    if (location == null) {
      await _scheduler.cancelAll();
      return const Result.success([]);
    }

    final now = _clock.nowAt(location);
    final days = <PrayerDay>[];
    // Whole days in the window, plus today and one spare for a late start.
    final dayCount = (_window.inHours / 24).ceil() + 2;
    for (var offset = 0; offset < dayCount; offset++) {
      final result = _getPrayerDay(
        location: location,
        params: settings.prayerParams,
        date: DateTime(now.year, now.month, now.day + offset),
      );
      switch (result) {
        case Success<PrayerDay>(:final value):
          days.add(value);
        case FailureResult<PrayerDay>(:final failure):
          return Result.failure(failure);
      }
    }

    final plan = buildNotificationPlan(
      from: now,
      days: days,
      matrix: settings.notifications,
      jamaat: jamaatAt?.call(now) ?? jamaat,
      window: _window,
      maxItems: _maxItems,
      keepAlive: true,
      hijriOffsetDays: settings.hijriOffsetDays,
    );
    final scheduled = await _scheduler.reschedule(plan, texts);
    return scheduled.map((_) => plan);
  }
}

typedef NotificationPlan = List<NotificationItem>;
