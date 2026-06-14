import 'package:flutter/material.dart';

import '../../../../core/theme/qalbee_tokens.dart';
import '../../../../shared/extensions/context_ext.dart';
import '../../domain/entities/hadith.dart';
import '../widgets/hadith_list_card.dart';

/// The bundled hadith for one topic.
final class HadithTopicScreen extends StatelessWidget {
  const HadithTopicScreen({required this.topic, super.key});

  final HadithTopic topic;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.hadithTopicName(topic.id))),
      body: SafeArea(
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(
            QSpace.s5,
            QSpace.s3,
            QSpace.s5,
            QSpace.s5,
          ),
          itemCount: topic.items.length,
          separatorBuilder: (_, _) => const SizedBox(height: QSpace.s3),
          itemBuilder: (context, index) =>
              HadithListCard(hadith: topic.items[index]),
        ),
      ),
    );
  }
}
