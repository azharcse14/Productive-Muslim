import 'dart:async';

import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../../core/di/locator.dart';
import '../../../../core/theme/productive_muslim_tokens.dart';
import '../../../../core/theme/productive_muslim_typography.dart';
import '../../../../core/utils/haptics.dart';
import '../../../../core/utils/locale_digits.dart';
import '../../../../shared/extensions/context_ext.dart';
import '../../../../shared/widgets/q_card.dart';
import '../../../../shared/widgets/q_chip.dart';
import '../../../../shared/widgets/q_copy_button.dart';
import '../../../quran/presentation/state/quran_store.dart';
import '../../domain/entities/dua.dart';
import '../state/dua_favorites_store.dart';

/// Full dua card: Arabic, transliteration, translation, reference and (when
/// authentic) the repetition count — with a favorite heart toggle.
final class DuaCard extends StatelessWidget {
  const DuaCard({required this.dua, super.key});

  final Dua dua;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final q = context.q;
    final favorites = locator<DuaFavoritesStore>();
    final languageCode = Localizations.localeOf(context).languageCode;
    return QCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                // Rebuilds when the Quran reader's font size changes.
                child: SignalBuilder(
                  builder: (context) => Text(
                    dua.arabic,
                    textDirection: TextDirection.rtl,
                    // A non-Arabic TTS garbles raw Arabic glyphs; speak the
                    // transliteration instead.
                    semanticsLabel: dua.transliterationFor(languageCode),
                    style: QType.quran(arabicBodySize()).copyWith(color: q.ink),
                  ),
                ),
              ),
              SignalBuilder(
                builder: (context) {
                  final active = favorites.ids.value.contains(dua.id);
                  final label = active
                      ? l10n.favoriteRemoveLabel
                      : l10n.favoriteAddLabel;
                  // IconButton's tooltip already labels the button.
                  return IconButton(
                    tooltip: label,
                    icon: Icon(
                      active ? Icons.favorite : Icons.favorite_border,
                      color: active ? q.primary : q.ink3,
                    ),
                    onPressed: () {
                      Haptics.selection();
                      unawaited(favorites.toggle(dua.id));
                    },
                  );
                },
              ),
              QCopyButton(
                text: '${dua.arabic}\n${dua.translationFor(languageCode)}'
                    '${dua.reference.isEmpty ? '' : '\n— ${dua.reference}'}',
              ),
            ],
          ),
          const SizedBox(height: QSpace.s3),
          Text(
            dua.transliterationFor(languageCode),
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
