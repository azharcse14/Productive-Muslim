import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../../core/theme/productive_muslim_tokens.dart';
import '../../../../core/theme/productive_muslim_typography.dart';
import '../../../../core/utils/locale_digits.dart';
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
            // Rebuilds when the reader text size changes.
            SignalBuilder(
              builder: (context) => Text(
                hadith.arabic,
                textDirection: TextDirection.rtl,
                // Lets screen readers pick an Arabic voice.
                locale: const Locale('ar'),
                // Sized by the reader setting, so the system text scale
                // must not multiply it again.
                textScaler: TextScaler.noScaling,
                style: QType.quran(arabicBodySize()).copyWith(color: q.ink),
              ),
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
                  LocaleDigits.localize(hadith.reference, languageCode),
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
    final l10n = context.l10n;
    // English-source grades ("Hasan Sahih", "Daif Isnaad") are translated
    // word by word; unknown words (and Bengali-source grades) pass through.
    final label = [
      for (final word in grade.split(' '))
        switch (l10n.hadithGradeWord(word.toLowerCase())) {
          '—' => word,
          final localized => localized,
        },
    ].join(' ');
    final isSahih =
        grade.toLowerCase().contains('sahih') ||
        grade.toLowerCase().contains('সহিহ');
    final color = isSahih ? q.ok : q.ink2;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: QSpace.s2, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(QRadius.sm),
      ),
      child: Text(
        label,
        style: QType.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
