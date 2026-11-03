import 'dart:async';

import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../../core/di/locator.dart';
import '../../../../core/theme/productive_muslim_tokens.dart';
import '../../../../shared/extensions/context_ext.dart';
import '../../../../shared/reader/reader_settings_sheet.dart';
import '../../../../shared/widgets/q_error_retry.dart';
import '../../../../shared/widgets/q_skeleton.dart';
import '../state/ruqyah_store.dart';
import '../widgets/ruqyah_card.dart';

/// One ruqyah category, by id (deep-linkable): full cards with title,
/// Arabic, transliteration, translation, reference and (when prescribed)
/// the recitation count.
final class RuqyahCategoryScreen extends StatefulWidget {
  const RuqyahCategoryScreen({required this.id, super.key});

  final String id;

  @override
  State<RuqyahCategoryScreen> createState() => _RuqyahCategoryScreenState();
}

final class _RuqyahCategoryScreenState extends State<RuqyahCategoryScreen> {
  // App-scoped store — never disposed here.
  late final RuqyahStore _store = locator<RuqyahStore>();

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
        final category = _store.categories.value
            .where((c) => c.id == widget.id)
            .firstOrNull;
        return Scaffold(
          appBar: AppBar(
            title: Text(
              category == null
                  ? l10n.ruqyahTitle
                  : l10n.ruqyahCategoryName(category.id),
            ),
            actions: const [ReaderSettingsAction()],
          ),
          body: SafeArea(
            child: switch ((category, _store.loaded.value)) {
              (final c?, _) => ListView.separated(
                padding: const EdgeInsets.fromLTRB(
                  QSpace.s5,
                  QSpace.s3,
                  QSpace.s5,
                  QSpace.s5,
                ),
                itemCount: c.items.length,
                separatorBuilder: (_, _) => const SizedBox(height: QSpace.s3),
                itemBuilder: (context, index) => RuqyahCard(
                  key: ValueKey(c.items[index].id),
                  item: c.items[index],
                ),
              ),
              (null, false) => const QSkeletonList(),
              (null, true) when _store.failed.value => QErrorRetry(
                message: l10n.ruqyahLoadError,
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
