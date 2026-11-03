import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../core/utils/locale_digits.dart';

import '../../settings/domain/entities/location_config.dart';
import '../domain/entities/notification_texts.dart';
import '../domain/repositories/jamaat_focus_control.dart';
import '../domain/usecases/build_focus_windows.dart';

/// Android-only seam to the native jamaat focus engine (JamaatFocus.kt):
/// it owns the alarms, Do Not Disturb, and the app-blocking accessibility
/// service, so sessions start and end with the app closed.
final class JamaatFocusBridge implements JamaatFocusControl {
  const JamaatFocusBridge([
    this._channel = const MethodChannel('com.productivemuslim.app/focus'),
  ]);

  final MethodChannel _channel;

  /// Replaces the planned sessions. [toUtc] converts the location wall
  /// clock to an instant. With [enabled] false a running non-strict
  /// session ends; a strict one always runs out its time. In a build without
  /// the blocking service, [block] and [nafs] are sent as off (the stored
  /// settings are left alone). A nafs session's end is only known natively
  /// (set when the shake comes): native formats it in the app's time format
  /// on [location]'s clock (a manual city's zone; the device's for GPS).
  Future<void> schedule({
    required List<FocusWindow> windows,
    required bool enabled,
    required bool block,
    required bool strict,
    required bool nafs,
    required Duration nafsDuration,
    required NotificationTexts texts,
    required DateTime Function(DateTime wall) toUtc,
    LocationConfig? location,
  }) async {
    final canBlock = await isBlockingAvailable();
    final clock = _format(texts.localeCode);
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
            w.key,
            // Session end as the app shows it (app language, city wall
            // clock): the native lock text uses it over the device's own.
            if (_endLabel(w.end, texts.localeCode) case final label?) label,
          ],
      ],
      'title': texts.channelFocusName,
      'body': texts.focusLockBody,
      'bodyUntil': texts.focusLockBodyUntil,
      'endAction': texts.focusEndAction,
      'channelName': texts.channelFocusName,
      'nafs.title': texts.nafsLockTitle,
      'nafs.bodyUntil': texts.nafsLockBodyUntil,
      // The app's time format, for ends only native knows (nafs).
      'clockPattern': clock?.pattern ?? '',
      'clockAm': clock?.dateSymbols.AMPMS.first ?? '',
      'clockPm': clock?.dateSymbols.AMPMS.last ?? '',
      'clockDigits': LocaleDigits.localize('0123456789', texts.localeCode),
      'clockZone': switch (location) {
        ManualCityLocation(:final city) => city.timezone,
        _ => '',
      },
    });
  }

  /// [end] (wall clock) as the app formats times; null when unknown or the
  /// locale's date data isn't loaded — native then formats it itself.
  static String? _endLabel(DateTime? end, String localeCode) {
    if (end == null) {
      return null;
    }
    return switch (_format(localeCode)) {
      final format? => LocaleDigits.localize(format.format(end), localeCode),
      null => null,
    };
  }

  /// The app's time format; null when the locale is unknown or its date
  /// data isn't loaded.
  static DateFormat? _format(String localeCode) {
    if (localeCode.isEmpty) {
      return null;
    }
    try {
      final format = DateFormat.jm(localeCode);
      format.format(DateTime(2000)); // missing date data throws here, not later
      return format;
    } on ArgumentError {
      return null;
    } on Exception {
      return null; // LocaleDataException: date symbols not initialized
    }
  }

  /// [toWall] converts the native end instant to the location wall clock
  /// (the clock the app shows), mirroring [schedule]'s `toUtc`.
  @override
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
  @override
  Future<void> end() => _channel.invokeMethod<void>('end');

  /// "Do Not Disturb access" — needed to silence the phone.
  @override
  Future<bool> hasSilencePermission() async =>
      await _channel.invokeMethod<bool>('hasDndAccess') ?? false;

  @override
  Future<void> requestSilencePermission() =>
      _channel.invokeMethod<void>('requestDndAccess');

  /// False in a build made with `focusBlocking=false`: the app-blocking
  /// service isn't in the manifest, so lock-the-phone and nafs lock can't
  /// work. Unknown (no native answer) counts as available.
  @override
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
  @override
  Future<bool> hasBlockPermission() async =>
      await _channel.invokeMethod<bool>('hasBlockAccess') ?? false;

  @override
  Future<void> requestBlockPermission() =>
      _channel.invokeMethod<void>('requestBlockAccess');
}
