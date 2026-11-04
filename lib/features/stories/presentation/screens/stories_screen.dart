import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../../core/di/locator.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/productive_muslim_tokens.dart';
import '../../../../shared/extensions/context_ext.dart';
import '../../../../shared/widgets/q_empty_state.dart';
import '../../../../shared/widgets/q_error_retry.dart';
import '../../../../shared/widgets/q_list_row.dart';
import '../../../../shared/widgets/q_skeleton.dart';
import '../../domain/entities/story.dart';
import '../state/stories_store.dart';

/// Quran and hadith stories in two tabs; [initialKind] picks the open tab.
final class StoriesScreen extends StatefulWidget {
  const StoriesScreen({this.initialKind = StoryKind.quran, super.key});

  final StoryKind initialKind;

  @override
  State<StoriesScreen> createState() => _StoriesScreenState();
}

final class _StoriesScreenState extends State<StoriesScreen> {
  late final StoriesStore _store = locator<StoriesStore>();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return DefaultTabController(
      length: StoryKind.values.length,
      initialIndex: StoryKind.values.indexOf(widget.initialKind),
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.storiesTitle),
          bottom: TabBar(
            tabs: [
              for (final kind in StoryKind.values)
                Tab(
                  text: switch (kind) {
                    StoryKind.quran => l10n.storiesTabQuran,
                    StoryKind.hadith => l10n.storiesTabHadith,
                  },
                ),
            ],
          ),
        ),
        body: SafeArea(
          child: TabBarView(
            children: [
              for (final kind in StoryKind.values)
                _StoryList(store: _store, kind: kind),
            ],
          ),
        ),
      ),
    );
  }
}

final class _StoryList extends StatefulWidget {
  const _StoryList({required this.store, required this.kind});

  final StoriesStore store;
  final StoryKind kind;

  @override
  State<_StoryList> createState() => _StoryListState();
}

final class _StoryListState extends State<_StoryList> {
  @override
  void initState() {
    super.initState();
    unawaited(widget.store.load(widget.kind));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final languageCode = Localizations.localeOf(context).languageCode;
    return SignalBuilder(
      builder: (context) {
        final stories = widget.store.stories.value[widget.kind];
        if (stories == null) {
          return widget.store.failed.value.contains(widget.kind)
              ? QErrorRetry(
                  message: l10n.storiesLoadError,
                  retryLabel: l10n.retry,
                  onRetry: () => unawaited(widget.store.load(widget.kind)),
                )
              : const QSkeletonList(height: 56);
        }
        if (stories.isEmpty) {
          return QEmptyState(
            icon: Icons.menu_book_outlined,
            body: l10n.storiesEmpty,
          );
        }
        return ListView.builder(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: QSpace.s3,
            vertical: QSpace.s3,
          ),
          itemCount: stories.length,
          itemBuilder: (context, index) {
            final story = stories[index];
            return QListRow(
              key: ValueKey(story.id),
              title: story.titleFor(languageCode),
              onTap: () => context.pushNamed(
                Routes.story.name,
                pathParameters: {'kind': widget.kind.name, 'id': story.id},
              ),
            );
          },
        );
      },
    );
  }
}
