/// Typed route names and paths — the only place paths are spelled out
/// (guide §4: no raw string paths sprinkled in widgets).
abstract final class Routes {
  static const home = (name: 'home', path: '/home');
  static const quran = (name: 'quran', path: '/quran');
  static const muhasaba = (name: 'muhasaba', path: '/muhasaba');
  static const dua = (name: 'dua', path: '/dua');
  static const more = (name: 'more', path: '/more');

  /// Settings stack lives under the More branch.
  static const settings = (name: 'settings', path: 'settings');

  /// Top-level (outside the shell) so Home and Settings can both open it
  /// full-screen without switching tabs.
  static const locationPicker = (name: 'locationPicker', path: '/location');

  /// Debug-only component gallery.
  static const gallery = (name: 'gallery', path: '/dev/gallery');
}
