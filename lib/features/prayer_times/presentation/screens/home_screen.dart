import 'package:flutter/material.dart';

import '../../../../shared/extensions/context_ext.dart';
import '../../../../shared/widgets/placeholder_screen.dart';

/// Home tab — replaced with the smart-countdown home in Phase 3.
final class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      PlaceholderScreen(title: context.l10n.tabHome);
}
