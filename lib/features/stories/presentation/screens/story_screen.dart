import 'dart:async';

import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../../core/di/locator.dart';
import '../../../../core/theme/productive_muslim_tokens.dart';
import '../../../../core/theme/productive_muslim_typography.dart';
import '../../../../shared/extensions/context_ext.dart';
import '../../../../shared/widgets/q_chip.dart';
import '../../../../shared/widgets/q_error_retry.dart';
import '../../../../shared/widgets/q_section_header.dart';
import '../../../../shared/widgets/q_skeleton.dart';
import '../../domain/entities/story.dart';
import '../state/stories_store.dart';

/// One story by kind and id (deep-linkable, e.g. from a prophet's page):
/// title, paragraphs and its Quran/hadith references. A null [kind] (an
/// unknown `:kind` in the path) shows "not available".
final class StoryScreen extends StatefulWidget {
  const StoryScreen({required this.kind, required this.id, super.key});

  final StoryKind? kind;
  final String id;

  @override
  State<StoryScreen> createState() => _StoryScreenState();
}

final class _StoryScreenState extends State<StoryScreen> {
  late final StoriesStore _store = locator<StoriesStore>();

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    if (widget.kind case final kind?) {
      unawaited(_store.load(kind));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final languageCode = Localizations.localeOf(context).languageCode;
    return SignalBuilder(
      builder: (context) {
        final kind = widget.kind;
        final stories = kind == null
            ? const <Story>[]
            : _store.stories.value[kind];
        final story = stories?.where((s) => s.id == widget.id).firstOrNull;
        final failed = kind != null && _store.failed.value.contains(kind);
        return Scaffold(
          appBar: AppBar(
            title: Text(story?.titleFor(languageCode) ?? l10n.storiesTitle),
          ),
          body: SafeArea(
            child: switch ((story, stories)) {
              (final s?, _) => _StoryBody(story: s, languageCode: languageCode),
              (null, null) when failed => QErrorRetry(
                message: l10n.storiesLoadError,
                retryLabel: l10n.retry,
                onRetry: _load,
              ),
              (null, null) => const QSkeletonList(),
              (null, _) => Center(child: Text(l10n.routeNotFound)),
            },
          ),
        );
      },
    );
  }
}

final class _StoryBody extends StatelessWidget {
  const _StoryBody({required this.story, required this.languageCode});

  final Story story;
  final String languageCode;

  @override
  Widget build(BuildContext context) {
    final q = context.q;
    return ListView(
      padding: const EdgeInsetsDirectional.fromSTEB(
        QSpace.s5,
        QSpace.s3,
        QSpace.s5,
        QSpace.s5,
      ),
      children: [
        Text(story.titleFor(languageCode), style: QType.headline),
        for (final paragraph in story.bodyFor(languageCode))
          Padding(
            padding: const EdgeInsetsDirectional.only(top: QSpace.s3),
            child: Text(paragraph, style: QType.body.copyWith(color: q.ink)),
          ),
        if (story.refs.isNotEmpty) ...[
          QSectionHeader(context.l10n.storyReferences),
          Wrap(
            spacing: QSpace.s2,
            runSpacing: QSpace.s2,
            children: [for (final ref in story.refs) QChip(label: ref)],
          ),
        ],
      ],
    );
  }
}
