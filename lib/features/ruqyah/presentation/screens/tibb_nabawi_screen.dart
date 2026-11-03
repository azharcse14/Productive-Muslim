import 'dart:async';

import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../../core/di/locator.dart';
import '../../../../core/theme/productive_muslim_tokens.dart';
import '../../../../core/theme/productive_muslim_typography.dart';
import '../../../../shared/extensions/context_ext.dart';
import '../../../../shared/reader/reader_settings_sheet.dart';
import '../../../../shared/widgets/q_card.dart';
import '../../../../shared/widgets/q_error_retry.dart';
import '../../../../shared/widgets/q_skeleton.dart';
import '../state/ruqyah_store.dart';
import '../widgets/ruqyah_card.dart';

/// Tibb an-Nabawi: authentic narrations on prophetic remedies (honey, black
/// seed, hijama…). Same card/schema as ruqyah, loaded from its own asset.
final class TibbNabawiScreen extends StatefulWidget {
  const TibbNabawiScreen({super.key});

  @override
  State<TibbNabawiScreen> createState() => _TibbNabawiScreenState();
}

final class _TibbNabawiScreenState extends State<TibbNabawiScreen> {
  // App-scoped store — never disposed here.
  late final RuqyahStore _store = locator<RuqyahStore>(
    instanceName: RuqyahStore.tibbNabawi,
  );

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
    final q = context.q;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.tibbNabawiTitle),
        actions: const [ReaderSettingsAction()],
      ),
      body: SafeArea(
        child: SignalBuilder(
          builder: (context) {
            final items = [for (final c in _store.categories.value) ...c.items];
            final failed = _store.failed.value && items.isEmpty;
            final loading = !failed && !_store.loaded.value;
            // Lazy: the note, then one row per card (or the retry / three
            // skeletons) — only the rows on screen are built.
            final rows = failed ? 1 : (loading ? 3 : items.length);
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(
                QSpace.s5,
                QSpace.s3,
                QSpace.s5,
                QSpace.s5,
              ),
              itemCount: rows + 1,
              separatorBuilder: (_, _) => const SizedBox(height: QSpace.s3),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return QCard(
                    child: Text(
                      l10n.tibbNabawiNote,
                      style: QType.body.copyWith(color: q.ink2),
                    ),
                  );
                }
                if (failed) {
                  return QErrorRetry(
                    message: l10n.ruqyahLoadError,
                    retryLabel: l10n.retry,
                    onRetry: () => unawaited(_store.load()),
                  );
                }
                if (loading) {
                  return const QSkeleton(height: 160, radius: QRadius.lg);
                }
                final item = items[index - 1];
                return RuqyahCard(key: ValueKey(item.id), item: item);
              },
            );
          },
        ),
      ),
    );
  }
}
