/// Seam over the url_launcher plugin so use cases (and tests) never touch
/// the static plugin API directly — mirrors [DeviceLocationSource].
abstract interface class ExternalLauncher {
  /// Opens [uri] in an external app (the Maps app or a browser).
  /// Returns whether the launch was accepted by the platform.
  Future<bool> launch(Uri uri);
}
