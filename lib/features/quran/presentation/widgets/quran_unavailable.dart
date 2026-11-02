import 'package:flutter/material.dart';

import '../../../../shared/extensions/context_ext.dart';
import '../../../../shared/widgets/q_empty_state.dart';

/// Shown in place of a Quran screen when quran.db failed to open at startup
/// and `QuranStore` was unregistered (see `setupLocator`).
final class QuranUnavailable extends StatelessWidget {
  const QuranUnavailable({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(context.l10n.quranTitle)),
    body: QEmptyState(
      icon: Icons.menu_book_outlined,
      body: context.l10n.quranUnavailable,
    ),
  );
}
