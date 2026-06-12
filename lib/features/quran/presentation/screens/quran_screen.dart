import 'package:flutter/material.dart';

import '../../../../shared/extensions/context_ext.dart';
import '../../../../shared/widgets/placeholder_screen.dart';

/// Quran tab — surah list + reader land in Phase 8.
final class QuranScreen extends StatelessWidget {
  const QuranScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      PlaceholderScreen(title: context.l10n.tabQuran);
}
