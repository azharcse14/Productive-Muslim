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
  static const notificationSettings =
      (name: 'notificationSettings', path: 'notifications');

  /// Top-level (outside the shell) so Home and Settings can both open it
  /// full-screen without switching tabs.
  static const locationPicker = (name: 'locationPicker', path: '/location');

  /// Top-level: reachable from Home's "Set jamaat" and the More tab.
  static const myMosque = (name: 'myMosque', path: '/mosque');

  /// Top-level full-screen compass (Home shortcut + More tab).
  static const qibla = (name: 'qibla', path: '/qibla');

  /// Explanatory detail page for the Home forbidden/nafl times cards.
  static const specialTimes = (name: 'specialTimes', path: '/special-times');

  /// Reader under the Quran branch; deep-link friendly
  /// (`/quran/:surah/:ayah` for notification taps — guide §4).
  static const quranReader = (name: 'quranReader', path: ':surah');
  static const quranAyah = (name: 'quranAyah', path: ':surah/:ayah');

  /// More-tab destinations (top-level pushes).
  static const ramadan = (name: 'ramadan', path: '/ramadan');
  static const calendar = (name: 'calendar', path: '/calendar');

  /// Zakat calculator — top-level so it's reachable directly from More
  /// (year-round obligation) as well as from the Ramadan hub.
  static const zakat = (name: 'zakat', path: '/zakat');

  /// Hadith collection — reachable from More and the Home daily card.
  static const hadith = (name: 'hadith', path: '/hadith');

  /// One bundled hadith by id (the Home "Hadith of the day" card).
  static const hadithItem = (name: 'hadithItem', path: 'item/:id');

  /// Ruqyah — Qur'anic & prophetic protection/healing (More tab).
  static const ruqyah = (name: 'ruqyah', path: '/ruqyah');

  /// Asmaul Husna memorization quiz (entered from the names screen).
  static const asmaQuiz = (name: 'asmaQuiz', path: '/asma-quiz');

  /// Sunnah / nafl fasting tracker — recommended days + personal log.
  static const fasting = (name: 'fasting', path: '/fasting');

  /// Islamic expense tracker — monthly hisab, no israf (More tab).
  static const expenses = (name: 'expenses', path: '/expenses');

  /// Achievements / badges (More tab + muhasaba summary).
  static const achievements = (name: 'achievements', path: '/achievements');

  /// Islamic calculators hub (More tab) and its individual tools.
  static const calculators = (name: 'calculators', path: '/calculators');
  static const fitra = (name: 'fitra', path: '/calculators/fitra');
  static const qaza = (name: 'qaza', path: '/calculators/qaza');
  static const faraid = (name: 'faraid', path: '/calculators/faraid');
  static const age = (name: 'age', path: '/calculators/age');

  /// First-run flow and the app-lock gate (outside the shell).
  static const splash = (name: 'splash', path: '/splash');
  static const onboarding = (name: 'onboarding', path: '/onboarding');
  static const lock = (name: 'lock', path: '/lock');

  /// Debug-only component gallery.
  static const gallery = (name: 'gallery', path: '/dev/gallery');
}
