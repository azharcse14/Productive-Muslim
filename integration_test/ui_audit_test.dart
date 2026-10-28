import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:productive_muslim/core/di/locator.dart';
import 'package:productive_muslim/core/router/app_router.dart';
import 'package:productive_muslim/features/settings/domain/entities/app_settings.dart';
import 'package:productive_muslim/features/settings/domain/entities/location_config.dart';
import 'package:productive_muslim/features/settings/presentation/state/settings_store.dart';
import 'package:productive_muslim/main.dart';

/// UI audit: every main screen × theme/locale/text-scale variants.
/// Run: flutter drive --driver=test_driver/integration_test.dart \
///        --target=integration_test/ui_audit_test.dart
const _screens = {
  'home': '/home',
  'quran': '/quran',
  'quran_reader': '/quran/1',
  'muhasaba': '/muhasaba',
  'dua': '/dua',
  'more': '/more',
  'settings': '/more/settings',
  'notifications': '/more/settings/notifications',
  'location': '/location',
  'mosque': '/mosque',
  'qibla': '/qibla',
  'special_times': '/special-times',
  'ramadan': '/ramadan',
  'calendar': '/calendar',
  'hadith': '/hadith',
  'ruqyah': '/ruqyah',
  'fasting': '/fasting',
  'expenses': '/expenses',
  'achievements': '/achievements',
  'zakat': '/zakat',
  'calculators': '/calculators',
  'fitra': '/calculators/fitra',
  'qaza': '/calculators/qaza',
  'faraid': '/calculators/faraid',
  'age': '/calculators/age',
};

const _variants = [
  (name: 'light_en', mode: AppThemeMode.light, locale: 'en', scale: 1.0),
  (name: 'dark_en', mode: AppThemeMode.dark, locale: 'en', scale: 1.0),
  (name: 'light_bn', mode: AppThemeMode.light, locale: 'bn', scale: 1.0),
  (name: 'light_bn_x1.3', mode: AppThemeMode.light, locale: 'bn', scale: 1.3),
];

Future<void> _settle(WidgetTester tester) async {
  // Countdown ticks forever, so pumpAndSettle would never return.
  for (var i = 0; i < 15; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('ui audit screenshots', (tester) async {
    await setupLocator();
    final store = locator<SettingsStore>();
    await store.setLocation(
      const GpsLocation(latitude: 23.8103, longitude: 90.4125, resolvedName: 'Dhaka'),
    );
    await store.setSetupComplete(complete: true);

    await tester.pumpWidget(const ProductiveMuslimApp());
    await _settle(tester);

    for (final v in _variants) {
      await store.setThemeMode(v.mode);
      await store.setLocale(v.locale);
      binding.platformDispatcher.textScaleFactorTestValue = v.scale;
      for (final MapEntry(key: name, value: path) in _screens.entries) {
        appRouter.go(path);
        await _settle(tester);
        await binding.takeScreenshot('${v.name}/$name');
      }
    }
    binding.platformDispatcher.clearAllTestValues();
  });
}
