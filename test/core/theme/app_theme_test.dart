import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qalbee/core/theme/app_theme.dart';
import 'package:qalbee/core/theme/qalbee_colors.dart';

void main() {
  group('AppTheme', () {
    test('light theme registers the QalbeeColors extension with light tokens',
        () {
      final theme = AppTheme.light();
      final q = theme.extension<QalbeeColors>();
      expect(q, isNotNull);
      expect(q!.bg, const Color(0xFFF6F4EE));
      expect(q.primary, const Color(0xFF15564D));
      expect(theme.brightness, Brightness.light);
    });

    test('dark theme is the designed palette, not an inversion', () {
      final theme = AppTheme.dark();
      final q = theme.extension<QalbeeColors>()!;
      expect(q.bg, const Color(0xFF0E1513));
      expect(q.ink, const Color(0xFFE4E9E4));
      expect(q.primary, const Color(0xFF79C7B6));
      expect(theme.brightness, Brightness.dark);
    });

    test('Material 3 is enabled', () {
      expect(AppTheme.light().useMaterial3, isTrue);
      expect(AppTheme.dark().useMaterial3, isTrue);
    });

    test('scaffold background uses the bg token, not surface', () {
      expect(
        AppTheme.light().scaffoldBackgroundColor,
        QalbeeColors.light.bg,
      );
      expect(AppTheme.dark().scaffoldBackgroundColor, QalbeeColors.dark.bg);
    });

    test('QalbeeColors lerp interpolates between themes', () {
      final mid = QalbeeColors.light.lerp(QalbeeColors.dark, 0.5);
      expect(mid.bg, Color.lerp(QalbeeColors.light.bg, QalbeeColors.dark.bg, 0.5));
    });
  });
}
