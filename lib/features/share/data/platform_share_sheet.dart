import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import '../domain/share_sheet.dart';

/// [ShareSheet] over MainActivity's / AppDelegate's `share` channel:
/// Android `Intent.ACTION_SEND` chooser, iOS `UIActivityViewController`.
final class PlatformShareSheet implements ShareSheet {
  PlatformShareSheet({
    MethodChannel channel = const MethodChannel(
      'com.productivemuslim.app/share',
    ),
    Future<Directory> Function() cacheDir = getTemporaryDirectory,
    DateTime Function() now = DateTime.now,
  }) : _channel = channel,
       _cacheDir = cacheDir,
       _now = now;

  final MethodChannel _channel;
  final Future<Directory> Function() _cacheDir;
  final DateTime Function() _now;

  /// Images go to `<cache>/share/`, the only folder Android's FileProvider
  /// exposes (`res/xml/share_file_paths.xml`).
  static const shareDir = 'share';

  @override
  Future<void> shareText(String text) =>
      _invoke(() => _channel.invokeMethod<void>('shareText', text));

  /// Each share gets a fresh file name, so a target app still reading the
  /// previous image never sees it replaced; older images are deleted
  /// first, so the folder holds one image at a time.
  @override
  Future<bool> shareImage(Uint8List png, String text) => _invoke(() async {
    final dir = Directory('${(await _cacheDir()).path}/$shareDir');
    if (dir.existsSync()) {
      await dir.delete(recursive: true);
    }
    await dir.create(recursive: true);
    final file = File(
      '${dir.path}/productive_muslim_${_now().millisecondsSinceEpoch}.png',
    );
    await file.writeAsBytes(png, flush: true);
    await _channel.invokeMethod<void>('shareImage', {
      'path': file.path,
      'text': text,
    });
  });

  /// Runs [share]; false (logged) when the native side is missing or
  /// fails, or the file can't be written.
  Future<bool> _invoke(Future<void> Function() share) async {
    try {
      await share();
      return true;
    } on PlatformException catch (e) {
      debugPrint('share: not shown: $e');
    } on MissingPluginException catch (e) {
      debugPrint('share: not shown: $e');
    } on FileSystemException catch (e) {
      debugPrint('share: image not written: $e');
    }
    return false;
  }
}
