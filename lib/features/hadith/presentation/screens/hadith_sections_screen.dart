import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/theme/productive_muslim_tokens.dart';
import '../../../../core/theme/productive_muslim_typography.dart';
import '../../../../core/utils/haptics.dart';
import '../../../../core/utils/locale_digits.dart';
import '../../../../shared/extensions/context_ext.dart';
import '../../../../shared/widgets/q_card.dart';
import '../../../../shared/widgets/q_number_dialog.dart';
import '../../domain/entities/hadith_book.dart';
import 'hadith_section_screen.dart';

/// The chapters/sections of one [HadithBook].
final class HadithSectionsScreen extends StatelessWidget {
  const HadithSectionsScreen({required this.book, super.key});

  final HadithBook book;

  void _open(BuildContext context, HadithSection section) {
    Haptics.selection();
    unawaited(
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => HadithSectionScreen(book: book, section: section),
        ),
      ),
    );
  }

  /// Opens the chapter holding hadith [number] (in the numbering of the
  /// shown chapter list), focused on that hadith.
  Future<void> _goToNumber(
    BuildContext context,
    List<HadithSection> sections,
  ) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final number = await showNumberDialog(
      context,
      title: l10n.hadithGoToNumber,
      hint: l10n.hadithNumberHint,
      actionLabel: l10n.goToAction,
    );
    if (number == null || !context.mounted) {
      return;
    }
    final section = sections
        .where((s) => (s.first ?? 0) <= number && number <= (s.last ?? -1))
        .firstOrNull;
    if (section == null) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.hadithNumberNotFound)),
      );
      return;
    }
    unawaited(
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => HadithSectionScreen(
            book: book,
            section: section,
            focusNumber: number,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final q = context.q;
    final languageCode = Localizations.localeOf(context).languageCode;
    final sections = book.sectionsFor(languageCode);
    return Scaffold(
      appBar: AppBar(
        title: Text(book.titleFor(languageCode)),
        actions: [
          if (sections.any((s) => s.first != null && s.last != null))
            IconButton(
              tooltip: context.l10n.hadithGoToNumber,
              icon: const Icon(Icons.format_list_numbered),
              onPressed: () => unawaited(_goToNumber(context, sections)),
            ),
        ],
      ),
      body: SafeArea(
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(
            QSpace.s5,
            QSpace.s3,
            QSpace.s5,
            QSpace.s5,
          ),
          itemCount: sections.length,
          separatorBuilder: (_, _) => const SizedBox(height: QSpace.s2),
          itemBuilder: (context, index) {
            final section = sections[index];
            final count = section.count;
            return Semantics(
              button: true,
              child: QCard(
                onTap: () => _open(context, section),
                padding: const EdgeInsets.all(QSpace.s4),
                child: Row(
                  children: [
                    ConstrainedBox(
                      constraints: const BoxConstraints(minWidth: 28),
                      child: Text(
                        // The book's own number: Ibn Majah starts at 0.
                        LocaleDigits.localize(
                          '${section.number}',
                          languageCode,
                        ),
                        style: QType.titleSm.copyWith(color: q.ink3),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            section.name,
                            style: QType.body.copyWith(color: q.ink),
                          ),
                          if (count != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              LocaleDigits.localize(
                                context.l10n.hadithCount(count),
                                languageCode,
                              ),
                              style: QType.caption.copyWith(color: q.ink2),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right, color: q.ink3),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
