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
import '../../../../shared/widgets/q_error_retry.dart';
import '../../domain/entities/hadith_search.dart';
import '../state/hadith_search_store.dart';
import 'hadith_section_screen.dart';

/// Searches the full text of every bundled hadith collection; a result
/// opens that hadith in its chapter.
final class HadithSearchScreen extends StatefulWidget {
  const HadithSearchScreen({super.key});

  @override
  State<HadithSearchScreen> createState() => _HadithSearchScreenState();
}

final class _HadithSearchScreenState extends State<HadithSearchScreen> {
  final HadithSearchStore _store = locator<HadithSearchStore>();
  final _controller = TextEditingController();
  var _warm = false;

  String get _lang => Localizations.localeOf(context).languageCode;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_warm) {
      _warm = true;
      _store.warmUp(_lang);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _store.dispose();
    super.dispose();
  }

  void _open(HadithSearchHit hit) {
    Haptics.selection();
    unawaited(
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => HadithSectionScreen(
            book: hit.book,
            section: hit.section,
            focusNumber: hit.number,
            languageCode: hit.languageCode,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final q = context.q;
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: true,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: l10n.hadithSearchFullHint,
            border: InputBorder.none,
          ),
          onChanged: (text) {
            _store.search(text, _lang);
            setState(() {}); // clear button visibility
          },
        ),
        actions: [
          if (_controller.text.isNotEmpty)
            IconButton(
              tooltip: l10n.clearSearch,
              icon: const Icon(Icons.close),
              onPressed: () {
                _controller.clear();
                _store.search('', _lang);
                setState(() {});
              },
            ),
        ],
      ),
      body: SafeArea(
        child: SignalBuilder(
          builder: (context) => switch (_store.state.value) {
            HadithSearchIdle() => _message(
              context,
              l10n.hadithSearchFullPrompt,
            ),
            HadithSearchLoading() => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  if (!_store.ready.value) ...[
                    const SizedBox(height: QSpace.s3),
                    Text(
                      l10n.hadithSearchFullPreparing,
                      style: QType.body.copyWith(color: q.ink2),
                    ),
                  ],
                ],
              ),
            ),
            HadithSearchFailed() => QErrorRetry(
              message: l10n.hadithSearchFullError,
              retryLabel: l10n.retry,
              onRetry: () => unawaited(_store.retry()),
            ),
            HadithSearchDone(:final results) when results.hits.isEmpty =>
              _message(context, l10n.hadithSearchFullNoResults),
            HadithSearchDone(results: (:final hits, :final truncated)) =>
              ListView.separated(
                padding: const EdgeInsetsDirectional.fromSTEB(
                  QSpace.s5,
                  QSpace.s3,
                  QSpace.s5,
                  QSpace.s5,
                ),
                itemCount: hits.length + (truncated ? 1 : 0),
                separatorBuilder: (_, _) => const SizedBox(height: QSpace.s3),
                itemBuilder: (context, i) {
                  if (i == hits.length) {
                    return Text(
                      LocaleDigits.localize(
                        l10n.hadithSearchFullShowingFirst(hits.length),
                        _lang,
                      ),
                      textAlign: TextAlign.center,
                      style: QType.caption.copyWith(color: q.ink3),
                    );
                  }
                  return _HitCard(hit: hits[i], onTap: () => _open(hits[i]));
                },
              ),
          },
        ),
      ),
    );
  }

  Widget _message(BuildContext context, String text) => Center(
    child: Padding(
      padding: const EdgeInsets.all(QSpace.s6),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: QType.body.copyWith(color: context.q.ink2),
      ),
    ),
  );
}

final class _HitCard extends StatelessWidget {
  const _HitCard({required this.hit, required this.onTap});

  final HadithSearchHit hit;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final q = context.q;
    final lang = Localizations.localeOf(context).languageCode;
    final body = QType.body.copyWith(color: q.ink);
    final s = hit.snippet;
    return QCard(
      onTap: onTap,
      padding: const EdgeInsets.all(QSpace.s4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${hit.book.titleFor(lang)} · '
            '${LocaleDigits.localize('${hit.number}', lang)}',
            style: QType.titleSm.copyWith(color: q.ink),
          ),
          const SizedBox(height: QSpace.s2),
          Text.rich(
            TextSpan(
              style: body,
              children: [
                TextSpan(text: s.substring(0, hit.matchStart)),
                TextSpan(
                  text: s.substring(hit.matchStart, hit.matchEnd),
                  style: body.copyWith(
                    fontWeight: FontWeight.w700,
                    backgroundColor: q.primarySoft,
                  ),
                ),
                TextSpan(text: s.substring(hit.matchEnd)),
              ],
            ),
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
