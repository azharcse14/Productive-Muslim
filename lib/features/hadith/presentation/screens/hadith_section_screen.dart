import 'dart:async';

import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../../core/di/locator.dart';
import '../../../../core/theme/qalbee_tokens.dart';
import '../../../../core/theme/qalbee_typography.dart';
import '../../../../shared/extensions/context_ext.dart';
import '../../../../shared/widgets/q_card.dart';
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
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Locale is read here (not initState) — inherited widgets aren't yet
    // available during initState. Guarded so it runs only once.
    if (!_started) {
      _started = true;
      unawaited(_load());
    }
  }

  Future<void> _load() => _store.load(
        widget.book,
        widget.section,
        Localizations.localeOf(context).languageCode,
      );

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
              return const Center(child: CircularProgressIndicator());
            }
            if (_store.failed.value) {
              return _ErrorRetry(
                message: l10n.hadithLoadError,
                retryLabel: l10n.hadithRetry,
                onRetry: () => unawaited(_load()),
              );
            }
            final items = _store.items.value;
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(
                QSpace.s5,
                QSpace.s3,
                QSpace.s5,
                QSpace.s5,
              ),
              itemCount: items.length + 1,
              separatorBuilder: (_, _) => const SizedBox(height: QSpace.s3),
              itemBuilder: (context, index) {
                if (index == items.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: QSpace.s2),
                    child: Text(
                      l10n.hadithSourceNote,
                      textAlign: TextAlign.center,
                      style: QType.caption.copyWith(color: context.q.ink3),
                    ),
                  );
                }
                return _BookHadithCard(hadith: items[index]);
              },
            );
          },
        ),
      ),
    );
  }
}

final class _BookHadithCard extends StatelessWidget {
  const _BookHadithCard({required this.hadith});

  final BookHadith hadith;

  @override
  Widget build(BuildContext context) {
    final q = context.q;
    return QCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (hadith.arabic.isNotEmpty) ...[
            Text(
              hadith.arabic,
              textDirection: TextDirection.rtl,
              style: QType.quran(24).copyWith(color: q.ink),
            ),
            const SizedBox(height: QSpace.s3),
          ],
          if (hadith.translation.isNotEmpty)
            Text(
              hadith.translation,
              style: QType.body.copyWith(color: q.ink),
            ),
          const SizedBox(height: QSpace.s2),
          Row(
            children: [
              if (hadith.grade.isNotEmpty) ...[
                GradeChip(grade: hadith.grade),
                const SizedBox(width: QSpace.s2),
              ],
              Expanded(
                child: Text(
                  hadith.reference,
                  textAlign: TextAlign.end,
                  style: QType.caption.copyWith(color: q.ink3),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

final class _ErrorRetry extends StatelessWidget {
  const _ErrorRetry({
    required this.message,
    required this.retryLabel,
    required this.onRetry,
  });

  final String message;
  final String retryLabel;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final q = context.q;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(QSpace.s6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_outlined, size: 40, color: q.ink3),
            const SizedBox(height: QSpace.s3),
            Text(
              message,
              textAlign: TextAlign.center,
              style: QType.body.copyWith(color: q.ink2),
            ),
            const SizedBox(height: QSpace.s4),
            FilledButton(onPressed: onRetry, child: Text(retryLabel)),
          ],
        ),
      ),
    );
  }
}
