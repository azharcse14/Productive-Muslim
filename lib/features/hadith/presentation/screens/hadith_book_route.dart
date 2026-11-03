import 'dart:async';

import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../../core/di/locator.dart';
import '../../../../shared/extensions/context_ext.dart';
import '../../../../shared/widgets/q_error_retry.dart';
import '../../../../shared/widgets/q_skeleton.dart';
import '../state/hadith_books_store.dart';
import 'hadith_section_screen.dart';
import 'hadith_sections_screen.dart';

/// Deep-link entry for the full collections: resolves [bookId] (and
/// chapter [section] of the [languageCode] chapter list, when given)
/// against the catalog, then shows that book's chapters or the chapter.
final class HadithBookRoute extends StatefulWidget {
  const HadithBookRoute({
    required this.bookId,
    this.section,
    this.languageCode,
    this.focusNumber,
    super.key,
  });

  final String bookId;

  /// Chapter number; null shows the book's chapter list.
  final int? section;

  /// Language whose chapter list [section] belongs to; defaults to the
  /// app locale's (see [HadithSectionScreen.languageCode]).
  final String? languageCode;

  /// Show only this hadith (see [HadithSectionScreen.focusNumber]).
  final int? focusNumber;

  @override
  State<HadithBookRoute> createState() => _HadithBookRouteState();
}

final class _HadithBookRouteState extends State<HadithBookRoute> {
  late final HadithBooksStore _store = locator<HadithBooksStore>();

  @override
  void initState() {
    super.initState();
    if (!_store.loaded.value) {
      unawaited(_store.load());
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SignalBuilder(
      builder: (context) {
        if (!_store.loaded.value) {
          return Scaffold(appBar: AppBar(), body: const QSkeletonList());
        }
        final book = _store.books.value
            .where((b) => b.id == widget.bookId)
            .firstOrNull;
        final number = widget.section;
        if (book != null && number == null) {
          return HadithSectionsScreen(book: book);
        }
        final language =
            widget.languageCode ?? Localizations.localeOf(context).languageCode;
        final section = book
            ?.sectionsFor(language)
            .where((s) => s.number == number)
            .firstOrNull;
        if (book != null && section != null) {
          return HadithSectionScreen(
            book: book,
            section: section,
            focusNumber: widget.focusNumber,
            languageCode: widget.languageCode,
          );
        }
        return Scaffold(
          appBar: AppBar(title: Text(l10n.hadithBooksTitle)),
          body: SafeArea(
            child: _store.failed.value && _store.books.value.isEmpty
                ? QErrorRetry(
                    message: l10n.hadithLoadError,
                    retryLabel: l10n.retry,
                    onRetry: () => unawaited(_store.load()),
                  )
                : Center(child: Text(l10n.routeNotFound)),
          ),
        );
      },
    );
  }
}
