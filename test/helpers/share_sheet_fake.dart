import 'dart:typed_data';

import 'package:productive_muslim/features/share/domain/share_sheet.dart';

/// Records shared content instead of opening the OS share sheet.
final class FakeShareSheet implements ShareSheet {
  final shared = <String>[];
  final images = <(Uint8List, String)>[];

  @override
  Future<void> shareText(String text) async => shared.add(text);

  @override
  Future<void> shareImage(Uint8List png, String text) async =>
      images.add((png, text));
}
