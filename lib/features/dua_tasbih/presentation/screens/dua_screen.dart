import 'dart:async';

import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../../core/di/locator.dart';
import '../../../../core/theme/productive_muslim_tokens.dart';
import '../../../../core/theme/productive_muslim_typography.dart';
import '../../../../core/utils/haptics.dart';
import '../../../../core/utils/locale_digits.dart';
import '../../../../shared/extensions/context_ext.dart';
import '../../../../shared/painters/qalb_mark.dart';
import '../../../../shared/widgets/q_card.dart';
import '../../../../shared/widgets/q_search_delegate.dart';
import '../../../../shared/widgets/staggered_entrance.dart';
import '../../../muhasaba/presentation/widgets/tracker_visuals.dart';
import '../../domain/entities/dua.dart';
import '../state/dua_favorites_store.dart';
import '../state/dua_store.dart';
import '../widgets/dua_card.dart';
import 'asmaul_husna_screen.dart';
import 'dua_category_screen.dart';
import 'tasbih_screen.dart';

/// Dua & Tasbih landing (design §4.8): tasbih + Asmaul Husna feature cards
/// up top, then the dua category grid.
final class DuaScreen extends StatefulWidget {
  const DuaScreen({super.key, this.openCategory});

  /// Category id to open on arrival (deep link), e.g. 'salah'.
  final String? openCategory;

  @override
  State<DuaScreen> createState() => _DuaScreenState();
}

final class _DuaScreenState extends State<DuaScreen> {
  // App-scoped stores — never disposed here.
  late final DuaStore _store = locator<DuaStore>();
  late final DuaFavoritesStore _favorites = locator<DuaFavoritesStore>();

  @override
  void initState() {
    super.initState();
    final loading = _store.loaded.value ? null : _store.load();
    if (loading != null) {
      unawaited(loading);
    }
    if (widget.openCategory case final id?) {
      unawaited(_openCategory(id, loading));
    }
    if (!_favorites.loaded.value) {
      unawaited(_favorites.load());
    }
  }

  Future<void> _openCategory(String id, Future<void>? loading) async {
    await loading;
    final category =
        _store.categories.value.where((c) => c.id == id).firstOrNull;
    if (category != null && mounted) {
      _push(DuaCategoryScreen(category: category));
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
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.duaTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: l10n.duaSearchTitle,
            onPressed: () {
              unawaited(
                showSearch<void>(
                  context: context,
                  delegate: QSearchDelegate<Dua>(
                    items: [for (final c in _store.categories.value) ...c.duas],
                    fields: (d) => [
                      d.transliteration,
                      d.transliterationBn,
                      d.translationEn,
                      d.translationBn,
                      d.reference,
                    ],
                    itemBuilder: (_, d) => DuaCard(dua: d),
                    emptyText: l10n.duaNoResults,
                    hint: l10n.duaSearchHint,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SignalBuilder(
          builder: (context) {
            final categories = _store.categories.value;
            final favoriteIds = _favorites.ids.value;
            final favoriteDuas = <Dua>[
              for (final category in categories)
                for (final dua in category.duas)
                  if (favoriteIds.contains(dua.id)) dua,
            ];
            return ListView(
              padding: const EdgeInsets.fromLTRB(
                QSpace.s5,
                QSpace.s3,
                QSpace.s5,
                QSpace.s5,
              ),
              children: staggered([
                Row(
                  children: [
                    Expanded(
                      child: _FeatureCard(
                        title: l10n.tasbihTitle,
                        icon: Icon(
                          TrackerVisuals.iconOf('beads'),
                          size: 22,
                          color: context.q.onPrimarySoft,
                        ),
                        onTap: () => _push(const TasbihScreen()),
                      ),
                    ),
                    const SizedBox(width: QSpace.s3),
                    Expanded(
                      child: _FeatureCard(
                        title: l10n.asmaulHusnaTitle,
                        icon: Star8(color: context.q.onPrimarySoft, size: 22),
                        onTap: () => _push(const AsmaulHusnaScreen()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: QSpace.s4),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: QSpace.s3,
                  crossAxisSpacing: QSpace.s3,
                  childAspectRatio: 1.2 / context.textGrowth,
                  children: [
                    for (final category in categories)
                      _CategoryCard(
                        category: category,
                        onTap: () =>
                            _push(DuaCategoryScreen(category: category)),
                      ),
                  ],
                ),
                const SizedBox(height: QSpace.s4),
                _FavoritesSection(duas: favoriteDuas),
              ]),
            );
          },
        ),
      ),
    );
  }
}

final class _FavoritesSection extends StatelessWidget {
  const _FavoritesSection({required this.duas});

  final List<Dua> duas;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final q = context.q;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.duaFavoritesTitle,
          style: QType.titleSm.copyWith(color: q.ink),
        ),
        const SizedBox(height: QSpace.s3),
        if (duas.isEmpty)
          QCard(
            child: Text(
              l10n.duaFavoritesEmpty,
              style: QType.body.copyWith(color: q.ink2),
            ),
          )
        else
          for (final dua in duas) ...[
            DuaCard(dua: dua),
            const SizedBox(height: QSpace.s3),
          ],
      ],
    );
  }
}

final class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final Widget icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final q = context.q;
    return Semantics(
      button: true,
      label: title,
      child: QCard(
        onTap: onTap,
        padding: const EdgeInsets.all(QSpace.s4),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: q.primarySoft,
                borderRadius: BorderRadius.circular(QRadius.sm),
              ),
              child: Center(child: icon),
            ),
            const SizedBox(width: QSpace.s3),
            Expanded(
              child: Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: QType.titleSm.copyWith(color: q.ink),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.category, required this.onTap});

  final DuaCategory category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final q = context.q;
    final languageCode = Localizations.localeOf(context).languageCode;
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
                TrackerVisuals.iconOf(category.icon),
                size: 19,
                color: q.onPrimarySoft,
              ),
            ),
            const Spacer(),
            Text(
              l10n.duaCategoryName(category.id),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: QType.titleSm.copyWith(color: q.ink),
            ),
            const SizedBox(height: 2),
            Text(
              LocaleDigits.localize(
                l10n.duaCount(category.duas.length),
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
