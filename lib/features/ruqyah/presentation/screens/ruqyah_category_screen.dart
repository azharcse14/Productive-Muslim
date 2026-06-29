import 'package:flutter/material.dart';

import '../../../../core/theme/productive_muslim_tokens.dart';
import '../../../../shared/extensions/context_ext.dart';
import '../../domain/entities/ruqyah.dart';
import '../widgets/ruqyah_card.dart';

/// One ruqyah category: full cards with title, Arabic, transliteration,
/// translation, reference and (when prescribed) the recitation count.
final class RuqyahCategoryScreen extends StatelessWidget {
  const RuqyahCategoryScreen({required this.category, super.key});

  final RuqyahCategory category;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.ruqyahCategoryName(category.id))),
      body: SafeArea(
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(
            QSpace.s5,
            QSpace.s3,
            QSpace.s5,
            QSpace.s5,
          ),
          itemCount: category.items.length,
          separatorBuilder: (_, _) => const SizedBox(height: QSpace.s3),
          itemBuilder: (context, index) =>
              RuqyahCard(item: category.items[index]),
        ),
      ),
    );
  }
}
