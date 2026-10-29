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

/// Opens [dua] alone in a bottom sheet (e.g. the Home "Dua of the day").
Future<void> showDuaSheet(BuildContext context, Dua dua) {
  final favorites = locator<DuaFavoritesStore>();
  if (!favorites.loaded.value) {
    unawaited(favorites.load());
  }
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(QSpace.s5, 0, QSpace.s5, QSpace.s5),
        child: DuaCard(dua: dua),
      ),
    ),
  );
}

/// Full dua card: Arabic, transliteration, translation, reference and (when
/// authentic) the repetition count — with a favorite heart toggle. The
/// count chip is a tap-to-count session counter (not persisted).
final class DuaCard extends StatefulWidget {
  const DuaCard({required this.dua, super.key});

  final Dua dua;

  @override
  State<DuaCard> createState() => _DuaCardState();
}

final class _DuaCardState extends State<DuaCard>
    with AutomaticKeepAliveClientMixin {
  /// Repetitions counted this visit.
  int _count = 0;

  Dua get dua => widget.dua;

  // A started count survives scrolling the card out of a lazy list.
  @override
  bool get wantKeepAlive => _count > 0;

  void _increment() {
    if (_count >= dua.repeat) {
      return;
    }
    setState(() => _count++);
    updateKeepAlive();
    if (_count == dua.repeat) {
      Haptics.medium();
    }
  }

  void _reset() {
    if (_count == 0) {
      return;
    }
    Haptics.selection();
    setState(() => _count = 0);
    updateKeepAlive();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
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
                // Rebuilds when the reader text size changes.
                child: SignalBuilder(
                  builder: (context) => Text(
                    dua.arabic,
                    textDirection: TextDirection.rtl,
                    // A non-Arabic TTS garbles raw Arabic glyphs; speak the
                    // transliteration instead.
                    semanticsLabel: dua.transliterationFor(languageCode),
                    // Sized by the reader setting, so the system text scale
                    // must not multiply it again.
                    textScaler: TextScaler.noScaling,
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
                text:
                    '${dua.arabic}\n${dua.translationFor(languageCode)}'
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
            _repeatCounter(context),
          ],
        ],
      ),
    );
  }

  Widget _repeatCounter(BuildContext context) {
    final l10n = context.l10n;
    final languageCode = Localizations.localeOf(context).languageCode;
    String digits(int n) => LocaleDigits.localize('$n', languageCode);
    return Row(
      children: [
        Semantics(
          button: true,
          label: l10n.duaRepeatCounterLabel(digits(_count), digits(dua.repeat)),
          onTap: _increment,
          onLongPress: _reset,
          excludeSemantics: true,
          child: GestureDetector(
            onLongPress: _reset,
            child: QChip(
              label: _count == 0
                  ? LocaleDigits.localize(
                      l10n.repeatTimes(dua.repeat),
                      languageCode,
                    )
                  : l10n.duaRepeatProgress(digits(_count), digits(dua.repeat)),
              icon: _count >= dua.repeat ? Icons.check : null,
              active: true,
              onTap: _increment,
            ),
          ),
        ),
        if (_count > 0)
          IconButton(
            tooltip: l10n.tasbihReset,
            icon: Icon(Icons.restart_alt, size: 20, color: context.q.ink3),
            onPressed: _reset,
          ),
      ],
    );
  }
}
