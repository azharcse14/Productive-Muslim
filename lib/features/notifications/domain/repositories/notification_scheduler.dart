import '../../../../core/utils/result.dart';
import '../entities/notification_item.dart';
import '../entities/notification_texts.dart';

/// Permission state for the in-app education states (design §15).
enum NotificationPermission { granted, denied, notRequested }

/// All scheduling goes through this single interface (guide §5).
/// The data layer owns the plugin; domain/presentation never touch it.
abstract interface class NotificationScheduler {
  /// One-time plugin setup ([texts] localizes action buttons/categories).
  Future<void> initialize(NotificationTexts texts);

  Future<NotificationPermission> permissionStatus();

  /// Shows the OS prompt (after in-app priming). Returns the new status.
  Future<NotificationPermission> requestPermission();

  /// Android 12+: whether exact alarms are permitted (azan precision).
  Future<bool> canScheduleExactAlarms();

  /// Opens the OS exact-alarm consent screen (Android; no-op elsewhere).
  Future<void> requestExactAlarmPermission();

  /// Replaces the entire pending schedule with [items].
  Future<Result<void>> reschedule(
    List<NotificationItem> items,
    NotificationTexts texts,
  );

  Future<void> cancelAll();
}
