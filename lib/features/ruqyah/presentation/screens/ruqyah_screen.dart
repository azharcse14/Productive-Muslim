import 'dart:async';

import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../../core/di/locator.dart';
import '../../../../core/theme/productive_muslim_tokens.dart';
import '../../../../core/theme/productive_muslim_typography.dart';
import '../../../../core/utils/haptics.dart';
import '../../../../shared/extensions/context_ext.dart';
import '../../../../shared/widgets/q_card.dart';
import '../../../../shared/widgets/q_category_tile.dart';
import '../../../../shared/widgets/q_error_retry.dart';
import '../../../../shared/widgets/q_search_delegate.dart';
import '../../../../shared/widgets/q_skeleton.dart';
import '../../../muhasaba/presentation/widgets/tracker_visuals.dart';
import '../../domain/entities/ruqyah.dart';
import '../state/ruqyah_store.dart';
import '../widgets/ruqyah_card.dart';
import 'ruqyah_category_screen.dart';

/// Ruqyah landing: a short "how to" guidance card, then the category grid
/// of authentic Qur'anic verses and prophetic supplications.
final class RuqyahScreen extends StatefulWidget {
  const RuqyahScreen({super.key});

  @override
  State<RuqyahScreen> createState() => _RuqyahScreenState();
}

final class _RuqyahScreenState extends State<RuqyahScreen> {
  // App-scoped store — never disposed here.
  late final RuqyahStore _store = locator<RuqyahStore>();

  @override
  void initState() {
    super.initState();
    if (!_store.loaded.value) {
      unawaited(_store.load());
    }
  }

  void _open(Widget screen) {
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
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.ruqyahTitle),
        actions: [
          // Disabled until loaded: the delegate snapshots the list.
          SignalBuilder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.search),
              tooltip: l10n.ruqyahSearchHint,
              onPressed: !_store.loaded.value
                  ? null
                  : () => unawaited(
                      showSearch<void>(
                        context: context,
                        delegate: QSearchDelegate<RuqyahItem>(
                          items: [
                            for (final c in _store.categories.value) ...c.items,
                          ],
                          fields: (r) => [
                            r.arabic,
                            r.titleEn,
                            r.titleBn,
                            r.transliteration,
                            r.translationEn,
                            r.translationBn,
                            r.reference,
                          ],
                          itemBuilder: (_, r) => RuqyahCard(item: r),
                          emptyText: l10n.ruqyahNoResults,
                          hint: l10n.ruqyahSearchHint,
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
            final categories = _store.categories.value;
            return ListView(
              padding: const EdgeInsets.fromLTRB(
                QSpace.s5,
                QSpace.s3,
                QSpace.s5,
                QSpace.s5,
              ),
              children: [
                const _GuidanceCard(),
                const SizedBox(height: QSpace.s4),
                if (_store.failed.value && categories.isEmpty)
                  QErrorRetry(
                    message: l10n.ruqyahLoadError,
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
                      for (final category in categories)
                        QCategoryTile(
                          icon: TrackerVisuals.iconOf(category.icon),
                          title: l10n.ruqyahCategoryName(category.id),
                          subtitle: context.digits(
                            l10n.ruqyahCount(category.items.length),
                          ),
                          onTap: () =>
                              _open(RuqyahCategoryScreen(category: category)),
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

final class _GuidanceCard extends StatelessWidget {
  const _GuidanceCard();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final q = context.q;
    return QCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.healing_outlined, size: 20, color: q.primary),
              const SizedBox(width: QSpace.s2),
              Expanded(
                child: Text(
                  l10n.ruqyahHowToTitle,
                  style: QType.titleSm.copyWith(color: q.ink),
                ),
              ),
            ],
          ),
          const SizedBox(height: QSpace.s2),
          Text(l10n.ruqyahHowToBody, style: QType.body.copyWith(color: q.ink2)),
        ],
      ),
    );
  }
}
