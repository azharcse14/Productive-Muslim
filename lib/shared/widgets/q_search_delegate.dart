import 'package:flutter/material.dart';

import '../../core/theme/productive_muslim_tokens.dart';
import '../../core/theme/productive_muslim_typography.dart';
import '../extensions/context_ext.dart';

/// In-memory search over a bundled list (duas, hadith, ruqyah). [fields]
/// gives the texts an item matches on (case-insensitive substring).
final class QSearchDelegate<T> extends SearchDelegate<void> {
  QSearchDelegate({
    required this.items,
    required this.fields,
    required this.itemBuilder,
    required this.emptyText,
    String? hint,
  }) : super(searchFieldLabel: hint);

  final List<T> items;
  final Iterable<String> Function(T item) fields;
  final Widget Function(BuildContext context, T item) itemBuilder;
  final String emptyText;

  List<T> _matches() {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) {
      return const [];
    }
    return [
      for (final item in items)
        if (fields(item).any((f) => f.toLowerCase().contains(q))) item,
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
            emptyText,
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
      itemBuilder: (context, index) => itemBuilder(context, matches[index]),
    );
  }

  /// The app's own app bar (Material's default here is a grey/white bar).
  @override
  ThemeData appBarTheme(BuildContext context) {
    final theme = Theme.of(context);
    return theme.copyWith(
      inputDecorationTheme: InputDecorationTheme(
        hintStyle: QType.title.copyWith(color: context.q.ink3),
        border: InputBorder.none,
      ),
    );
  }

  @override
  List<Widget> buildActions(BuildContext context) => [
    if (query.isNotEmpty)
      IconButton(
        tooltip: MaterialLocalizations.of(context).clearButtonTooltip,
        icon: const Icon(Icons.clear),
        onPressed: () => query = '',
      ),
  ];

  @override
  Widget buildLeading(BuildContext context) => IconButton(
    tooltip: MaterialLocalizations.of(context).backButtonTooltip,
    icon: const BackButtonIcon(),
    onPressed: () => close(context, null),
  );

  @override
  Widget buildResults(BuildContext context) => _body(context);

  @override
  Widget buildSuggestions(BuildContext context) => _body(context);
}
