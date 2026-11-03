import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/theme/productive_muslim_tokens.dart';
import '../../../../core/theme/productive_muslim_typography.dart';
import '../../../../core/utils/haptics.dart';
import '../../../../core/utils/locale_digits.dart';
import '../../../../shared/extensions/context_ext.dart';
import '../../../../shared/widgets/q_card.dart';
import '../../../../shared/widgets/q_number_dialog.dart';
import '../../domain/entities/hadith_book.dart';

/// The chapters/sections of one [HadithBook].
final class HadithSectionsScreen extends StatelessWidget {
  const HadithSectionsScreen({required this.book, super.key});

  final HadithBook book;

  void _open(BuildContext context, HadithSection section, {int? focus}) {
    Haptics.selection();
    unawaited(
      context.pushNamed(
        Routes.hadithSection.name,
        pathParameters: {'book': book.id, 'section': '${section.number}'},
        queryParameters: {'n': ?focus?.toString()},
      ),
    );
  }

  /// Opens the chapter holding hadith [number] — the number its card shows
  /// (Sahih Muslim's standard reference, not the internal one) — focused on
  /// that hadith.
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
    final matches = sections.where((s) => s.holds(number)).toList();
    if (matches.isEmpty) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.hadithNumberNotFound)),
      );
      return;
    }
    // Lettered variants can span chapters (Sahih Muslim 274a–k in one,
    // 274l–m in another): let the user pick instead of hiding the rest.
    final section = matches.length == 1
        ? matches.single
        : await _pickSection(context, number, matches);
    if (section == null || !context.mounted) {
      return;
    }
    _open(context, section, focus: number);
  }

  Future<HadithSection?> _pickSection(
    BuildContext context,
    int number,
    List<HadithSection> matches,
  ) {
    final languageCode = Localizations.localeOf(context).languageCode;
    return showModalBottomSheet<HadithSection>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(
                QSpace.s5,
                QSpace.s5,
                QSpace.s5,
                QSpace.s2,
              ),
              child: Text(
                sheetContext.l10n.hadithNumberInChapters(
                  LocaleDigits.localize('$number', languageCode),
                ),
                style: QType.title.copyWith(color: sheetContext.q.ink),
              ),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final section in matches)
                    ListTile(
                      leading: Text(
                        LocaleDigits.localize(
                          '${section.number}',
                          languageCode,
                        ),
                      ),
                      title: Text(section.name),
                      onTap: () => Navigator.of(sheetContext).pop(section),
                    ),
                ],
              ),
            ),
          ],
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
          if (sections.any(
            (s) => s.refs.isNotEmpty || (s.first != null && s.last != null),
          ))
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
