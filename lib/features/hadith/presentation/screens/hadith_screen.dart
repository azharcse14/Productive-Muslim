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
import '../../../../shared/widgets/q_search_delegate.dart';
import '../../../../shared/widgets/q_skeleton.dart';
import '../../../muhasaba/presentation/widgets/tracker_visuals.dart';
import '../../domain/entities/hadith.dart';
import '../state/hadith_store.dart';
import '../widgets/hadith_list_card.dart';
import 'hadith_books_screen.dart';
import 'hadith_topic_screen.dart';

/// Hadith landing: a "full collections" entry on top, then the bundled
/// topic-wise grid of authentic narrations.
final class HadithScreen extends StatefulWidget {
  const HadithScreen({super.key});

  @override
  State<HadithScreen> createState() => _HadithScreenState();
}

/// Topic id → curated icon key (see [TrackerVisuals.icons]).
const _topicIcons = <String, String>{
  'intention': 'spark',
  'faith': 'heart',
  'character': 'star',
  'speech': 'speech',
  'knowledge': 'book',
  'charity': 'hands',
  'mercy': 'people',
  'worship': 'mosque',
  'dunya': 'globe',
};

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

  void _push(Widget screen) {
    Haptics.selection();
    unawaited(
      Navigator.of(
        context,
      ).push(MaterialPageRoute<void>(builder: (_) => screen)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final languageCode = Localizations.localeOf(context).languageCode;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.hadithTitle),
        actions: [
          // Disabled until loaded: the delegate snapshots the list.
          SignalBuilder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.search),
              tooltip: l10n.hadithSearchHint,
              onPressed: !_store.loaded.value
                  ? null
                  : () => unawaited(
                      showSearch<void>(
                        context: context,
                        delegate: QSearchDelegate<Hadith>(
                          items: _store.items.value,
                          fields: (h) => [
                            h.arabic,
                            h.en,
                            h.bn,
                            h.narrator,
                            h.reference,
                          ],
                          itemBuilder: (_, h) => HadithListCard(hadith: h),
                          emptyText: l10n.hadithNoResults,
                          hint: l10n.hadithSearchHint,
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SignalBuilder(
          builder: (context) {
            final topics = _store.topics.value;
            return ListView(
              padding: const EdgeInsets.fromLTRB(
                QSpace.s5,
                QSpace.s3,
                QSpace.s5,
                QSpace.s5,
              ),
              children: [
                _FullCollectionsCard(
                  onTap: () => _push(const HadithBooksScreen()),
                ),
                const SizedBox(height: QSpace.s4),
                if (_store.failed.value && topics.isEmpty)
                  QErrorRetry(
                    message: l10n.hadithTopicsLoadError,
                    retryLabel: l10n.hadithRetry,
                    onRetry: () => unawaited(_store.load()),
                  )
                else
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: QSpace.s3,
                    crossAxisSpacing: QSpace.s3,
                    childAspectRatio: 1.2 / context.textGrowth,
                    children: [
                      if (!_store.loaded.value)
                        for (var i = 0; i < 6; i++)
                          const QSkeleton(height: 120, radius: QRadius.lg),
                      for (final topic in topics)
                        _TopicCard(
                          topic: topic,
                          languageCode: languageCode,
                          onTap: () => _push(HadithTopicScreen(topic: topic)),
                        ),
                    ],
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

final class _FullCollectionsCard extends StatelessWidget {
  const _FullCollectionsCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final q = context.q;
    return Semantics(
      button: true,
      label: l10n.hadithBooksTitle,
      child: QCard(
        onTap: onTap,
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
                TrackerVisuals.iconOf('library'),
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
                    l10n.hadithBooksTitle,
                    style: QType.titleSm.copyWith(color: q.ink),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n.hadithBooksSubtitle,
                    style: QType.caption.copyWith(color: q.ink2),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: q.ink3),
          ],
        ),
      ),
    );
  }
}

final class _TopicCard extends StatelessWidget {
  const _TopicCard({
    required this.topic,
    required this.languageCode,
    required this.onTap,
  });

  final HadithTopic topic;
  final String languageCode;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final q = context.q;
    return Semantics(
      button: true,
      child: QCard(
        onTap: onTap,
        padding: const EdgeInsets.all(QSpace.s4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: q.primarySoft,
                borderRadius: BorderRadius.circular(QRadius.sm),
              ),
              child: Icon(
                TrackerVisuals.iconOf(_topicIcons[topic.id] ?? 'spark'),
                size: 19,
                color: q.onPrimarySoft,
              ),
            ),
            const Spacer(),
            Text(
              l10n.hadithTopicName(topic.id),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: QType.titleSm.copyWith(color: q.ink),
            ),
            const SizedBox(height: 2),
            Text(
              LocaleDigits.localize(
                l10n.hadithCount(topic.items.length),
                languageCode,
              ),
              style: QType.caption.copyWith(color: q.ink2),
            ),
          ],
        ),
      ),
    );
  }
}
