import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Release builds run R8. A missing keep rule doesn't fail the build — it
/// silently breaks scheduled notifications on users' phones — so the config
/// that protects them is pinned here.
void main() {
  final gradle = File('android/app/build.gradle.kts').readAsStringSync();

  test('release build is minified, shrunk and signed from key.properties', () {
    expect(gradle, contains('isMinifyEnabled = true'));
    expect(gradle, contains('isShrinkResources = true'));
    expect(gradle, contains('"proguard-rules.pro"'));
    expect(gradle, contains('rootProject.file("key.properties")'));
  });

  test('proguard keeps flutter_local_notifications and Gson models', () {
    final rules = File('android/app/proguard-rules.pro').readAsStringSync();
    expect(
      rules,
      contains('-keep class com.dexterous.flutterlocalnotifications.** { *; }'),
    );
    expect(rules, contains('com.google.gson.reflect.TypeToken'));
  });

  test('the notification small icon survives shrinkResources', () {
    final scheduler = File(
      'lib/features/notifications/data/local_notifications_scheduler.dart',
    ).readAsStringSync();
    final icon = RegExp(
      r"AndroidInitializationSettings\('@([^']+)'\)",
    ).firstMatch(scheduler)![1]!;
    final keep = File(
      'android/app/src/main/res/raw/keep.xml',
    ).readAsStringSync();
    expect(keep, contains('@$icon'));
  });

  test('signing secrets are gitignored', () {
    final ignore = File('.gitignore').readAsStringSync();
    for (final p in ['key.properties', '*.jks', '*.keystore']) {
      expect(ignore.split('\n'), contains(p));
    }
  });
}
