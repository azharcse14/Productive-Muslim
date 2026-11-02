import 'package:flutter/material.dart';

import '../../core/theme/productive_muslim_tokens.dart';
import '../extensions/context_ext.dart';

/// Uppercase overline above a group of rows (settings, More, credits).
final class QSectionHeader extends StatelessWidget {
  const QSectionHeader(this.title, {super.key});

  final String title;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsetsDirectional.only(
      top: QSpace.s6,
      bottom: QSpace.s3,
      start: QSpace.s1,
    ),
    child: Semantics(
      header: true,
      child: Text(title.toUpperCase(), style: context.text.labelSmall),
    ),
  );
}
