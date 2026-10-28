import 'package:url_launcher/url_launcher.dart';

import '../domain/external_launcher.dart';

/// [ExternalLauncher] backed by the url_launcher plugin. Always launches in
/// an external application so the Maps app (or the browser) takes over rather
/// than an in-app web view.
final class UrlLauncherExternal implements ExternalLauncher {
  const UrlLauncherExternal();

  /// False instead of throwing when the platform rejects the launch
  /// (url_launcher throws a PlatformException for some failures).
  @override
  Future<bool> launch(Uri uri) async {
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } on Exception {
      return false;
    }
  }
}
