import 'package:flutter/material.dart';

import '../../../../core/theme/qalbee_tokens.dart';
import '../../../../core/theme/qalbee_typography.dart';
import '../../../../core/utils/locale_digits.dart';
import '../../../../shared/extensions/context_ext.dart';
import '../../../../shared/widgets/q_card.dart';
import '../../../../shared/widgets/q_chip.dart';
import '../../domain/entities/dua.dart';

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
          itemBuilder: (context, index) => _DuaCard(dua: category.duas[index]),
        ),
      ),
    );
  }
}

final class _DuaCard extends StatelessWidget {
  const _DuaCard({required this.dua});

  final Dua dua;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final q = context.q;
    final languageCode = Localizations.localeOf(context).languageCode;
    return QCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            dua.arabic,
            textDirection: TextDirection.rtl,
            style: QType.quran(24).copyWith(color: q.ink),
          ),
          const SizedBox(height: QSpace.s3),
          Text(
            dua.transliteration,
            style: QType.caption.copyWith(
              color: q.ink2,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: QSpace.s2),
          Text(
            dua.translationFor(languageCode),
            style: QType.body.copyWith(color: q.ink),
          ),
          if (dua.reference.isNotEmpty) ...[
            const SizedBox(height: QSpace.s2),
            Text(
              '${l10n.referenceLabel} — ${dua.reference}',
              style: QType.caption.copyWith(color: q.ink3),
            ),
          ],
          if (dua.repeat > 1) ...[
            const SizedBox(height: QSpace.s3),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: QChip(
                label: LocaleDigits.localize(
                  l10n.repeatTimes(dua.repeat),
                  languageCode,
                ),
                active: true,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
