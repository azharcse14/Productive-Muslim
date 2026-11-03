import 'dart:typed_data';

/// Hands content to the OS share sheet (Android chooser, iOS activity
/// sheet). Best-effort: a missing or failing native side shares nothing.
abstract interface class ShareSheet {
  Future<void> shareText(String text);

  /// Shares [png] (PNG-encoded bytes) as an image, with [text] as the
  /// caption where the target app takes one. False when the image could
  /// not be written or the sheet not shown, so the caller can say so.
  Future<bool> shareImage(Uint8List png, String text);
}
