import 'package:flutter/material.dart';

import '../../../../core/theme/productive_muslim_tokens.dart';
import '../../../../core/theme/productive_muslim_typography.dart';
import '../../../../shared/extensions/context_ext.dart';
import '../../domain/entities/dua.dart';
import '../widgets/dua_card.dart';

/// Full-text dua search across every category. Matches transliteration,
/// English/Bangla translation and reference (case-insensitive).
final class DuaSearchDelegate extends SearchDelegate<void> {
  DuaSearchDelegate(List<DuaCategory> categories, {String? hint})
      : _duas = [for (final c in categories) ...c.duas],
        super(searchFieldLabel: hint);

  final List<Dua> _duas;

  List<Dua> _matches() {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) {
      return const [];
    }
    return [
      for (final dua in _duas)
        if (dua.transliteration.toLowerCase().contains(q) ||
            dua.transliterationBn.toLowerCase().contains(q) ||
            dua.translationEn.toLowerCase().contains(q) ||
            dua.translationBn.toLowerCase().contains(q) ||
            dua.reference.toLowerCase().contains(q))
          dua,
    ];
  }

  Widget _body(BuildContext context) {
    if (query.trim().isEmpty) {
      return const SizedBox.shrink();
    }
    final matches = _matches();
    if (matches.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(QSpace.s5),
          child: Text(
            context.l10n.duaNoResults,
            textAlign: TextAlign.center,
            style: QType.body.copyWith(color: context.q.ink2),
          ),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        QSpace.s5,
        QSpace.s3,
        QSpace.s5,
        QSpace.s5,
      ),
      itemCount: matches.length,
      separatorBuilder: (_, _) => const SizedBox(height: QSpace.s3),
      itemBuilder: (context, index) => DuaCard(dua: matches[index]),
    );
  }

  @override
  List<Widget> buildActions(BuildContext context) => [
        if (query.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () => query = '',
          ),
      ];

  @override
  Widget buildLeading(BuildContext context) => IconButton(
        icon: const BackButtonIcon(),
        onPressed: () => close(context, null),
      );

  @override
  Widget buildResults(BuildContext context) => _body(context);

  @override
  Widget buildSuggestions(BuildContext context) => _body(context);
}
