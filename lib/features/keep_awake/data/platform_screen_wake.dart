import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../domain/screen_wake.dart';

/// [ScreenWake] over MainActivity's / AppDelegate's `screen` channel:
/// Android `FLAG_KEEP_SCREEN_ON` on the activity window, iOS
/// `UIApplication.isIdleTimerDisabled`. Best-effort: a failure only means
/// the screen may dim as usual.
final class PlatformScreenWake implements ScreenWake {
  PlatformScreenWake({
    MethodChannel channel = const MethodChannel(
      'com.productivemuslim.app/screen',
    ),
  }) : _channel = channel;

  final MethodChannel _channel;

  /// Open holds; the native flag follows `_holds > 0`. A screen replacing
  /// another opens before the old one disposes, so a plain on/off would
  /// switch it off under the new screen.
  int _holds = 0;

  @override
  Future<void> hold({required bool on}) async {
    final wasOn = _holds > 0;
    _holds = on ? _holds + 1 : (wasOn ? _holds - 1 : 0);
    final isOn = _holds > 0;
    if (wasOn == isOn) {
      return;
    }
    try {
      await _channel.invokeMethod<void>('keepOn', isOn);
    } on PlatformException catch (e) {
      debugPrint('screen wake: not set: $e');
    } on MissingPluginException catch (e) {
      debugPrint('screen wake: not set: $e');
    }
  }
}
