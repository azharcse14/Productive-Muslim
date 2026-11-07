import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:productive_muslim/core/di/locator.dart';
import 'package:productive_muslim/core/router/app_router.dart';
import 'package:productive_muslim/core/settings/settings_store.dart';
import 'package:productive_muslim/features/onboarding/presentation/state/app_lock_store.dart';
import 'package:productive_muslim/features/settings/domain/entities/app_settings.dart';
import 'package:productive_muslim/main.dart';

/// On-device interaction flows: real taps on the real app (real locator,
/// prefs and databases — it mutates the device's app data).
/// Run: flutter test integration_test/app_flows_test.dart -d DEVICE_ID
/// Screenshots: `--dart-define=E2E_SHOTS_DIR=/abs/host/dir` on the iOS
/// simulator, else the app's Documents/e2e_shots.
///
/// Each flow collects FlutterErrors (overflows, exceptions) instead of
/// stopping at the first, logs them as `E2E-ERROR`, then fails on them.
late IntegrationTestWidgetsFlutterBinding binding;
var _booted = false;

Future<void> _boot(WidgetTester t, {String locale = 'en'}) async {
  if (!_booted) {
    await setupLocator();
    _booted = true;
  }
  final store = locator<SettingsStore>();
  // Settings load async: decide nothing before they're in.
  for (var i = 0; i < 100 && !store.loaded.value; i++) {
    await Future<void>.delayed(const Duration(milliseconds: 50));
  }
  if (store.settings.value.setupComplete) {
    await store.setLocale(locale);
  }
  // A lock left on by an aborted run would gate every flow.
  final lock = locator<AppLockStore>();
  if (lock.enabled.value) {
    await lock.disable();
  }
  await t.pumpWidget(const ProductiveMuslimApp());
  await _settle(t, 20);
  if (store.settings.value.setupComplete) {
    appRouter.go('/home');
    await _settle(t);
  }
}

