import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../../core/di/locator.dart';
import '../../../../core/theme/productive_muslim_tokens.dart';
import '../../../../core/theme/productive_muslim_typography.dart';
import '../../../../core/utils/locale_digits.dart';
import '../../../../shared/extensions/context_ext.dart';
import '../../../../shared/widgets/q_card.dart';
import '../../../muhasaba/presentation/widgets/tracker_visuals.dart';
import '../../domain/entities/hadith_book.dart';
import '../state/hadith_books_store.dart';
import 'hadith_sections_screen.dart';

/// List of the full hadith collections in the bundled catalog.
final class HadithBooksScreen extends StatefulWidget {
  const HadithBooksScreen({super.key});

  @override
  State<HadithBooksScreen> createState() => _HadithBooksScreenState();
}

final class _HadithBooksScreenState extends State<HadithBooksScreen> {
  late final HadithBooksStore _store = locator<HadithBooksStore>();

  @override
  void initState() {
    super.initState();
    if (!_store.loaded.value) {
      unawaited(_store.load());
    }
  }

  void _open(HadithBook book) {
    unawaited(HapticFeedback.selectionClick());
    unawaited(
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => HadithSectionsScreen(book: book),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final languageCode = Localizations.localeOf(context).languageCode;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.hadithBooksTitle)),
      body: SafeArea(
        child: SignalBuilder(
          builder: (context) {
            final books = _store.books.value;
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(
                QSpace.s5,
                QSpace.s3,
                QSpace.s5,
                QSpace.s5,
              ),
              itemCount: books.length + 1,
              separatorBuilder: (_, _) => const SizedBox(height: QSpace.s3),
              itemBuilder: (context, index) {
                if (index == books.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: QSpace.s2),
                    child: Text(
                      l10n.hadithSourceNote,
                      textAlign: TextAlign.center,
                      style: QType.caption.copyWith(color: context.q.ink3),
                    ),
                  );
                }
                final book = books[index];
                return _BookCard(
                  book: book,
                  languageCode: languageCode,
                  onTap: () => _open(book),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

final class _BookCard extends StatelessWidget {
  const _BookCard({
    required this.book,
    required this.languageCode,
    required this.onTap,
  });

  final HadithBook book;
  final String languageCode;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final q = context.q;
    final subtitle = book.isSahih
        ? l10n.hadithBookAllSahih
        : LocaleDigits.localize(
            l10n.hadithChapterCount(book.sectionsFor(languageCode).length),
            languageCode,
          );
    // Surface when a book has no Bengali translation in any source (Qudsi).
    final englishOnly = languageCode == 'bn' && !book.bnAvailable;
    return Semantics(
      button: true,
      label: book.titleFor(languageCode),
      child: GestureDetector(
        onTap: onTap,
        child: QCard(
          padding: const EdgeInsets.all(QSpace.s4),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: q.primarySoft,
                  borderRadius: BorderRadius.circular(QRadius.sm),
                ),
                child: Icon(
                  TrackerVisuals.iconOf('book'),
                  size: 22,
                  color: q.onPrimarySoft,
                ),
              ),
              const SizedBox(width: QSpace.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.titleFor(languageCode),
                      style: QType.titleSm.copyWith(color: q.ink),
                    ),
                    const SizedBox(height: 2),
                    if (book.authorFor(languageCode).isNotEmpty)
                      Text(
                        book.authorFor(languageCode),
                        style: QType.caption.copyWith(color: q.ink3),
                      ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: QType.caption.copyWith(
                        color: book.isSahih ? q.ok : q.ink2,
                      ),
                    ),
                    if (englishOnly) ...[
                      const SizedBox(height: 2),
                      Text(
                        l10n.hadithEnglishOnly,
                        style: QType.caption.copyWith(color: q.ink3),
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
  }
}
