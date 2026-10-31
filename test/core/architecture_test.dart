import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guide §2/§4 and docs/REVIEW_FIX_PLAN.md Phase 5.1: layer and feature
/// import rules. Every current offender is listed in [_baseline]; the list
/// may only shrink. A violation is written as `'from -> to'`, where `to` is
/// the imported file (`lib/...`), the package (`package:x`), or `GetIt` /
/// `locator` for rule 6.
void main() {
  test('no domain file imports Flutter', () {
    final offenders = [
      for (final f in Directory('lib').listSync(recursive: true))
        if (f is File &&
            f.path.endsWith('.dart') &&
            f.path.contains('/domain/') &&
            f.readAsStringSync().contains("import 'package:flutter/"))
          f.path,
    ];
    expect(offenders, isEmpty);
  });

  final violations = _findViolations();

  test('no new layer or feature import violations', () {
    final added = violations.difference(_baseline).toList()..sort();
    expect(added, isEmpty, reason: 'Fix these imports; do not baseline them.');
  });

  test('baseline has no entries that are already fixed', () {
    final fixed = _baseline.difference(violations).toList()..sort();
    expect(fixed, isEmpty, reason: 'Delete these entries from _baseline.');
  });
}

/// Composition roots may wire anything to anything.
bool _isExempt(String path) =>
    path == 'lib/main.dart' ||
    path.startsWith('lib/core/di/') ||
    path.startsWith('lib/core/router/');

const _platformPackages = {
  'shared_preferences',
  'drift',
  'sqlite3',
  'geolocator',
  'sensors_plus',
  'flutter_local_notifications',
  'local_auth',
  'url_launcher',
  'path_provider',
};

/// The only non-domain project files a domain file may import. Each must stay
/// pure Dart (no Flutter, no packages); add one only if that holds.
const _pureCoreUtils = {
  'lib/core/utils/hijri_date.dart',
  'lib/core/utils/locale_digits.dart',
  'lib/core/utils/result.dart',
};

// `import` / `export` directives; `\s+` also spans multi-line statements.
final _directive = RegExp(
  r'''^\s*(?:import|export)\s+['"]([^'"]+)['"]''',
  multiLine: true,
);
final _serviceLocator = RegExp(r'\b(GetIt|locator)\b');

/// `lib/features/<name>/...` → `<name>`, else null.
String? _feature(String path) {
  final parts = path.split('/');
  return parts.length > 3 && parts[1] == 'features' ? parts[2] : null;
}

