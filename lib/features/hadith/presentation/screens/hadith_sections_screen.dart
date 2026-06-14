import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/qalbee_tokens.dart';
import '../../../../core/theme/qalbee_typography.dart';
import '../../../../core/utils/locale_digits.dart';
import '../../../../shared/extensions/context_ext.dart';
import '../../../../shared/widgets/q_card.dart';
import '../../domain/entities/hadith_book.dart';
import 'hadith_section_screen.dart';

/// The chapters/sections of one [HadithBook].
final class HadithSectionsScreen extends StatelessWidget {
  const HadithSectionsScreen({required this.book, super.key});

  final HadithBook book;

  void _open(BuildContext context, HadithSection section) {
    unawaited(HapticFeedback.selectionClick());
    unawaited(
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => HadithSectionScreen(book: book, section: section),
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
      appBar: AppBar(title: Text(book.titleFor(languageCode))),
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
              child: GestureDetector(
                onTap: () => _open(context, section),
                child: QCard(
                  padding: const EdgeInsets.all(QSpace.s4),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 28,
                        child: Text(
                          LocaleDigits.localize('${index + 1}', languageCode),
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
                                style:
                                    QType.caption.copyWith(color: q.ink2),
                              ),
                            ],
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right, color: q.ink3),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
