import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../../core/di/locator.dart';
import '../../../../core/theme/qalbee_tokens.dart';
import '../../../../core/theme/qalbee_typography.dart';
import '../../../../core/utils/locale_digits.dart';
import '../../../../shared/extensions/context_ext.dart';
import '../../../../shared/widgets/q_card.dart';
import '../../../muhasaba/presentation/widgets/tracker_visuals.dart';
import '../../domain/entities/ruqyah.dart';
import '../state/ruqyah_store.dart';
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
    unawaited(HapticFeedback.selectionClick());
    unawaited(
      Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => screen),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.ruqyahTitle)),
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
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: QSpace.s3,
                  crossAxisSpacing: QSpace.s3,
                  childAspectRatio: 1.35,
                  children: [
                    for (final category in categories)
                      _CategoryCard(
                        category: category,
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
              Text(
                l10n.ruqyahHowToTitle,
                style: QType.titleSm.copyWith(color: q.ink),
              ),
            ],
          ),
          const SizedBox(height: QSpace.s2),
          Text(
            l10n.ruqyahHowToBody,
            style: QType.body.copyWith(color: q.ink2),
          ),
        ],
      ),
    );
  }
}

final class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.category, required this.onTap});

  final RuqyahCategory category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final q = context.q;
    final languageCode = Localizations.localeOf(context).languageCode;
    return Semantics(
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: QCard(
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
                l10n.ruqyahCategoryName(category.id),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: QType.titleSm.copyWith(color: q.ink),
              ),
              const SizedBox(height: 2),
              Text(
                LocaleDigits.localize(
                  l10n.ruqyahCount(category.items.length),
                  languageCode,
                ),
                style: QType.caption.copyWith(color: q.ink2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
