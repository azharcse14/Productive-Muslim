import 'package:flutter/material.dart';

import '../../../../core/theme/productive_muslim_tokens.dart';
import '../../../../shared/extensions/context_ext.dart';
import '../../domain/entities/dua.dart';
import '../widgets/dua_card.dart';

/// One dua category: full cards with Arabic, transliteration, translation,
/// reference and (when authentic) the repetition count.
final class DuaCategoryScreen extends StatelessWidget {
  const DuaCategoryScreen({required this.category, super.key});

  final DuaCategory category;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.duaCategoryName(category.id))),
      body: SafeArea(
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(
            QSpace.s5,
            QSpace.s3,
            QSpace.s5,
            QSpace.s5,
          ),
          itemCount: category.duas.length,
          separatorBuilder: (_, _) => const SizedBox(height: QSpace.s3),
          itemBuilder: (context, index) => DuaCard(dua: category.duas[index]),
        ),
      ),
    );
  }
}