/// The countdown ticks forever, so pumpAndSettle never returns.
Future<void> _settle(WidgetTester t, [int frames = 8]) async {
  for (var i = 0; i < frames; i++) {
    await t.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _wait(WidgetTester t, Duration d) async {
  final end = DateTime.now().add(d);
  while (DateTime.now().isBefore(end)) {
    await t.pump(const Duration(milliseconds: 200));
  }
}

/// Waits (live) until [f] finds something, up to [timeout].
Future<void> _until(
  WidgetTester t,
  Finder f, {
  Duration timeout = const Duration(seconds: 10),
}) async {
  final end = DateTime.now().add(timeout);
  while (f.evaluate().isEmpty) {
    if (DateTime.now().isAfter(end)) {
      _dump('until timed out: $f');
      fail('Timed out waiting for $f');
    }
    await t.pump(const Duration(milliseconds: 200));
  }
}

String _textOf(Text w) => w.data ?? w.textSpan?.toPlainText() ?? '';

List<String> _texts() => [
  for (final e in find.byType(Text).evaluate())
    if (_textOf(e.widget as Text) case final s when s.trim().isNotEmpty)
      s.replaceAll('\n', ' '),
];

void _dump(String why) {
  final tips = find
      .byType(Tooltip)
      .evaluate()
      .map((e) => (e.widget as Tooltip).message)
      .join(' | ');
  debugPrint('E2E-DUMP ($why) TEXTS: ${_texts().join(' | ')}');
  debugPrint('E2E-DUMP ($why) TIPS: $tips');
}

Future<void> _tap(WidgetTester t, Finder f, {int frames = 8}) async {
  if (f.evaluate().isEmpty) {
    _dump('missing $f');
  }
  await t.ensureVisible(f.first);
  await t.pump();
  await t.tap(f.first, warnIfMissed: false);
  await _settle(t, frames);
}

Future<void> _tapText(WidgetTester t, String text) =>
    _tap(t, find.text(text));

Future<void> _tapTip(WidgetTester t, String tip) =>
    _tap(t, find.byTooltip(tip));

/// Scrolls the first scrollable down, then up, until [f] is built.
Future<void> _scrollTo(WidgetTester t, Finder f, {Finder? scrollable}) async {
  final s = scrollable ?? find.byType(Scrollable).first;
  for (final delta in [300.0, -300.0]) {
    if (f.evaluate().isNotEmpty) {
      break;
    }
    try {
      await t.scrollUntilVisible(f, delta, scrollable: s, maxScrolls: 40);
    } on StateError {
      // Ran out of list this way; try the other.
    }
  }
  await _settle(t, 4);
}

Future<void> _back(WidgetTester t) async {
  final back = find.byTooltip('Back');
  if (back.evaluate().isNotEmpty) {
    await _tap(t, back);
  } else {
    await t.pageBack();
    await _settle(t);
  }
}

/// Writes the current frame as a PNG into Documents/e2e_shots.
Future<void> _shot(WidgetTester t, String name) async {
  try {
    final view = t.binding.renderViews.first;
    final layer = view.debugLayer! as OffsetLayer;
    final size = view.flutterView.physicalSize;
    final image = await layer.toImage(Offset.zero & size);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    // On the iOS simulator the app can write straight to a host folder:
    // --dart-define=E2E_SHOTS_DIR=/abs/path (flutter test uninstalls the
    // app afterwards, taking Documents with it).
    const hostDir = String.fromEnvironment('E2E_SHOTS_DIR');
    final dir = Directory(
      hostDir.isNotEmpty
          ? hostDir
          : '${(await getApplicationDocumentsDirectory()).path}/e2e_shots',
    );
    await dir.create(recursive: true);
    await File('${dir.path}/$name.png').writeAsBytes(bytes!.buffer.asUint8List());
  } on Object catch (e) {
    debugPrint('E2E-SHOT failed for $name: $e');
  }
}

/// Runs [body] collecting every FlutterError, then fails on any.
Future<void> _flow(
  WidgetTester t,
  String name,
  Future<void> Function() body,
) async {
  final previous = FlutterError.onError;
  final errors = <String>[];
  FlutterError.onError = (details) {
    final summary = details.exceptionAsString().split('\n').take(6).join(' / ');
    final where = details.context?.toDescription() ?? '';
    final stack = (details.stack?.toString() ?? '')
        .split('\n')
        .where((l) => l.contains('package:productive_muslim'))
        .take(3)
        .join(' <- ');
    errors.add('$summary [$where] $stack');
    debugPrint('E2E-ERROR [$name] $summary | $where | $stack');
  };
  try {
    await body();
  } on Object {
    _dump('$name failed');
    await _shot(t, '${name}_FAILED');
    rethrow;
  } finally {
    FlutterError.onError = previous;
  }
  expect(errors, isEmpty, reason: 'FlutterErrors during $name');
}

void main() {
  binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('01 onboarding (fresh install only)', (t) async {
    await _boot(t);
    final store = locator<SettingsStore>();
    if (store.settings.value.setupComplete) {
      debugPrint('E2E-SKIP onboarding: setup already complete');
      return;
    }
    await _flow(t, 'onboarding', () async {
      await _until(t, find.text('Next'), timeout: const Duration(seconds: 20));
      await _shot(t, 'onboarding_welcome');
      await _tapText(t, 'Next');
      await _until(t, find.text('Where are you?'));
      await _tapText(t, 'Choose city manually');
      await _until(t, find.byType(TextField));
      await t.enterText(find.byType(TextField).first, 'Dhaka');
      await _wait(t, const Duration(seconds: 2));
      await _tap(t, find.text('Dhaka').last);
      await _until(t, find.text('Next'));
      await _shot(t, 'onboarding_location_set');
      await _tapText(t, 'Next'); // location → madhab
      await _tapText(t, 'Next'); // madhab → method
      await _tapText(t, 'Next'); // method → notifications
      await _tapText(t, 'Maybe later');
      await _until(t, find.text('Begin'));
      await _tapText(t, 'Begin');
      await _wait(t, const Duration(seconds: 2));
      expect(store.settings.value.setupComplete, isTrue);
      await _until(t, find.textContaining(RegExp('ENDS IN|STARTS IN|IN\$')));
      await _shot(t, 'onboarding_done_home');
    });
  });

  testWidgets('02 bottom nav, back, tab state', (t) async {
    await _boot(t);
    await _flow(t, 'nav', () async {
      for (final tab in ['Quran', 'Muhasaba', 'Dua', 'More', 'Home']) {
        await _tap(t, find.text(tab).last);
        await _shot(t, 'nav_$tab');
      }
      // Quran tab: switch to Juz, leave, come back — still Juz.
      await _tap(t, find.text('Quran').last);
      await _tapText(t, 'Juz');
      await _tap(t, find.text('Home').last);
      await _tap(t, find.text('Quran').last);
      final juzList = find.byKey(const PageStorageKey('quranJuzList'));
      expect(juzList, findsOneWidget, reason: 'Quran tab kept the Juz tab');
      await _tapText(t, 'Surahs');
      // Secondary page + back returns to its tab.
      await _tap(t, find.text('More').last);
      await _tapText(t, 'Calendar');
      await _back(t);
      expect(find.text('Calendar'), findsOneWidget);
    });
  });

  testWidgets('03 muhasaba', (t) async {
    await _boot(t);
    final semantics = t.ensureSemantics();
    await _flow(t, 'muhasaba', () async {
      await _tap(t, find.text('Muhasaba').last);
      await _shot(t, 'muhasaba_today');
      // Yes/no toggle.
      final sadaqah = find.text('Sadaqah');
      await _tap(t, sadaqah);
      await _shot(t, 'muhasaba_sadaqah_toggled');
      await _tap(t, sadaqah); // back off
      // Count +/-.
      const counter = 'Drinking water';
      await _scrollTo(t, find.text(counter));
      await _tap(t, _inRow(counter, Icons.add));
      await _tap(t, _inRow(counter, Icons.add));
      expect(find.text('2 / 8 times'), findsOneWidget);
      await _tap(t, _inRow(counter, Icons.remove));
      expect(find.text('1 / 8 times'), findsOneWidget);
      await _tap(t, _inRow(counter, Icons.remove));
      // Date back / forward.
      await _scrollTo(t, find.byTooltip('Previous day'));
      await _tapTip(t, 'Previous day');
      await _shot(t, 'muhasaba_yesterday');
      await _tapTip(t, 'Next day');
      // Dashboard.
      await _tapText(t, 'Dashboard');
      await _wait(t, const Duration(seconds: 1));
      await _shot(t, 'muhasaba_dashboard');
      await _tapText(t, 'Today');
      // Add a custom count item.
      await _tapTip(t, 'Add item');
      await t.enterText(find.byType(TextField).first, 'E2E Item');
      await _settle(t);
      await _tapText(t, 'Count');
      await _tap(t, find.text('Save').last);
      await _wait(t, const Duration(seconds: 1));
      await _scrollTo(t, find.text('E2E Item'));
      await _shot(t, 'muhasaba_item_added');
      // Reorder sheet opens and lists it.
      await _tapTip(t, 'Reorder items');
      expect(find.text('E2E Item'), findsWidgets);
      await _shot(t, 'muhasaba_reorder');
      final handles = find.byIcon(Icons.drag_handle);
      if (handles.evaluate().length >= 2) {
        await t.drag(handles.last, const Offset(0, -120));
        await _settle(t);
      }
      await t.tapAt(const Offset(20, 80)); // dismiss the sheet
      await _settle(t);
      // Archive it: count rows have no pencil; long press opens the editor.
      await _scrollTo(t, find.text('E2E Item'));
      await t.longPress(find.text('E2E Item'));
      await _settle(t);
      await _tap(t, find.text('Archive').last);
      await _wait(t, const Duration(seconds: 1));
      await _shot(t, 'muhasaba_archived');
      // Archived items move to their own section, history kept.
      expect(find.text('ARCHIVED'), findsOneWidget);
      expect(
        t.getTopLeft(find.text('E2E Item')).dy,
        greaterThan(t.getTopLeft(find.text('ARCHIVED')).dy),
      );
    }).whenComplete(semantics.dispose);
  });

  testWidgets('04 tasbih', (t) async {
    await _boot(t);
    await _flow(t, 'tasbih', () async {
      appRouter.go('/dua/tasbih');
      await _settle(t);
      await _tapText(t, 'SubhanAllah');
      // Reset first if a count is left over.
      if (find.text('0').evaluate().isEmpty) {
        await _tapText(t, 'Reset');
        if (find.text('Discard').evaluate().isNotEmpty) {
          await _tapText(t, 'Discard');
        }
      }
      final bead = find.text('سُبْحَانَ ٱللَّٰهِ');
      for (var i = 0; i < 3; i++) {
        await _tap(t, bead, frames: 2);
      }
      expect(find.text('3'), findsOneWidget);
      await _shot(t, 'tasbih_3');
      // Leave and come back: persists.
      await _back(t);
      appRouter.go('/dua/tasbih');
      await _settle(t);
      expect(find.text('3'), findsOneWidget, reason: 'tasbih count persisted');
      // Custom target.
      await _tapText(t, 'Custom');
      await t.enterText(find.byType(TextField).last, '7');
      await _tap(t, find.text('Save').last);
      expect(find.text('7'), findsWidgets);
      await _shot(t, 'tasbih_target7');
      // Reset → discard.
      await _tapText(t, 'Reset');
      await _shot(t, 'tasbih_reset_dialog');
      await _tapText(t, 'Discard');
      expect(find.text('0'), findsWidgets);
      await _tapText(t, '33');
    });
  });

  testWidgets('05 dua favorite + search', (t) async {
    await _boot(t);
    await _flow(t, 'dua', () async {
      await _tap(t, find.text('Dua').last);
      await _tapText(t, 'Sleep');
      await _until(t, find.byTooltip('Add to favorites'));
      await _tap(t, find.byTooltip('Add to favorites').first);
      await _shot(t, 'dua_fav_added');
      await _back(t);
      final removes = find.byTooltip('Remove from favorites').evaluate().length;
      expect(removes, greaterThanOrEqualTo(1));
      await _tapText(t, 'Sleep');
      await _tap(t, find.byTooltip('Remove from favorites').first);
      await _back(t);
      expect(
        find.byTooltip('Remove from favorites').evaluate().length,
        removes - 1,
      );
      await _tapTip(t, 'Search');
      await t.enterText(find.byType(TextField).last, 'sleep');
      await _wait(t, const Duration(seconds: 1));
      await _shot(t, 'dua_search');
      expect(find.text('No duas found'), findsNothing);
      await t.enterText(find.byType(TextField).last, 'zzzxqv');
      await _wait(t, const Duration(seconds: 1));
      await _shot(t, 'dua_search_empty');
      await _back(t);
    });
  });

  testWidgets('06 quran', (t) async {
    await _boot(t);
    await _flow(t, 'quran', () async {
      await _tap(t, find.text('Quran').last);
      await _tapText(t, 'Al-Baqara');
      await _until(t, find.byTooltip('Bookmark'));
      await t.fling(find.byType(Scrollable).first, const Offset(0, -2500), 3000);
      await _wait(t, const Duration(seconds: 2));
      await _shot(t, 'quran_baqara_scrolled');
      await _tap(t, find.byTooltip('Bookmark').first);
      await _shot(t, 'quran_bookmarked');
      expect(find.byIcon(Icons.bookmark), findsWidgets);
      await _back(t);
      await _wait(t, const Duration(seconds: 1));
      await _shot(t, 'quran_list_after');
      expect(
        find.textContaining('Al-Baqara ·'),
        findsOneWidget,
        reason: 'continue-reading card shows Al-Baqara',
      );
      await _tapTip(t, 'Bookmarks');
      await _shot(t, 'quran_bookmarks');
      expect(find.textContaining('2:'), findsWidgets);
      await _tap(t, find.text('Home').last);
      expect(find.text('Al-Baqara'), findsWidgets);
    });
  });

  testWidgets('07 hadith', (t) async {
    await _boot(t);
    await _flow(t, 'hadith', () async {
      appRouter.go('/hadith');
      await _settle(t);
      await _tapText(t, 'Faith');
      await _wait(t, const Duration(seconds: 1));
      await _shot(t, 'hadith_topic');
      _dump('hadith topic');
      await _back(t);
      appRouter.go('/hadith/books');
      await _wait(t, const Duration(seconds: 2));
      await _shot(t, 'hadith_books');
      _dump('hadith books');
      await _tapText(t, 'Sahih al-Bukhari');
      await _wait(t, const Duration(seconds: 2));
      await _shot(t, 'hadith_book');
      _dump('hadith book');
      appRouter.go('/hadith');
      await _settle(t);
      await _tapTip(t, 'Search topics');
      await t.enterText(find.byType(TextField).last, 'charity');
      await _wait(t, const Duration(seconds: 1));
      await _shot(t, 'hadith_search');
      _dump('hadith search');
    });
  });

  testWidgets('08 settings: language, theme, method', (t) async {
    await _boot(t);
    final store = locator<SettingsStore>();
    await _flow(t, 'settings', () async {
      appRouter.go('/more/settings');
      await _settle(t);
      await _scrollTo(t, find.text('Language'));
      await _tapText(t, 'Language');
      await _tapText(t, 'বাংলা');
      await _wait(t, const Duration(seconds: 1));
      expect(store.locale.value.languageCode, 'bn');
      await _shot(t, 'settings_bn');
      _checkNoLatinLeaks('settings bn');
      appRouter.go('/home');
      await _settle(t, 15);
      await _shot(t, 'home_bn');
      _checkNoLatinLeaks('home bn');
      appRouter.go('/more');
      await _settle(t);
      _checkNoLatinLeaks('more bn');
      await store.setLocale('en');
      await _settle(t);
      // Theme → dark.
      appRouter.go('/more/settings');
      await _settle(t);
      await _scrollTo(t, find.text('Theme'));
      await _tapText(t, 'Theme');
      await _tapText(t, 'Dark');
      expect(store.themeMode.value, ThemeMode.dark);
      await _shot(t, 'settings_dark');
      // Calculation method → Muslim World League changes Fajr.
      appRouter.go('/home');
      await _settle(t, 15);
      final before = '${_rowRange('Fajr')} / ${_rowRange('Isha')}';
      appRouter.go('/more/settings');
      await _settle(t);
      final methodBefore = store.settings.value.prayerParams.method;
      await _tapText(t, 'Calculation method');
      await _shot(t, 'settings_method_sheet');
      await _tap(t, find.text('Muslim World League').last);
      appRouter.go('/home');
      await _settle(t, 15);
      final after = '${_rowRange('Fajr')} / ${_rowRange('Isha')}';
      debugPrint(
        'E2E-INFO method $methodBefore -> '
        '${store.settings.value.prayerParams.method}: '
        'fajr/isha before=$before after=$after',
      );
      expect(after, isNot(before), reason: 'method change moves Fajr');
      // Restore.
      await store.setMethod(methodBefore);
      await store.setThemeMode(AppThemeMode.system);
      await _settle(t);
    });
  });

  testWidgets('09 location picker: London and back', (t) async {
    await _boot(t);
    final store = locator<SettingsStore>();
    final original = store.location.value;
    await _flow(t, 'location', () async {
      appRouter.go('/more/settings');
      await _settle(t);
      await _tapText(t, 'Location');
      await _until(t, find.byType(TextField));
      await t.enterText(find.byType(TextField).first, 'London');
      await _wait(t, const Duration(seconds: 2));
      await _shot(t, 'location_search_london');
      // The GB London, not London, Ontario.
      final gb = find.ancestor(
        of: find.textContaining('GB'),
        matching: find.byType(InkWell),
      );
      final london = find.ancestor(
        of: find.text('London'),
        matching: find.byType(InkWell),
      );
      final pick = london.evaluate().firstWhere(
        (e) => gb.evaluate().contains(e),
      );
      await t.tap(find.byElementPredicate((e) => e == pick));
      await _settle(t);
      await _wait(t, const Duration(seconds: 1));
      appRouter.go('/home');
      await _settle(t, 15);
      await _shot(t, 'home_london');
      _dump('home london');
      expect(find.text('London, GB'), findsOneWidget);
    });
    if (original != null) {
      await store.setLocation(original);
      await _settle(t);
    }
  });

  testWidgets('10 my mosque jamaat → home countdown', (t) async {
    await _boot(t);
    final semantics = t.ensureSemantics();
    await _flow(t, 'mosque', () async {
      appRouter.go('/mosque');
      await _settle(t);
      await _tapText(t, 'Add profile');
      await t.enterText(find.byType(TextField).last, 'E2E Masjid');
      await _tap(t, find.text('Save').last);
      await _wait(t, const Duration(seconds: 1));
      await _shot(t, 'mosque_profile');
      _dump('mosque');
      // Offset 60 min on every prayer (max), so the current waqt likely
      // has a future jamaat.
      for (final p in ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha']) {
        final seg = find.bySemanticsLabel(RegExp('^$p.*Offset'));
        if (seg.evaluate().isEmpty) {
          debugPrint('E2E-INFO no Offset segment semantics for $p');
          continue;
        }
        await _tap(t, seg);
      }
      await _shot(t, 'mosque_offsets');
      appRouter.go('/home');
      await _settle(t, 15);
      // Current waqt from the countdown label ("DHUHR ENDS IN").
      if (find.text('JAMAAT IN').evaluate().isNotEmpty) {
        await _shot(t, 'home_with_jamaat');
        debugPrint('E2E-INFO countdown already targets a jamaat (offsets)');
        return;
      }
      final label = _texts().firstWhere(
        (s) => s.endsWith(' ENDS IN'),
        orElse: () => '',
      );
      if (label.isEmpty) {
        debugPrint('E2E-INFO no "ENDS IN" countdown now; jamaat skipped');
        return;
      }
      final word = label.split(' ').first;
      final prayer = word[0] + word.substring(1).toLowerCase();
      final at = DateTime.now().add(const Duration(minutes: 3));
      appRouter.go('/mosque');
      await _settle(t);
      await _scrollTo(t, find.bySemanticsLabel('$prayer: Fixed'));
      await _tap(t, find.bySemanticsLabel('$prayer: Fixed'));
      await _tap(t, find.byIcon(Icons.keyboard_outlined));
      final fields = find.descendant(
        of: find.byType(Dialog),
        matching: find.byType(TextField),
      );
      final h12 = at.hour % 12 == 0 ? 12 : at.hour % 12;
      await t.enterText(fields.at(0), '$h12');
      await t.enterText(fields.at(1), at.minute.toString().padLeft(2, '0'));
      await _tapText(t, at.hour < 12 ? 'AM' : 'PM');
      await _shot(t, 'mosque_time_picker');
      await _tapText(t, 'OK');
      await _wait(t, const Duration(seconds: 1));
      await _shot(t, 'mosque_fixed');
      _dump('mosque fixed');
      appRouter.go('/home');
      await _settle(t, 15);
      await _shot(t, 'home_with_jamaat');
      _dump('home jamaat');
      expect(
        find.text('JAMAAT IN'),
        findsOneWidget,
        reason: '$prayer jamaat at $at is the countdown target',
      );
    }).whenComplete(semantics.dispose);
  });

  testWidgets('11 calculators', (t) async {
    await _boot(t);
    await _flow(t, 'calculators', () async {
      // Zakat: cash 1,000,000 above the silver nisab → 25,000.
      appRouter.go('/zakat');
      await _settle(t);
      Future<void> field(String label, String v) async {
        final f = find.widgetWithText(TextField, label);
        await _scrollTo(t, f);
        await t.enterText(f, v);
        await _settle(t, 3);
      }

      await field('Gold price per gram', '10000');
      await field('Silver price per gram', '100');
      await field('Cash on hand', '1000000');
      await _scrollTo(t, find.text('Calculate'));
      await _tapText(t, 'Calculate');
      await _scrollTo(t, find.textContaining('25,000'));
      await _shot(t, 'zakat_result');
      _dump('zakat');
      expect(find.textContaining('25,000'), findsWidgets);

      // Faraid: husband + mother + full sister, estate 800,000 → awl to 8.
      appRouter.go('/calculators/faraid');
      await _settle(t);
      await t.enterText(find.byType(TextField).first, '800000');
      await t.testTextInput.receiveAction(TextInputAction.done);
      await _settle(t);
      await _tapText(t, 'Husband');
      await _shot(t, 'faraid_husband_tapped');
      await _tapText(t, 'Mother');
      final sisters = find.bySemanticsLabel('Increase Full sisters');
      if (sisters.evaluate().isNotEmpty) {
        await _tap(t, sisters);
      } else {
        await _scrollTo(t, find.text('Full sisters'));
        final row = find.ancestor(
          of: find.text('Full sisters'),
          matching: find.byType(Row),
        );
        await _tap(
          t,
          find.descendant(of: row.first, matching: find.byIcon(Icons.add)),
        );
      }
      await _scrollTo(t, find.text('Calculate'));
      await _shot(t, 'faraid_form');
      await _tapText(t, 'Calculate');
      await _wait(t, const Duration(seconds: 1));
      await _shot(t, 'faraid_result');
      _dump('faraid');
      expect(find.textContaining('300,000'), findsWidgets);
      expect(find.textContaining('200,000'), findsWidgets);

      // Fitra: wheat 50/kg × 4 people.
      appRouter.go('/calculators/fitra');
      await _settle(t);
      await t.enterText(find.widgetWithText(TextField, 'Price per kg'), '50');
      await t.enterText(
        find.widgetWithText(TextField, 'Number of people'),
        '4',
      );
      await _scrollTo(t, find.text('Calculate'));
      await _tapText(t, 'Calculate');
      await _shot(t, 'fitra_result');
      _dump('fitra');

      // Age: DOB 15 Jan 1990 via the date picker's input mode.
      appRouter.go('/calculators/age');
      await _settle(t);
      await _tap(t, find.text('Select date').first);
      await _pickDate(t, '01/15/1990');
      await _tapText(t, 'Calculate');
      await _shot(t, 'age_result');
      _dump('age');
      expect(find.textContaining('36'), findsWidgets);

      // Qaza: 1 Jan 2020 → today.
      appRouter.go('/calculators/qaza');
      await _settle(t);
      await _tap(t, find.text('Select date').first);
      await _pickDate(t, '01/01/2020');
      await _scrollTo(t, find.text('Calculate'));
      await _tapText(t, 'Calculate');
      await _shot(t, 'qaza_result');
      _dump('qaza');
    });
  });

  testWidgets('12 expenses, health, fasting', (t) async {
    await _boot(t);
    await _flow(t, 'trackers', () async {
      appRouter.go('/expenses');
      await _settle(t);
      await _tapTip(t, 'Add expense');
      await _shot(t, 'expense_sheet');
      _dump('expense sheet');
      await t.enterText(find.byType(TextField).first, '250');
      await _tap(t, find.text('Save').last);
      await _wait(t, const Duration(seconds: 1));
      await _shot(t, 'expense_added');
      expect(find.textContaining('250.00'), findsWidgets);
      await _tapTip(t, 'Monthly budget');
      await _shot(t, 'expense_budget');
      _dump('budget dialog');
      await t.enterText(find.byType(TextField).last, '60000');
      await _tap(t, find.text('Save').last);
      await _settle(t);
      expect(find.textContaining('60,000'), findsWidgets);
      // Delete: swipe the row.
      final row = find.textContaining('250.00').last;
      await t.drag(row, const Offset(-500, 0));
      await _wait(t, const Duration(seconds: 1));
      await _shot(t, 'expense_after_swipe');
      _dump('after swipe');

      appRouter.go('/health');
      await _settle(t);
      await _tapText(t, "Log today's weight");
      await t.enterText(find.byType(TextField).last, '70.5');
      await _tap(t, find.text('Save').last);
      await _settle(t);
      await _shot(t, 'health_weight');
      expect(find.textContaining('70.5'), findsWidgets);

      appRouter.go('/fasting');
      await _settle(t);
      final today = '${DateTime.now().day}';
      await _tap(t, find.text(today).last);
      await _tapText(t, 'Voluntary (nafl)');
      await _settle(t);
      expect(find.text('1'), findsWidgets);
      await _shot(t, 'fasting_marked');
      _dump('fasting');
    });
  });

  testWidgets('13 app lock', (t) async {
    await _boot(t);
    final lock = locator<AppLockStore>();
    Future<void> pin(String digits) async {
      for (final d in digits.split('')) {
        await _tap(t, find.text(d).last, frames: 2);
      }
      await _settle(t);
    }

    await _flow(t, 'lock', () async {
      appRouter.go('/more/settings');
      await _settle(t);
      await _scrollTo(t, find.text('App lock'));
      await _tapText(t, 'App lock');
      await _settle(t, 10);
      if (find.text('I understand').evaluate().isNotEmpty) {
        await _tapText(t, 'I understand');
      }
      await _until(t, find.text('Set a 4-digit PIN'));
      await pin('1234');
      await _until(t, find.text('Confirm your PIN'));
      await pin('1234');
      await _settle(t, 10);
      // A biometric offer may appear.
      for (final label in ['Not now', 'Skip', 'No thanks']) {
        if (find.text(label).evaluate().isNotEmpty) {
          await _tapText(t, label);
        }
      }
      expect(lock.enabled.value, isTrue);
      // Background past the 30s grace period, then resume.
      for (final s in [
        AppLifecycleState.inactive,
        AppLifecycleState.hidden,
        AppLifecycleState.paused,
      ]) {
        t.binding.handleAppLifecycleStateChanged(s);
      }
      // No pumping while paused: the engine sends no frames, pump hangs.
      await Future<void>.delayed(const Duration(seconds: 32));
      for (final s in [
        AppLifecycleState.hidden,
        AppLifecycleState.inactive,
        AppLifecycleState.resumed,
      ]) {
        t.binding.handleAppLifecycleStateChanged(s);
      }
      await _wait(t, const Duration(seconds: 2));
      await _shot(t, 'lock_gate');
      expect(find.text('Enter your PIN'), findsOneWidget);
      // Five wrong PINs → cooldown.
      for (var i = 0; i < 5; i++) {
        await pin('0000');
      }
      await _shot(t, 'lock_throttled');
      _dump('throttled');
      expect(find.textContaining('Too many attempts'), findsOneWidget);
      await _wait(t, const Duration(seconds: 31));
      await pin('1234');
      await _wait(t, const Duration(seconds: 1));
      expect(lock.locked.value, isFalse);
      await _shot(t, 'lock_unlocked');
      // Remove the lock (needs the PIN).
      appRouter.go('/more/settings');
      await _settle(t);
      await _scrollTo(t, find.text('App lock'));
      await _tapText(t, 'App lock');
      await _until(t, find.text('Enter your PIN'));
      await pin('1234');
      await _wait(t, const Duration(seconds: 1));
      expect(lock.enabled.value, isFalse);
    });
    if (lock.enabled.value) {
      await lock.disable();
    }
  });

  testWidgets('14 qibla no-sensor state', (t) async {
    await _boot(t);
    await _flow(t, 'qibla', () async {
      appRouter.go('/qibla');
      await _wait(t, const Duration(seconds: 8));
      await _shot(t, 'qibla');
      _dump('qibla after 8s');
    });
  });

  testWidgets('15 big text + dark sweep', (t) async {
    await _boot(t);
    final store = locator<SettingsStore>();
    await store.setThemeMode(AppThemeMode.dark);
    binding.platformDispatcher.textScaleFactorTestValue = 2.0;
    try {
      await _flow(t, 'sweep', () async {
        for (final locale in ['en', 'bn']) {
          await store.setLocale(locale);
          for (final p in _sweepPaths) {
            debugPrint('E2E-SWEEP $locale $p');
            appRouter.go(p);
            await _settle(t, 10);
            await _shot(t, 'x2_dark_${locale}_${p.replaceAll('/', '_')}');
          }
        }
        appRouter.go('/home');
        await _settle(t);
      });
    } finally {
      binding.platformDispatcher.clearAllTestValues();
      await store.setThemeMode(AppThemeMode.system);
      await store.setLocale('en');
    }
  });
}

const _sweepPaths = [
  '/home', '/quran', '/quran/2', '/muhasaba', '/dua', '/dua/tasbih', '/more',
  '/more/settings', '/location', '/mosque', '/qibla', '/hadith', '/fasting',
  '/expenses', '/health', '/zakat', '/calculators', '/calculators/fitra',
  '/calculators/qaza', '/calculators/faraid', '/calculators/age', '/ramadan',
  '/calendar', '/special-times', '/achievements', '/ruqyah', '/prophets',
  '/stories', '/asmaul-husna', '/notifications',
];

/// The [icon] in the nearest ancestor of the [label] text that has one.
Finder _inRow(String label, IconData icon) {
  for (final a in find
      .ancestor(
        of: find.text(label),
        matching: find.byWidgetPredicate((w) => w is Flex),
      )
      .evaluate()) {
    final hit = find.descendant(
      of: find.byElementPredicate((e) => e == a),
      matching: find.byIcon(icon),
    );
    if (hit.evaluate().isNotEmpty) {
      return hit;
    }
  }
  return find.byIcon(icon).first;
}

String _rowRange(String prayer) {
  final texts = _texts();
  final i = texts.indexOf(prayer);
  return i >= 0 && i + 1 < texts.length ? texts[i + 1] : '<no $prayer>';
}

/// Flags ASCII words on a Bangla screen (likely missing translations).
/// Logged, not failed: names, numbers in Latin and brand words are fine.
void _checkNoLatinLeaks(String where) {
  final latin = RegExp('[A-Za-z]{3,}');
  final leaks = _texts().where(latin.hasMatch).toList();
  debugPrint('E2E-LATIN ($where): ${leaks.join(' | ')}');
}

Future<void> _pickDate(WidgetTester t, String mmddyyyy) async {
  final toInput = find.byIcon(Icons.edit_outlined);
  if (toInput.evaluate().isNotEmpty) {
    await _tap(t, toInput.last);
  }
  await t.enterText(find.byType(TextField).last, mmddyyyy);
  await _settle(t);
  await _tapText(t, 'OK');
}
