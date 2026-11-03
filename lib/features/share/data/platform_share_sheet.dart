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
  }) : _channel = channel,
       _cacheDir = cacheDir;

  final MethodChannel _channel;
  final Future<Directory> Function() _cacheDir;

  /// Images go to `<cache>/share/`, the only folder Android's FileProvider
  /// exposes (`res/xml/file_paths.xml`). One fixed name: each share
  /// replaces the last, so the cache never grows.
  static const shareDir = 'share';
  static const imageName = 'productive_muslim_share.png';

  @override
  Future<void> shareText(String text) =>
      _invoke(() => _channel.invokeMethod<void>('shareText', text));

  @override
  Future<void> shareImage(Uint8List png, String text) => _invoke(() async {
    final dir = Directory('${(await _cacheDir()).path}/$shareDir');
    await dir.create(recursive: true);
    final file = File('${dir.path}/$imageName');
    await file.writeAsBytes(png, flush: true);
    await _channel.invokeMethod<void>('shareImage', {
      'path': file.path,
      'text': text,
    });
  });

  Future<void> _invoke(Future<void> Function() share) async {
    try {
      await share();
    } on PlatformException catch (e) {
      debugPrint('share: not shown: $e');
    } on MissingPluginException catch (e) {
      debugPrint('share: not shown: $e');
    } on FileSystemException catch (e) {
      debugPrint('share: image not written: $e');
    }
  }
}
