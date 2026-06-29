import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:productive_muslim/core/theme/app_theme.dart';
import 'package:productive_muslim/core/theme/productive_muslim_colors.dart';

void main() {
  group('AppTheme', () {
    test('light theme registers the ProductiveMuslimColors extension with light tokens',
        () {
      final theme = AppTheme.light();
      final q = theme.extension<ProductiveMuslimColors>();
      expect(q, isNotNull);
      expect(q!.bg, const Color(0xFFF6F4EE));
      expect(q.primary, const Color(0xFF15564D));
      expect(theme.brightness, Brightness.light);
    });

    test('dark theme is the designed palette, not an inversion', () {
      final theme = AppTheme.dark();
      final q = theme.extension<ProductiveMuslimColors>()!;
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
        ProductiveMuslimColors.light.bg,
      );
      expect(AppTheme.dark().scaffoldBackgroundColor, ProductiveMuslimColors.dark.bg);
    });

    test('ProductiveMuslimColors lerp interpolates between themes', () {
      final mid = ProductiveMuslimColors.light.lerp(ProductiveMuslimColors.dark, 0.5);
      expect(mid.bg, Color.lerp(ProductiveMuslimColors.light.bg, ProductiveMuslimColors.dark.bg, 0.5));
    });
  });
}
