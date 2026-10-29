/// Live session as reported by the native side.
typedef FocusStatus = ({bool active, bool strict, bool nafs, DateTime? until});

/// What the jamaat focus settings page needs from the native focus engine
/// (Android only): session status, ending a session, and the two
/// permissions it relies on.
abstract interface class JamaatFocusControl {
  /// [toWall] converts the native end instant to the location wall clock.
  Future<FocusStatus> status({
    required DateTime Function(DateTime instant) toWall,
  });

  /// Ends a running non-strict session now.
  Future<void> end();

  /// "Do Not Disturb access" — needed to silence the phone.
  Future<bool> hasSilencePermission();
  Future<void> requestSilencePermission();

  /// False in a build without the app-blocking service.
  Future<bool> isBlockingAvailable();

  /// Accessibility service — needed to block other apps.
  Future<bool> hasBlockPermission();
  Future<void> requestBlockPermission();
}
