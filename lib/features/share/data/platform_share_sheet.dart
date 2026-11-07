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

  /// How long a shared image stays: target apps may read it lazily (a
  /// draft, a slow upload), so only images older than this are pruned.
  static const keepFor = Duration(hours: 1);

  static final _name = RegExp(r'productive_muslim_(\d+)\.png$');

  /// Each share gets a fresh file name, so a target app still reading an
  /// earlier image never sees it replaced or deleted; only images older
  /// than [keepFor] (by the time in their name) are removed.
  @override
  Future<bool> shareImage(Uint8List png, String text) => _invoke(() async {
    final dir = Directory('${(await _cacheDir()).path}/$shareDir');
    final nowMs = _now().millisecondsSinceEpoch;
    await _prune(dir, nowMs - keepFor.inMilliseconds);
    await dir.create(recursive: true);
    final file = File('${dir.path}/productive_muslim_$nowMs.png');
    await file.writeAsBytes(png, flush: true);
    await _channel.invokeMethod<void>('shareImage', {
      'path': file.path,
      'text': text,
    });
  });

  /// Deletes entries of [dir] named before [cutoffMs] (or not named by us).
  /// Best effort: a file that can't be removed doesn't stop the share.
  static Future<void> _prune(Directory dir, int cutoffMs) async {
    if (!dir.existsSync()) {
      return;
    }
    for (final entry in dir.listSync()) {
      final ms = _name.firstMatch(entry.path)?.group(1);
      if (ms != null && int.parse(ms) >= cutoffMs) {
        continue;
      }
      try {
        await entry.delete(recursive: true);
      } on FileSystemException catch (e) {
        debugPrint('share: old image not removed: $e');
      }
    }
  }

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
