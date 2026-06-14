import 'dart:async';

import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../../core/di/locator.dart';
import '../../../../core/theme/qalbee_tokens.dart';
import '../../../../core/theme/qalbee_typography.dart';
import '../../../../shared/extensions/context_ext.dart';
import '../../../../shared/widgets/q_card.dart';
import '../../domain/entities/hadith.dart';
import '../state/hadith_store.dart';

/// The full bundled hadith collection: a card per narration with Arabic,
/// translation, narrator and reference.
final class HadithScreen extends StatefulWidget {
  const HadithScreen({super.key});

  @override
  State<HadithScreen> createState() => _HadithScreenState();
}

final class _HadithScreenState extends State<HadithScreen> {
  // App-scoped store — never disposed here.
  late final HadithStore _store = locator<HadithStore>();

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
    return Scaffold(
      appBar: AppBar(title: Text(l10n.hadithTitle)),
      body: SafeArea(
        child: SignalBuilder(
          builder: (context) {
            final hadiths = _store.items.value;
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(
                QSpace.s5,
                QSpace.s3,
                QSpace.s5,
                QSpace.s5,
              ),
              itemCount: hadiths.length,
              separatorBuilder: (_, _) => const SizedBox(height: QSpace.s3),
              itemBuilder: (context, index) =>
                  _HadithCard(hadith: hadiths[index]),
            );
          },
        ),
      ),
    );
  }
}

final class _HadithCard extends StatelessWidget {
  const _HadithCard({required this.hadith});

  final Hadith hadith;

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
              style: QType.quran(24).copyWith(color: q.ink),
            ),
            const SizedBox(height: QSpace.s3),
          ],
          Text(
            hadith.translationFor(languageCode),
            style: QType.body.copyWith(color: q.ink),
          ),
          if (hadith.narrator.isNotEmpty) ...[
            const SizedBox(height: QSpace.s2),
            Text(
              l10n.hadithNarratedBy(hadith.narrator),
              style: QType.caption.copyWith(color: q.ink3),
            ),
          ],
          if (hadith.reference.isNotEmpty) ...[
            const SizedBox(height: QSpace.s1),
            Text(
              hadith.reference,
              style: QType.caption.copyWith(color: q.ink3),
            ),
          ],
        ],
      ),
    );
  }
}
