import 'package:flutter/material.dart';

import '../../../../core/theme/productive_muslim_tokens.dart';
import '../../../../core/theme/productive_muslim_typography.dart';
import '../../../../shared/extensions/context_ext.dart';
import '../../../../shared/widgets/q_card.dart';
import '../../../../shared/widgets/q_copy_button.dart';
import '../../../quran/presentation/state/quran_store.dart';
import '../../domain/entities/hadith.dart';

/// A card for one bundled [Hadith]: Arabic, translation, narrator, grade chip
/// and reference.
final class HadithListCard extends StatelessWidget {
  const HadithListCard({required this.hadith, super.key});

  final Hadith hadith;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final q = context.q;
    final languageCode = Localizations.localeOf(context).languageCode;
    return QCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (hadith.arabic.isNotEmpty) ...[
            Text(
              hadith.arabic,
              textDirection: TextDirection.rtl,
              style: QType.quran(arabicBodySize()).copyWith(color: q.ink),
            ),
            const SizedBox(height: QSpace.s3),
          ],
          Text(
            hadith.translationFor(languageCode),
            style: QType.body.copyWith(color: q.ink),
          ),
          if (hadith.narrator.isNotEmpty) ...[
            const SizedBox(height: QSpace.s2),
            Text(
              l10n.hadithNarratedBy(hadith.narrator),
              style: QType.caption.copyWith(color: q.ink3),
            ),
          ],
          const SizedBox(height: QSpace.s2),
          Row(
            children: [
              if (hadith.grade.isNotEmpty) ...[
                GradeChip(grade: hadith.grade),
                const SizedBox(width: QSpace.s2),
              ],
              Expanded(
                child: Text(
                  hadith.reference,
                  textAlign: TextAlign.end,
                  style: QType.caption.copyWith(color: q.ink3),
                ),
              ),
              QCopyButton(
                text: [
                  hadith.arabic,
                  hadith.translationFor(languageCode),
                  if (hadith.reference.isNotEmpty) '— ${hadith.reference}',
                ].where((s) => s.isNotEmpty).join('\n'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Small pill showing an authenticity grade. Sahih reads in the positive
/// (ok) tone; anything else in a neutral tone.
final class GradeChip extends StatelessWidget {
  const GradeChip({required this.grade, super.key});

  final String grade;

  @override
  Widget build(BuildContext context) {
    final q = context.q;
    final isSahih = grade.toLowerCase().contains('sahih') ||
        grade.toLowerCase().contains('সহিহ');
    final color = isSahih ? q.ok : q.ink2;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: QSpace.s2,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(QRadius.sm),
      ),
      child: Text(
        grade,
        style: QType.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
