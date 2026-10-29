import 'dart:async';

import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../../core/di/locator.dart';
import '../../../../core/theme/productive_muslim_tokens.dart';
import '../../../../core/theme/productive_muslim_typography.dart';
import '../../../../shared/extensions/context_ext.dart';
import '../../../../shared/widgets/q_card.dart';
import '../../../../shared/widgets/q_error_retry.dart';
import '../../../../shared/widgets/q_skeleton.dart';
import '../../../quran/presentation/widgets/reader_settings_sheet.dart';
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
            return ListView(
              padding: const EdgeInsets.fromLTRB(
                QSpace.s5,
                QSpace.s3,
                QSpace.s5,
                QSpace.s5,
              ),
              children: [
                QCard(
                  child: Text(
                    l10n.tibbNabawiNote,
                    style: QType.body.copyWith(color: q.ink2),
                  ),
                ),
                const SizedBox(height: QSpace.s3),
                if (_store.failed.value && items.isEmpty)
                  QErrorRetry(
                    message: l10n.ruqyahLoadError,
                    retryLabel: l10n.hadithRetry,
                    onRetry: () => unawaited(_store.load()),
                  )
                else if (!_store.loaded.value)
                  for (var i = 0; i < 3; i++) ...[
                    const QSkeleton(height: 160, radius: QRadius.lg),
                    const SizedBox(height: QSpace.s3),
                  ]
                else
                  for (final item in items) ...[
                    RuqyahCard(item: item),
                    const SizedBox(height: QSpace.s3),
                  ],
              ],
            );
          },
        ),
      ),
    );
  }
}
