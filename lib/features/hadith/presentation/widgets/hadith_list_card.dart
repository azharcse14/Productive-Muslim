import 'dart:async';

import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../../core/theme/productive_muslim_tokens.dart';
import '../../../../core/theme/productive_muslim_typography.dart';
import '../../../../core/utils/haptics.dart';
import '../../../../core/utils/locale_digits.dart';
import '../../../../shared/extensions/context_ext.dart';
import '../../../../shared/reader/reader_text_size.dart';
import '../../../../shared/widgets/q_card.dart';
import '../../../../shared/widgets/q_copy_button.dart';
import '../../domain/entities/hadith.dart';
import '../state/hadith_store.dart';

/// A card for one bundled [Hadith]: Arabic, translation, narrator, grade chip
/// and reference — with a favorite heart when [store] is given.
final class HadithListCard extends StatelessWidget {
  const HadithListCard({required this.hadith, this.store, super.key});

  final Hadith hadith;
  final HadithStore? store;

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
                style: QType.quran(
                  arabicBodySize(context),
                ).copyWith(color: q.ink),
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
              if (store case final store?)
                SignalBuilder(
                  builder: (context) {
                    final active = store.favorites.value.contains(hadith.id);
                    return IconButton(
                      tooltip: active
                          ? l10n.favoriteRemoveLabel
                          : l10n.favoriteAddLabel,
                      icon: Icon(
                        active ? Icons.favorite : Icons.favorite_border,
                        color: active ? q.primary : q.ink3,
                      ),
                      onPressed: () {
                        Haptics.selection();
                        final messenger = ScaffoldMessenger.of(context);
                        unawaited(
                          store.toggleFavorite(hadith.id).then((saved) {
                            if (!saved) {
                              messenger.showSnackBar(
                                SnackBar(content: Text(l10n.saveFailed)),
                              );
                            }
                          }),
                        );
                      },
                    );
                  },
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
    // English-source grades ("Hasan Sahih", "Shadh, Sahih") are translated
    // word by word, keeping punctuation around a word; unknown words (and
    // Bengali-source grades) pass through.
    final label = [
      for (final word in grade.split(' '))
        if (_wordParts.firstMatch(word) case final m?)
          switch (l10n.hadithGradeWord(m[2]!.toLowerCase())) {
            '—' => word,
            final localized => '${m[1]}$localized${m[3]}',
          }
        else
          word,
    ].join(' ');
    final color = isSahihGrade(grade) ? q.ok : q.ink2;
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

/// Leading punctuation, the word, trailing punctuation ("Shadh," → "Shadh").
final _wordParts = RegExp(
  r'^([^\p{L}\p{M}\p{N}]*)(.*?)([^\p{L}\p{M}\p{N}]*)$',
  unicode: true,
);

/// Qualifiers that weaken a grading even next to "sahih".
const _weakening = [
  'shadh',
  'munkar',
  'daif',
  "da'if",
  'mawdu',
  'batil',
  'malool',
  "ma'lul",
  'শায',
  'মুনকার',
  'যঈফ',
  'দুর্বল',
  'জাল',
  'বাতিল',
  'মা\'লুল',
];

/// True when [grade] is a plain sahih grading (en or bn). Mixed gradings
/// with a weakening qualifier ("Shadh, Sahih", "সহিহ মওকুফ শায",
/// "Munkar Sahih") stay neutral.
bool isSahihGrade(String grade) {
  final g = grade.toLowerCase();
  if (_weakening.any(g.contains)) {
    return false;
  }
  return g.contains('sahih') || g.contains('সহিহ');
}
