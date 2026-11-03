import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../domain/share_sheet.dart';

/// [ShareSheet] over MainActivity's / AppDelegate's `share` channel:
/// Android `Intent.ACTION_SEND` chooser, iOS `UIActivityViewController`.
final class PlatformShareSheet implements ShareSheet {
  PlatformShareSheet({
    MethodChannel channel = const MethodChannel(
      'com.productivemuslim.app/share',
    ),
  }) : _channel = channel;

  final MethodChannel _channel;

  @override
  Future<void> shareText(String text) async {
    try {
      await _channel.invokeMethod<void>('shareText', text);
    } on PlatformException catch (e) {
      debugPrint('share: not shown: $e');
    } on MissingPluginException catch (e) {
      debugPrint('share: not shown: $e');
    }
  }
}
