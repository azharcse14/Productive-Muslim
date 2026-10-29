import 'package:flutter/services.dart';

import '../domain/entities/notification_texts.dart';
import '../domain/usecases/build_focus_windows.dart';

/// Live session as reported by the native side.
typedef FocusStatus = ({bool active, bool strict, bool nafs, DateTime? until});

/// Android-only seam to the native jamaat focus engine (JamaatFocus.kt):
/// it owns the alarms, Do Not Disturb, and the app-blocking accessibility
/// service, so sessions start and end with the app closed.
final class JamaatFocusBridge {
  const JamaatFocusBridge([
    this._channel = const MethodChannel('com.productivemuslim.app/focus'),
  ]);

  final MethodChannel _channel;

  /// Replaces the planned sessions. [toUtc] converts the location wall
  /// clock to an instant. With [enabled] false a running non-strict
  /// session ends; a strict one always runs out its time. In a build without
  /// the blocking service, [block] and [nafs] are sent as off (the stored
  /// settings are left alone).
  Future<void> schedule({
    required List<FocusWindow> windows,
    required bool enabled,
    required bool block,
    required bool strict,
    required bool nafs,
    required Duration nafsDuration,
    required NotificationTexts texts,
    required DateTime Function(DateTime wall) toUtc,
  }) async {
    final canBlock = await isBlockingAvailable();
    await _channel.invokeMethod<void>('schedule', {
      'enabled': enabled,
      'block': block && canBlock,
      'strict': strict,
      'nafs': nafs && canBlock,
      'nafsMinutes': nafsDuration.inMinutes,
      'windows': [
        for (final w in windows)
          [
            toUtc(w.start).millisecondsSinceEpoch,
            if (w.end case final end?)
              toUtc(end).millisecondsSinceEpoch
            else
              -1,
          ],
      ],
      'title': texts.channelFocusName,
      'body': texts.focusLockBody,
      'bodyUntil': texts.focusLockBodyUntil,
      'endAction': texts.focusEndAction,
      'channelName': texts.channelFocusName,
      'nafs.title': texts.nafsLockTitle,
      'nafs.bodyUntil': texts.nafsLockBodyUntil,
    });
  }

  /// [toWall] converts the native end instant to the location wall clock
  /// (the clock the app shows), mirroring [schedule]'s `toUtc`.
  Future<FocusStatus> status({
    required DateTime Function(DateTime instant) toWall,
  }) async {
    final map = await _channel.invokeMapMethod<String, Object?>('status');
    final until = map?['until'] as int? ?? -1;
    return (
      active: map?['active'] == true,
      strict: map?['strict'] == true,
      nafs: map?['nafs'] == true,
      until: until > 0
          ? toWall(DateTime.fromMillisecondsSinceEpoch(until, isUtc: true))
          : null,
    );
  }

  /// Ends a running non-strict session now.
  Future<void> end() => _channel.invokeMethod<void>('end');

  /// "Do Not Disturb access" — needed to silence the phone.
  Future<bool> hasSilencePermission() async =>
      await _channel.invokeMethod<bool>('hasDndAccess') ?? false;

  Future<void> requestSilencePermission() =>
      _channel.invokeMethod<void>('requestDndAccess');

  /// False in a build made with `focusBlocking=false`: the app-blocking
  /// service isn't in the manifest, so lock-the-phone and nafs lock can't
  /// work. Unknown (no native answer) counts as available.
  Future<bool> isBlockingAvailable() async {
    try {
      return await _channel.invokeMethod<bool>('isBlockingAvailable') ?? true;
    } on PlatformException {
      return true;
    } on MissingPluginException {
      return true;
    }
  }

  /// Accessibility service — needed to block other apps.
  Future<bool> hasBlockPermission() async =>
      await _channel.invokeMethod<bool>('hasBlockAccess') ?? false;

  Future<void> requestBlockPermission() =>
      _channel.invokeMethod<void>('requestBlockAccess');
}
