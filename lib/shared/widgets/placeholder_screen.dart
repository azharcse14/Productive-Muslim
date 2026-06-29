import 'package:flutter/material.dart';

import '../../core/theme/productive_muslim_tokens.dart';
import '../extensions/context_ext.dart';
import '../painters/qalb_mark.dart';

/// Temporary screen body for tabs whose feature phase hasn't landed yet.
/// Replaced phase by phase; intentionally minimal.
final class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({required this.title, super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    final q = context.q;
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            QalbMark(size: 72, color: q.ink3, accent: q.primary),
            const SizedBox(height: QSpace.s4),
            Text(
              context.l10n.comingSoon,
              style: context.text.bodyMedium?.copyWith(color: q.ink2),
            ),
          ],
        ),
      ),
    );
  }
}
