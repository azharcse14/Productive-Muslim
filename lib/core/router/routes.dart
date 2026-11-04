/// Typed route names and paths — the only place paths are spelled out
/// (guide §4: no raw string paths sprinkled in widgets).
abstract final class Routes {
  static const home = (name: 'home', path: '/home');
  static const quran = (name: 'quran', path: '/quran');
  static const muhasaba = (name: 'muhasaba', path: '/muhasaba');
  static const dua = (name: 'dua', path: '/dua');

  /// One dua category by id, under the Dua tab (`/dua/category/:id`).
  static const duaCategory = (name: 'duaCategory', path: 'category/:id');

  /// Full-screen tasbih counter, under the Dua tab.
  static const tasbih = (name: 'tasbih', path: 'tasbih');
  static const more = (name: 'more', path: '/more');

  /// Settings stack: under the More branch's path (deep links switch to
  /// that tab), shown full-screen on the root navigator like every other
  /// secondary page.
  static const settings = (name: 'settings', path: 'settings');

  /// Sources & licenses page, under Settings.
  static const credits = (name: 'credits', path: 'credits');
  static const notifications = (name: 'notifications', path: '/notifications');
  static const notificationSettings = (
    name: 'notificationSettings',
    path: '/notifications/settings',
  );

  /// Jamaat focus + nafs lock (linked from notification settings).
  static const notificationFocus = (
    name: 'notificationFocus',
    path: '/notifications/focus',
  );

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

  /// One curated hadith topic by id (`/hadith/topic/:topic`).
  static const hadithTopic = (name: 'hadithTopic', path: 'topic/:topic');

  /// Full collections: the book list, full-text search, one book's
  /// chapters and one chapter (`/hadith/books/:book/:section`; optional
  /// `?lang=` for the chapter list it is from and `?n=` to show one hadith).
  static const hadithBooks = (name: 'hadithBooks', path: 'books');
  static const hadithSearch = (name: 'hadithSearch', path: 'search');
  static const hadithBook = (name: 'hadithBook', path: ':book');
  static const hadithSection = (name: 'hadithSection', path: ':section');

  /// Ruqyah — Qur'anic & prophetic protection/healing (More tab).
  static const ruqyah = (name: 'ruqyah', path: '/ruqyah');

  /// One ruqyah category by id (`/ruqyah/category/:id`).
  static const ruqyahCategory = (name: 'ruqyahCategory', path: 'category/:id');

  /// The 99 names — reachable from More and the Dua tab.
  static const asmaulHusna = (name: 'asmaulHusna', path: '/asmaul-husna');

  /// Names of the Prophet ﷺ (More tab) and their quiz.
  static const rasulNames = (name: 'rasulNames', path: '/rasul-names');
  static const rasulQuiz = (name: 'rasulQuiz', path: '/rasul-quiz');

  /// Asmaul Husna memorization quiz (entered from the names screen).
  static const asmaQuiz = (name: 'asmaQuiz', path: '/asma-quiz');

  /// Sunnah / nafl fasting tracker — recommended days + personal log.
  static const fasting = (name: 'fasting', path: '/fasting');

  /// Islamic expense tracker — monthly hisab, no israf (More tab).
  static const expenses = (name: 'expenses', path: '/expenses');

  /// Sunnah health tracker — habits, weight, guidance (More tab).
  static const health = (name: 'health', path: '/health');

  /// Quran and hadith stories (More tab); `?kind=quran|hadith` opens a tab.
  static const stories = (name: 'stories', path: '/stories');

  /// One story (`/stories/:kind/:id`) — prophet pages deep-link here.
  static const story = (name: 'story', path: ':kind/:id');

  /// Tibb an-Nabawi — prophetic medicine (More tab + Ruqyah screen).
  static const tibbNabawi = (name: 'tibbNabawi', path: '/tibb-nabawi');

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
