/// Hands plain text to the OS share sheet (Android chooser, iOS activity
/// sheet). Best-effort: a missing or failing native side shares nothing.
abstract interface class ShareSheet {
  Future<void> shareText(String text);
}
