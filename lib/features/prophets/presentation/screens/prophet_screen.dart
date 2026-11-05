import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../../config/assets.dart';
import '../../../../core/di/locator.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/productive_muslim_tokens.dart';
import '../../../../core/theme/productive_muslim_typography.dart';
import '../../../../shared/extensions/context_ext.dart';
import '../../../../shared/widgets/q_chip.dart';
import '../../../../shared/widgets/q_error_retry.dart';
import '../../../../shared/widgets/q_list_row.dart';
import '../../../../shared/widgets/q_section_header.dart';
import '../../../../shared/widgets/q_skeleton.dart';
import '../../../stories/domain/entities/story.dart';
import '../../domain/entities/prophet.dart';
import '../state/prophets_store.dart';

/// One prophet by id (deep-linkable): names, title, summary, Quran mentions
/// (each opens the reader at that ayah), its Quran stories and hadith
/// references.
final class ProphetScreen extends StatefulWidget {
  const ProphetScreen({required this.id, super.key});

  final String id;

  @override
  State<ProphetScreen> createState() => _ProphetScreenState();
}

final class _ProphetScreenState extends State<ProphetScreen> {
  // App-scoped store — never disposed here.
  late final ProphetsStore _store = locator<ProphetsStore>();

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
    final languageCode = Localizations.localeOf(context).languageCode;
    return SignalBuilder(
      builder: (context) {
        final prophet = _store.prophets.value
            .where((p) => p.id == widget.id)
            .firstOrNull;
        return Scaffold(
          appBar: AppBar(
            title: Text(prophet?.nameFor(languageCode) ?? l10n.prophetsTitle),
          ),
          body: SafeArea(
            child: switch ((prophet, _store.loaded.value)) {
              (final p?, _) => _Details(
                prophet: p,
                stories: [
                  for (final id in p.storyIds) ?_store.quranStories.value[id],
                ],
              ),
              (null, false) => const QSkeletonList(),
              (null, true) when _store.failed.value => QErrorRetry(
                message: l10n.prophetsLoadError,
                retryLabel: l10n.retry,
                onRetry: () => unawaited(_store.load()),
              ),
              (null, true) => Center(child: Text(l10n.routeNotFound)),
            },
          ),
        );
      },
    );
  }
}

final class _Details extends StatelessWidget {
  const _Details({required this.prophet, required this.stories});

  final Prophet prophet;

  /// The prophet's `storyIds` that resolved to a loaded story.
  final List<Story> stories;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final q = context.q;
    final languageCode = Localizations.localeOf(context).languageCode;
    final title = prophet.titleFor(languageCode);
    final summary = prophet.summaryFor(languageCode);
    return ListView(
      padding: const EdgeInsets.all(QSpace.s5),
      children: [
        Text(
          prophet.nameAr,
          textAlign: TextAlign.center,
          textDirection: TextDirection.rtl,
          style: QType.headline.copyWith(
            fontFamily: AppFonts.arabicUi,
            color: q.primary,
          ),
        ),
        Text(
          prophet.nameFor(languageCode),
          textAlign: TextAlign.center,
          style: QType.title.copyWith(color: q.ink),
        ),
        if (title.isNotEmpty)
          Text(
            title,
            textAlign: TextAlign.center,
            style: QType.body.copyWith(color: q.ink2),
          ),
        const SizedBox(height: QSpace.s4),
        if (summary.isEmpty)
          Text(
            l10n.prophetSummaryComingSoon,
            style: QType.body.copyWith(color: q.ink3),
          )
        else
          for (final paragraph in summary)
            Padding(
              padding: const EdgeInsetsDirectional.only(bottom: QSpace.s3),
              child: Text(paragraph, style: QType.body.copyWith(color: q.ink)),
            ),
        if (prophet.quranMentions.isNotEmpty) ...[
          QSectionHeader(l10n.prophetQuranMentions),
          Wrap(
            spacing: QSpace.s2,
            children: [
              for (final mention in prophet.quranMentions)
                QChip(
                  label: context.digits(mention),
                  icon: Icons.menu_book_outlined,
                  onTap: _ayahOf(mention) == null
                      ? null
                      : () => unawaited(
                          context.pushNamed(
                            Routes.quranAyah.name,
                            pathParameters: _ayahOf(mention)!,
                          ),
                        ),
                ),
            ],
          ),
        ],
        if (stories.isNotEmpty) ...[
          QSectionHeader(l10n.storiesTitle),
          for (final story in stories)
            QListRow(
              key: ValueKey(story.id),
              title: story.titleFor(languageCode),
              onTap: () => unawaited(
                context.pushNamed(
                  Routes.story.name,
                  pathParameters: {
                    'kind': StoryKind.quran.name,
                    'id': story.id,
                  },
                ),
              ),
            ),
        ],
        if (prophet.hadithRefs.isNotEmpty) ...[
          QSectionHeader(l10n.prophetHadithRefs),
          for (final ref in prophet.hadithRefs)
            Text(
              context.digits(ref),
              style: QType.body.copyWith(color: q.ink2),
            ),
        ],
      ],
    );
  }

  /// `"14:35-41"` → `{surah: 14, ayah: 35}`; null when malformed.
  static Map<String, String>? _ayahOf(String mention) =>
      switch (RegExp(r'^(\d+):(\d+)').firstMatch(mention)) {
        final m? => {'surah': m[1]!, 'ayah': m[2]!},
        null => null,
      };
}
