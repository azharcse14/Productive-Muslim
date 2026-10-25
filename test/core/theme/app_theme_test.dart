import 'dart:io';
import 'dart:math' as math;

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

  group('Contrast (WCAG AA, 4.5:1 for text)', () {
    double ratio(Color a, Color b) {
      final la = a.computeLuminance();
      final lb = b.computeLuminance();
      return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
    }

    for (final (name, q) in [
      ('light', ProductiveMuslimColors.light),
      ('dark', ProductiveMuslimColors.dark),
    ]) {
      test('$name: every text token on every base surface', () {
        final text = {
          'ink': q.ink,
          'ink2': q.ink2,
          'ink3': q.ink3,
          'primary': q.primary,
          'accentStrong': q.accentStrong,
          'ok': q.ok,
          'warn': q.warn,
          'urgent': q.urgent,
        };
        final surfaces = {
          'bg': q.bg,
          'surface': q.surface,
          'surface2': q.surface2,
        };
        for (final MapEntry(key: t, value: fg) in text.entries) {
          for (final MapEntry(key: s, value: bg) in surfaces.entries) {
            expect(
              ratio(fg, bg),
              greaterThanOrEqualTo(4.5),
              reason: '$t on $s',
            );
          }
        }
      });

      test('$name: on-colors on their tonal containers', () {
        final pairs = {
          'onPrimary/primary': (q.onPrimary, q.primary),
          'onPrimarySoft/primarySoft': (q.onPrimarySoft, q.primarySoft),
          'onAccentSoft/accentSoft': (q.onAccentSoft, q.accentSoft),
          'ok/okSoft': (q.ok, q.okSoft),
          'warn/warnSoft': (q.warn, q.warnSoft),
          'urgent/urgentSoft': (q.urgent, q.urgentSoft),
        };
        for (final MapEntry(key: name, value: (fg, bg)) in pairs.entries) {
          expect(ratio(fg, bg), greaterThanOrEqualTo(4.5), reason: name);
        }
      });
    }
  });

  group('tokens.css stays 1:1 with ProductiveMuslimColors', () {
    final css = File(
      'docs/design_handoff_productive_muslim/productive_muslim/tokens.css',
    ).readAsStringSync();

    Map<String, Color> block(String selector) {
      final body = RegExp('\\.$selector \\{([^}]*)\\}').firstMatch(css)![1]!;
      return {
        for (final m in RegExp(r'--([a-z0-9-]+):\s*#([0-9A-Fa-f]{6})')
            .allMatches(body))
          m[1]!: Color(int.parse('FF${m[2]}', radix: 16)),
      };
    }

    Map<String, Color> dart(ProductiveMuslimColors q) => {
          'bg': q.bg,
          'surface': q.surface,
          'surface-2': q.surface2,
          'ink': q.ink,
          'ink-2': q.ink2,
          'ink-3': q.ink3,
          'line': q.line,
          'primary': q.primary,
          'on-primary': q.onPrimary,
          'primary-soft': q.primarySoft,
          'on-primary-soft': q.onPrimarySoft,
          'accent': q.accent,
          'accent-strong': q.accentStrong,
          'accent-soft': q.accentSoft,
          'on-accent-soft': q.onAccentSoft,
          'ok': q.ok,
          'ok-soft': q.okSoft,
          'warn': q.warn,
          'warn-soft': q.warnSoft,
          'urgent': q.urgent,
          'urgent-soft': q.urgentSoft,
        };

    test('light', () {
      expect(block('q-light'), dart(ProductiveMuslimColors.light));
    });

    test('dark', () {
      expect(block('q-dark'), dart(ProductiveMuslimColors.dark));
    });
  });
}
