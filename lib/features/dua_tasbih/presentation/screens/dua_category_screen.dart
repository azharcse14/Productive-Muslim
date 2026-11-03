import 'dart:async';

import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../../core/di/locator.dart';
import '../../../../core/theme/productive_muslim_tokens.dart';
import '../../../../shared/extensions/context_ext.dart';
import '../../../../shared/reader/reader_settings_sheet.dart';
import '../../../../shared/widgets/q_error_retry.dart';
import '../../../../shared/widgets/q_skeleton.dart';
import '../state/dua_store.dart';
import '../widgets/dua_card.dart';

/// One dua category, by id (deep-linkable): full cards with Arabic,
/// transliteration, translation, reference and (when authentic) the
/// repetition count.
final class DuaCategoryScreen extends StatefulWidget {
  const DuaCategoryScreen({required this.id, super.key});

  final String id;

  @override
  State<DuaCategoryScreen> createState() => _DuaCategoryScreenState();
}

final class _DuaCategoryScreenState extends State<DuaCategoryScreen> {
  // App-scoped store — never disposed here.
  late final DuaStore _store = locator<DuaStore>();

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
                  ? l10n.duaTitle
                  : l10n.duaCategoryName(category.id),
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
                itemCount: c.duas.length,
                separatorBuilder: (_, _) => const SizedBox(height: QSpace.s3),
                itemBuilder: (context, index) => DuaCard(
                  key: ValueKey(c.duas[index].id),
                  dua: c.duas[index],
                ),
              ),
              (null, false) => const QSkeletonList(),
              (null, true) when _store.failed.value => QErrorRetry(
                message: l10n.duaLoadError,
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
