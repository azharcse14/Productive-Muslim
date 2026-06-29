import 'package:flutter/material.dart';

import '../../../../core/theme/productive_muslim_tokens.dart';
import '../../../../core/theme/productive_muslim_typography.dart';
import '../../../../core/utils/locale_digits.dart';
import '../../../../shared/extensions/context_ext.dart';
import '../../../../shared/widgets/q_card.dart';
import '../../../../shared/widgets/q_chip.dart';
import '../../domain/entities/ruqyah.dart';

/// Full ruqyah card: title, Arabic, transliteration, translation, reference
/// and (when prescribed) the recitation count.
final class RuqyahCard extends StatelessWidget {
  const RuqyahCard({required this.item, super.key});

  final RuqyahItem item;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final q = context.q;
    final languageCode = Localizations.localeOf(context).languageCode;
    final title = item.titleFor(languageCode);
    return QCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title.isNotEmpty) ...[
            Text(title, style: QType.titleSm.copyWith(color: q.primary)),
            const SizedBox(height: QSpace.s3),
          ],
          Text(
            item.arabic,
            textDirection: TextDirection.rtl,
            // A non-Arabic TTS engine garbles raw Arabic glyphs; speak the
            // transliteration instead so screen-reader users hear the words.
            semanticsLabel: item.transliteration,
            style: QType.quran(24).copyWith(color: q.ink),
          ),
          const SizedBox(height: QSpace.s3),
          Text(
            item.transliteration,
            style: QType.caption.copyWith(
              color: q.ink2,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: QSpace.s2),
          Text(
            item.translationFor(languageCode),
            style: QType.body.copyWith(color: q.ink),
          ),
          if (item.reference.isNotEmpty) ...[
            const SizedBox(height: QSpace.s2),
            Text(
              '${l10n.referenceLabel} — ${item.reference}',
              style: QType.caption.copyWith(color: q.ink3),
            ),
          ],
          if (item.repeat > 1) ...[
            const SizedBox(height: QSpace.s3),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: QChip(
                label: LocaleDigits.localize(
                  l10n.repeatTimes(item.repeat),
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
