import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

/// Saves `binding.takeScreenshot` output for the UI audit.
Future<void> main() => integrationDriver(
  onScreenshot: (name, bytes, [args]) async {
    final file = File('build/ui_audit/$name.png');
    await file.create(recursive: true);
    await file.writeAsBytes(bytes);
    return true;
  },
);
