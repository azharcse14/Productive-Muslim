import 'package:flutter/services.dart';

import '../domain/widget_payload.dart';

/// The single platform-channel seam to the native home-screen widgets.
/// No third-party plugin — Android writes the payload to its widget
/// SharedPreferences and repaints the AppWidget; iOS writes to the shared
/// App Group and reloads the WidgetKit timeline. Keeping this the only
/// impure call site keeps [buildWidgetPayload] fully testable.
final class WidgetBridge {
  const WidgetBridge([
    this._channel = const MethodChannel('com.qalbee.qalbee/widget'),
  ]);

  final MethodChannel _channel;

  /// Hands the formatted snapshot to the native side and asks it to repaint.
  Future<void> push(WidgetPayload payload) =>
      _channel.invokeMethod<void>('updateWidget', payload);
}
