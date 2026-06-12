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

/// Orchestrates a full reschedule: compute the next three prayer days,
/// build the ~48h plan, and hand it to the scheduler. Called on app open
/// and whenever settings/location/jamaat change (guide §5).
final class RescheduleNotifications {
  const RescheduleNotifications({
    required GetPrayerDay getPrayerDay,
    required NotificationScheduler scheduler,
    required ZonedClock clock,
  })  : _getPrayerDay = getPrayerDay,
        _scheduler = scheduler,
        _clock = clock;

  final GetPrayerDay _getPrayerDay;
  final NotificationScheduler _scheduler;
  final ZonedClock _clock;

  Future<Result<int>> call({
    required AppSettings settings,
    required NotificationTexts texts,
    JamaatConfig jamaat = JamaatConfig.none,
  }) async {
    final location = settings.location;
    if (location == null) {
      await _scheduler.cancelAll();
      return const Result.success(0);
    }

    final now = _clock.nowAt(location);
    final days = <PrayerDay>[];
    for (var offset = 0; offset < 3; offset++) {
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
      jamaat: jamaat,
    );
    final scheduled = await _scheduler.reschedule(plan, texts);
    return scheduled.map((_) => plan.length);
  }
}

/// Re-exported for callers that only need the plan size for diagnostics.
typedef NotificationPlan = List<NotificationItem>;
