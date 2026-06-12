import 'package:flutter/material.dart';

import '../../../../shared/extensions/context_ext.dart';
import '../../../../shared/widgets/placeholder_screen.dart';

/// Muhasaba tab — tracker + dashboard land in Phase 7.
final class MuhasabaScreen extends StatelessWidget {
  const MuhasabaScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      PlaceholderScreen(title: context.l10n.tabMuhasaba);
}
