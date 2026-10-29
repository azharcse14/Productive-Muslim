import 'dart:async';

import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../../core/di/locator.dart';
import '../../../../core/theme/productive_muslim_tokens.dart';
import '../../../../core/theme/productive_muslim_typography.dart';
import '../../../../core/utils/locale_digits.dart';
import '../../../../shared/extensions/context_ext.dart';
import '../../../../shared/widgets/q_card.dart';
import '../../../../shared/widgets/q_copy_button.dart';
import '../../../../shared/widgets/q_error_retry.dart';
import '../../../../shared/widgets/q_skeleton.dart';
import '../../../quran/presentation/state/quran_store.dart';
import '../../domain/entities/hadith_book.dart';
import '../state/hadith_section_store.dart';
import '../widgets/hadith_list_card.dart';

/// Reader for one section of a book — hadith are fetched from the online
/// dataset, with loading and retry states.
final class HadithSectionScreen extends StatefulWidget {
  const HadithSectionScreen({
    required this.book,
    required this.section,
    super.key,
  });

  final HadithBook book;
  final HadithSection section;

  @override
  State<HadithSectionScreen> createState() => _HadithSectionScreenState();
}

final class _HadithSectionScreenState extends State<HadithSectionScreen> {
  final HadithSectionStore _store = locator<HadithSectionStore>();

  /// Language the screen was opened in, pinned for its lifetime: the
  /// section came from that language's list (bn chapter numbers differ
  /// from en), so a mid-screen language switch must not refetch — or
  /// retry — a different chapter under this title.
  String? _lang;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Locale is read here (not initState) — inherited widgets aren't yet
    // available during initState. Guarded so it runs only once.
    if (_lang == null) {
      _lang = Localizations.localeOf(context).languageCode;
      unawaited(_load());
    }
  }

  Future<void> _load() => _store.load(widget.book, widget.section, _lang!);

  @override
  void dispose() {
    _store.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(widget.section.name)),
      body: SafeArea(
        child: SignalBuilder(
          builder: (context) {
            if (_store.loading.value) {
              return const QSkeletonList();
            }
            if (_store.failed.value) {
              return QErrorRetry(
                message: l10n.hadithLoadError,
                retryLabel: l10n.hadithRetry,
                onRetry: () => unawaited(_load()),
              );
            }
            final bnSource = widget.book.usesBanglaSource(_lang!);
            final items = _store.items.value;
            if (items.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(QSpace.s6),
                  child: Text(
                    l10n.hadithSectionEmpty,
                    textAlign: TextAlign.center,
                    style: QType.body.copyWith(color: context.q.ink2),
                  ),
                ),
              );
            }
            // Whole section came back English despite a bn request → one banner
            // instead of a note on every card.
            final allFallback =
                items.isNotEmpty && items.every((h) => h.fallbackTranslation);
            final leading = allFallback ? 1 : 0;
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(
                QSpace.s5,
                QSpace.s3,
                QSpace.s5,
                QSpace.s5,
              ),
              itemCount: items.length + leading + 1,
              separatorBuilder: (_, _) => const SizedBox(height: QSpace.s3),
              itemBuilder: (context, index) {
                if (allFallback && index == 0) {
                  return _Banner(text: l10n.hadithBengaliUnavailableSection);
                }
                final i = index - leading;
                if (i == items.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: QSpace.s2),
                    child: Text(
                      bnSource
                          ? l10n.hadithSourceNoteBn
                          : l10n.hadithSourceNote,
                      textAlign: TextAlign.center,
                      style: QType.caption.copyWith(color: context.q.ink3),
                    ),
                  );
                }
                return _BookHadithCard(
                  hadith: items[i],
                  // Per-hadith note only for scattered gaps (not when the whole
                  // section is English — the banner covers that).
                  showFallbackNote:
                      !allFallback && items[i].fallbackTranslation,
                );
              },
            );
          },
        ),
      ),
    );
  }
}

final class _BookHadithCard extends StatelessWidget {
  const _BookHadithCard({required this.hadith, this.showFallbackNote = false});

  final BookHadith hadith;
  final bool showFallbackNote;

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
          if (hadith.translation.isNotEmpty)
            Text(hadith.translation, style: QType.body.copyWith(color: q.ink)),
          if (hadith.narrator.isNotEmpty) ...[
            const SizedBox(height: QSpace.s2),
            Text(
              l10n.hadithNarratedBy(hadith.narrator),
              style: QType.caption.copyWith(color: q.ink3),
            ),
          ],
          if (showFallbackNote) ...[
            const SizedBox(height: QSpace.s2),
            Text(
              l10n.hadithBengaliUnavailable,
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
                  hadith.translation,
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

/// Thin info banner shown above a section whose Bengali translation is missing.
final class _Banner extends StatelessWidget {
  const _Banner({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final q = context.q;
    return Container(
      padding: const EdgeInsets.all(QSpace.s3),
      decoration: BoxDecoration(
        color: q.primarySoft,
        borderRadius: BorderRadius.circular(QRadius.sm),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 16, color: q.onPrimarySoft),
          const SizedBox(width: QSpace.s2),
          Expanded(
            child: Text(text, style: QType.caption.copyWith(color: q.ink2)),
          ),
        ],
      ),
    );
  }
}
