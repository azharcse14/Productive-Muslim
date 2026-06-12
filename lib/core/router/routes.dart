/// Typed route names and paths — the only place paths are spelled out
/// (guide §4: no raw string paths sprinkled in widgets).
abstract final class Routes {
  static const home = (name: 'home', path: '/home');
  static const quran = (name: 'quran', path: '/quran');
  static const muhasaba = (name: 'muhasaba', path: '/muhasaba');
  static const dua = (name: 'dua', path: '/dua');
  static const more = (name: 'more', path: '/more');

  /// Debug-only component gallery.
  static const gallery = (name: 'gallery', path: '/dev/gallery');
}