Set<String> _findViolations() {
  final out = <String>{};
  final files = Directory('lib')
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart') && !f.path.contains('/l10n/gen/'));
  for (final file in files) {
    final from = file.path.replaceAll(r'\', '/');
    if (_isExempt(from)) continue;
    final source = file.readAsStringSync();
    // Allowlisted utils are held to the domain rules so they stay pure.
    final inDomain =
        from.contains('/domain/') || _pureCoreUtils.contains(from);
    final inData = from.contains('/data/');
    final inPresentation = from.contains('/presentation/');

    for (final m in _directive.allMatches(source)) {
      final uri = m.group(1)!;
      if (uri.startsWith('dart:')) continue;
      const self = 'package:productive_muslim/';
      String? to; // resolved lib/ path; null for a third-party package
      if (uri.startsWith(self)) {
        to = 'lib/${uri.substring(self.length)}';
      } else if (!uri.startsWith('package:')) {
        to = Uri.parse(from).resolve(uri).path;
      }

      if (to == null) {
        final package = uri.substring('package:'.length).split('/').first;
        // Rule 1: domain imports no Flutter and no third-party package.
        // Rule 5: presentation never touches storage/platform plugins.
        if (inDomain ||
            (inPresentation && _platformPackages.contains(package))) {
          out.add('$from -> package:$package');
        }
        continue;
      }
      // Rule 1b: domain imports only domain and pure-Dart core utils.
      if (inDomain &&
          !to.contains('/domain/') &&
          !_pureCoreUtils.contains(to)) {
        out.add('$from -> $to');
      }
      // Rules 2 and 3: data and presentation never import each other.
      if (inData && to.contains('/presentation/')) out.add('$from -> $to');
      if (inPresentation && to.contains('/data/')) out.add('$from -> $to');
      // Rule 4: another feature only through its domain/.
      final target = _feature(to);
      if (target != null &&
          target != _feature(from) &&
          !to.startsWith('lib/features/$target/domain/')) {
        out.add('$from -> $to');
      }
    }

    // Rule 6: widgets get their dependencies passed in.
    if (from.contains('/presentation/widgets/')) {
      for (final m in _serviceLocator.allMatches(source)) {
        out.add('$from -> ${m.group(1)}');
      }
    }
  }
  return out;
}

/// Violations that existed when the rules were added (2026-10-29). Delete an
/// entry when you fix it; never add one.
const _baseline = <String>{
  'lib/features/achievements/presentation/state/achievement_store.dart -> lib/features/dua_tasbih/presentation/state/tasbih_store.dart',
  'lib/features/achievements/presentation/state/achievement_store.dart -> lib/features/fasting/presentation/state/fasting_store.dart',
  'lib/features/achievements/presentation/state/achievement_store.dart -> lib/features/quran/presentation/state/quran_store.dart',
  'lib/features/achievements/presentation/state/achievement_store.dart -> package:shared_preferences',
  'lib/features/achievements/presentation/widgets/achievements_summary_card.dart -> lib/features/muhasaba/presentation/state/muhasaba_store.dart',
  'lib/features/achievements/presentation/widgets/achievements_summary_card.dart -> locator',
  'lib/features/calculators/presentation/screens/age_screen.dart -> lib/features/settings/presentation/state/settings_store.dart',
  'lib/features/calculators/presentation/screens/fitra_screen.dart -> lib/features/settings/presentation/state/settings_store.dart',
  'lib/features/calculators/presentation/screens/qaza_screen.dart -> lib/features/settings/presentation/state/settings_store.dart',
  'lib/features/calendar/presentation/screens/calendar_screen.dart -> lib/features/prayer_times/presentation/state/home_store.dart',
  'lib/features/calendar/presentation/screens/calendar_screen.dart -> lib/features/settings/presentation/state/settings_store.dart',
  'lib/features/calendar/presentation/screens/calendar_screen.dart -> lib/features/settings/presentation/widgets/setting_labels.dart',
  'lib/features/daily_content/presentation/state/daily_content_store.dart -> lib/features/dua_tasbih/presentation/state/dua_store.dart',
  'lib/features/dua_tasbih/presentation/screens/dua_category_screen.dart -> lib/features/quran/presentation/widgets/reader_settings_sheet.dart',
  'lib/features/dua_tasbih/presentation/screens/dua_screen.dart -> lib/features/muhasaba/presentation/widgets/tracker_visuals.dart',
  'lib/features/dua_tasbih/presentation/screens/tasbih_screen.dart -> package:shared_preferences',
  'lib/features/dua_tasbih/presentation/state/asma_quiz_store.dart -> package:shared_preferences',
  'lib/features/dua_tasbih/presentation/state/dua_favorites_store.dart -> package:shared_preferences',
  'lib/features/dua_tasbih/presentation/state/tasbih_store.dart -> package:shared_preferences',
  'lib/features/dua_tasbih/presentation/widgets/dua_card.dart -> lib/features/quran/presentation/state/quran_store.dart',
  'lib/features/dua_tasbih/presentation/widgets/dua_card.dart -> locator',
  'lib/features/expenses/presentation/state/expense_store.dart -> package:shared_preferences',
  'lib/features/fasting/presentation/screens/fasting_screen.dart -> lib/features/prayer_times/presentation/state/home_store.dart',
  'lib/features/fasting/presentation/state/fasting_store.dart -> package:shared_preferences',
  'lib/features/hadith/presentation/screens/hadith_books_screen.dart -> lib/features/muhasaba/presentation/widgets/tracker_visuals.dart',
  'lib/features/hadith/presentation/screens/hadith_detail_screen.dart -> lib/features/quran/presentation/widgets/reader_settings_sheet.dart',
  'lib/features/hadith/presentation/screens/hadith_screen.dart -> lib/features/muhasaba/presentation/widgets/tracker_visuals.dart',
  'lib/features/hadith/presentation/screens/hadith_section_screen.dart -> lib/features/quran/presentation/state/quran_store.dart',
  'lib/features/hadith/presentation/screens/hadith_section_screen.dart -> lib/features/quran/presentation/widgets/reader_settings_sheet.dart',
  'lib/features/hadith/presentation/screens/hadith_topic_screen.dart -> lib/features/quran/presentation/widgets/reader_settings_sheet.dart',
  'lib/features/hadith/presentation/state/hadith_books_store.dart -> package:shared_preferences',
  'lib/features/hadith/presentation/widgets/hadith_list_card.dart -> lib/features/quran/presentation/state/quran_store.dart',
  'lib/features/health/presentation/screens/health_screen.dart -> lib/features/muhasaba/presentation/state/muhasaba_store.dart',
  'lib/features/health/presentation/screens/health_screen.dart -> lib/features/muhasaba/presentation/widgets/tracker_row.dart',
  'lib/features/health/presentation/screens/health_screen.dart -> lib/features/prayer_times/presentation/state/home_store.dart',
  'lib/features/health/presentation/state/health_store.dart -> package:shared_preferences',
  'lib/features/home_widget/data/prayer_widget_service.dart -> lib/features/my_mosque/presentation/state/mosque_store.dart',
  'lib/features/home_widget/data/prayer_widget_service.dart -> lib/features/prayer_times/presentation/screens/home_formatting.dart',
  'lib/features/home_widget/data/prayer_widget_service.dart -> lib/features/settings/presentation/state/settings_store.dart',
  'lib/features/home_widget/data/prayer_widget_service.dart -> lib/features/settings/presentation/widgets/setting_labels.dart',
  'lib/features/muhasaba/presentation/screens/muhasaba_screen.dart -> lib/features/achievements/presentation/state/achievement_store.dart',
  'lib/features/muhasaba/presentation/screens/muhasaba_screen.dart -> lib/features/achievements/presentation/widgets/achievements_summary_card.dart',
  'lib/features/muhasaba/presentation/screens/muhasaba_screen.dart -> lib/features/prayer_times/presentation/state/home_store.dart',
  'lib/features/muhasaba/presentation/screens/muhasaba_screen.dart -> lib/features/settings/presentation/state/settings_store.dart',
  'lib/features/muhasaba/presentation/state/muhasaba_store.dart -> package:shared_preferences',
  'lib/features/my_mosque/presentation/screens/my_mosque_screen.dart -> lib/features/prayer_times/presentation/state/home_store.dart',
  'lib/features/my_mosque/presentation/screens/my_mosque_screen.dart -> lib/features/settings/presentation/widgets/setting_labels.dart',
  'lib/features/my_mosque/presentation/widgets/prayer_jamaat_card.dart -> lib/features/settings/presentation/widgets/setting_labels.dart',
  'lib/features/notifications/presentation/screens/notification_settings_screen.dart -> lib/features/settings/presentation/state/settings_store.dart',
  'lib/features/notifications/presentation/screens/notification_settings_screen.dart -> lib/features/settings/presentation/widgets/setting_labels.dart',
  'lib/features/notifications/presentation/screens/notifications_screen.dart -> lib/features/prayer_times/presentation/screens/home_formatting.dart',
  'lib/features/notifications/presentation/screens/notifications_screen.dart -> lib/features/settings/presentation/state/settings_store.dart',
  'lib/features/notifications/presentation/screens/notifications_screen.dart -> lib/features/settings/presentation/widgets/setting_labels.dart',
  'lib/features/notifications/presentation/state/notification_controller.dart -> lib/features/my_mosque/presentation/state/mosque_store.dart',
  'lib/features/notifications/presentation/state/notification_controller.dart -> lib/features/settings/presentation/state/settings_store.dart',
  'lib/features/notifications/presentation/state/notification_controller.dart -> lib/features/settings/presentation/widgets/setting_labels.dart',
  'lib/features/onboarding/presentation/screens/onboarding_screen.dart -> lib/features/settings/presentation/state/settings_store.dart',
  'lib/features/onboarding/presentation/screens/onboarding_screen.dart -> lib/features/settings/presentation/widgets/setting_labels.dart',
  'lib/features/onboarding/presentation/screens/splash_screen.dart -> lib/features/settings/presentation/state/settings_store.dart',
  'lib/features/prayer_times/presentation/screens/home_formatting.dart -> lib/features/settings/presentation/widgets/setting_labels.dart',
  'lib/features/prayer_times/presentation/screens/home_screen.dart -> lib/features/daily_content/presentation/state/daily_content_store.dart',
  'lib/features/prayer_times/presentation/screens/home_screen.dart -> lib/features/daily_content/presentation/widgets/dua_of_day_card.dart',
  'lib/features/prayer_times/presentation/screens/home_screen.dart -> lib/features/dua_tasbih/presentation/screens/tasbih_screen.dart',
  'lib/features/prayer_times/presentation/screens/home_screen.dart -> lib/features/dua_tasbih/presentation/state/tasbih_store.dart',
  'lib/features/prayer_times/presentation/screens/home_screen.dart -> lib/features/dua_tasbih/presentation/widgets/dua_card.dart',
  'lib/features/prayer_times/presentation/screens/home_screen.dart -> lib/features/fasting/presentation/state/fasting_store.dart',
  'lib/features/prayer_times/presentation/screens/home_screen.dart -> lib/features/hadith/presentation/state/hadith_store.dart',
  'lib/features/prayer_times/presentation/screens/home_screen.dart -> lib/features/hadith/presentation/widgets/hadith_card.dart',
  'lib/features/prayer_times/presentation/screens/home_screen.dart -> lib/features/muhasaba/presentation/state/muhasaba_store.dart',
  'lib/features/prayer_times/presentation/screens/home_screen.dart -> lib/features/quran/presentation/state/quran_store.dart',
  'lib/features/prayer_times/presentation/screens/home_screen.dart -> lib/features/settings/presentation/state/settings_store.dart',
  'lib/features/prayer_times/presentation/state/home_store.dart -> lib/features/my_mosque/presentation/state/mosque_store.dart',
  'lib/features/prayer_times/presentation/state/home_store.dart -> lib/features/settings/presentation/state/settings_store.dart',
  'lib/features/prayer_times/presentation/widgets/day_timeline_sheet.dart -> lib/features/settings/presentation/widgets/setting_labels.dart',
  'lib/features/prayer_times/presentation/widgets/prayer_detail_sheet.dart -> lib/features/settings/presentation/widgets/setting_labels.dart',
  'lib/features/prayer_times/presentation/widgets/prayer_table.dart -> lib/features/settings/presentation/widgets/setting_labels.dart',
  'lib/features/prayer_times/presentation/widgets/tasbih_quick_card.dart -> locator',
  'lib/features/qibla/presentation/state/qibla_store.dart -> lib/features/settings/presentation/state/settings_store.dart',
  'lib/features/quran/presentation/state/quran_store.dart -> package:shared_preferences',
  'lib/features/quran/presentation/widgets/reader_settings_sheet.dart -> GetIt',
  'lib/features/ramadan/presentation/screens/ramadan_screen.dart -> lib/features/prayer_times/presentation/screens/home_formatting.dart',
  'lib/features/ramadan/presentation/screens/ramadan_screen.dart -> lib/features/settings/presentation/state/settings_store.dart',
  'lib/features/ramadan/presentation/state/ramadan_store.dart -> lib/features/settings/presentation/state/settings_store.dart',
  'lib/features/ruqyah/presentation/screens/ruqyah_category_screen.dart -> lib/features/quran/presentation/widgets/reader_settings_sheet.dart',
  'lib/features/ruqyah/presentation/screens/ruqyah_screen.dart -> lib/features/muhasaba/presentation/widgets/tracker_visuals.dart',
  'lib/features/ruqyah/presentation/screens/tibb_nabawi_screen.dart -> lib/features/quran/presentation/widgets/reader_settings_sheet.dart',
  'lib/features/ruqyah/presentation/widgets/ruqyah_card.dart -> lib/features/quran/presentation/state/quran_store.dart',
  'lib/features/settings/presentation/screens/settings_screen.dart -> lib/features/onboarding/presentation/screens/lock_screen.dart',
  'lib/features/settings/presentation/screens/settings_screen.dart -> lib/features/onboarding/presentation/screens/onboarding_screen.dart',
  'lib/features/settings/presentation/screens/settings_screen.dart -> lib/features/onboarding/presentation/state/app_lock_store.dart',
  'lib/features/settings/presentation/screens/settings_screen.dart -> lib/features/quran/presentation/state/quran_store.dart',
  'lib/features/settings/presentation/screens/settings_screen.dart -> lib/features/quran/presentation/widgets/reader_settings_sheet.dart',
};
