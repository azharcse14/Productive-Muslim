import 'dart:async';

import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../../core/di/locator.dart';
import '../../../../core/theme/productive_muslim_tokens.dart';
import '../../../../shared/extensions/context_ext.dart';
import '../../../../shared/widgets/q_skeleton.dart';
import '../state/hadith_store.dart';
import '../widgets/hadith_list_card.dart';

/// One bundled hadith, opened from the Home "Hadith of the day" card.
final class HadithDetailScreen extends StatefulWidget {
  const HadithDetailScreen({required this.id, super.key});

  final String id;

  @override
  State<HadithDetailScreen> createState() => _HadithDetailScreenState();
}

final class _HadithDetailScreenState extends State<HadithDetailScreen> {
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
        final hadith = _store.items.value
            .where((h) => h.id == widget.id)
            .firstOrNull;
        return Scaffold(
          appBar: AppBar(
            title: Text(
              hadith == null
                  ? l10n.hadithTitle
                  : l10n.hadithTopicName(hadith.topic),
            ),
          ),
          body: SafeArea(
            child: switch ((hadith, _store.loaded.value)) {
              (final h?, _) => ListView(
                padding: const EdgeInsets.all(QSpace.s5),
                children: [HadithListCard(hadith: h)],
              ),
              (null, false) => const QSkeletonList(count: 1, height: 220),
              (null, true) => Center(child: Text(l10n.hadithNotFound)),
            },
          ),
        );
      },
    );
  }
}
