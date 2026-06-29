import 'package:flutter/material.dart';

import '../../../../core/theme/productive_muslim_colors.dart';
import '../../domain/achievements.dart';

/// Icon + tier-color scheme for badges. Reuses the muhasaba icon vocabulary
/// where it overlaps; tier colors come only from tokens (no raw colors).
abstract final class AchievementIcons {
  static const icons = <String, IconData>{
    'spark': Icons.auto_awesome_outlined,
    'fire': Icons.local_fire_department_outlined,
    'mosque': Icons.mosque_outlined,
    'beads': Icons.grain,
    'book': Icons.menu_book_outlined,
    'library': Icons.local_library_outlined,
    'star': Icons.star_outline,
    'sun': Icons.wb_sunny_outlined,
    'moon': Icons.nightlight_outlined,
  };

  static IconData of(String key) => icons[key] ?? Icons.auto_awesome;

  /// Tier accent (used only on unlocked badges) — token-derived.
  static Color tierColor(ProductiveMuslimColors q, AchievementTier tier) =>
      switch (tier) {
        AchievementTier.bronze => q.primary,
        AchievementTier.silver => q.accentStrong,
        AchievementTier.gold => q.accent,
      };

  static Color tierSoft(ProductiveMuslimColors q, AchievementTier tier) =>
      switch (tier) {
        AchievementTier.bronze => q.primarySoft,
        AchievementTier.silver => q.accentSoft,
        AchievementTier.gold => q.accentSoft,
      };
}
