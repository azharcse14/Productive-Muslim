import 'package:flutter/material.dart';

import '../../../../core/theme/productive_muslim_colors.dart';

/// Curated icon set for tracker items (keys are stored in the DB).
abstract final class TrackerVisuals {
  static const icons = <String, IconData>{
    'mosque': Icons.mosque_outlined,
    'book': Icons.menu_book_outlined,
    'beads': Icons.grain,
    'heart': Icons.favorite_outline,
    'moon': Icons.nightlight_outlined,
    'sun': Icons.wb_sunny_outlined,
    'spark': Icons.auto_awesome_outlined,
    'food': Icons.restaurant_outlined,
    'water': Icons.water_drop_outlined,
    'walk': Icons.directions_walk_outlined,
    'star': Icons.star_outline,
    'speech': Icons.chat_bubble_outline,
    'hands': Icons.volunteer_activism_outlined,
    'people': Icons.groups_outlined,
    'globe': Icons.public_outlined,
    'library': Icons.local_library_outlined,
    'shield': Icons.shield_outlined,
    'healing': Icons.healing_outlined,
    'eye': Icons.visibility_outlined,
    'protect': Icons.security_outlined,
  };

  static IconData iconOf(String key) => icons[key] ?? Icons.auto_awesome;

  /// Curated palette — token-derived, no raw colors in feature widgets.
  static List<Color> palette(ProductiveMuslimColors q) => [
    q.primary,
    q.accentStrong,
    q.ok,
    q.warn,
    q.onPrimarySoft,
    q.ink2,
  ];

  static Color colorOf(ProductiveMuslimColors q, int index) {
    final colors = palette(q);
    return colors[index % colors.length];
  }
}
