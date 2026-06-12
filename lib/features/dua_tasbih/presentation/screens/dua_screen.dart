import 'package:flutter/material.dart';

import '../../../../shared/extensions/context_ext.dart';
import '../../../../shared/widgets/placeholder_screen.dart';

/// Dua & Tasbih tab — lands in Phase 9.
final class DuaScreen extends StatelessWidget {
  const DuaScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      PlaceholderScreen(title: context.l10n.tabDua);
}
