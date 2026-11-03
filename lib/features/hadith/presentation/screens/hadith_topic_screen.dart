import 'dart:async';

import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../../core/di/locator.dart';
import '../../../../core/theme/productive_muslim_tokens.dart';
import '../../../../shared/extensions/context_ext.dart';
import '../../../../shared/reader/reader_settings_sheet.dart';
import '../../../../shared/widgets/q_error_retry.dart';
import '../../../../shared/widgets/q_skeleton.dart';
import '../state/hadith_store.dart';
import '../widgets/hadith_list_card.dart';

/// The bundled hadith for one topic, by id (deep-linkable).
final class HadithTopicScreen extends StatefulWidget {
  const HadithTopicScreen({required this.id, super.key});

  final String id;

  @override
  State<HadithTopicScreen> createState() => _HadithTopicScreenState();
}

final class _HadithTopicScreenState extends State<HadithTopicScreen> {
  // App-scoped store — owns the favorites.
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
    return SignalBuilder(
      builder: (context) {
        final topic = _store.topics.value
            .where((t) => t.id == widget.id)
            .firstOrNull;
        return Scaffold(
          appBar: AppBar(
            title: Text(
              topic == null ? l10n.hadithTitle : l10n.hadithTopicName(topic.id),
            ),
            actions: const [ReaderSettingsAction()],
          ),
          body: SafeArea(
            child: switch ((topic, _store.loaded.value)) {
              (final t?, _) => ListView.separated(
                padding: const EdgeInsets.fromLTRB(
                  QSpace.s5,
                  QSpace.s3,
                  QSpace.s5,
                  QSpace.s5,
                ),
                itemCount: t.items.length,
                separatorBuilder: (_, _) => const SizedBox(height: QSpace.s3),
                itemBuilder: (context, index) =>
                    HadithListCard(hadith: t.items[index], store: _store),
              ),
              (null, false) => const QSkeletonList(),
              (null, true) when _store.failed.value => QErrorRetry(
                message: l10n.hadithTopicsLoadError,
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
