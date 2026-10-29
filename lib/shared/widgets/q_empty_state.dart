import 'package:flutter/material.dart';

import '../../core/theme/productive_muslim_tokens.dart';
import '../../core/theme/productive_muslim_typography.dart';
import '../extensions/context_ext.dart';

/// Centered empty/notice state: icon, optional title, body, optional detail
/// and action. Scrolls when the text is taller than the space (large fonts).
final class QEmptyState extends StatelessWidget {
  const QEmptyState({
    required this.icon,
    required this.body,
    this.title,
    this.detail,
    this.action,
    super.key,
  });

  final IconData icon;
  final String body;
  final String? title;

  /// Emphasised line under [body], e.g. a bearing or a value.
  final String? detail;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final q = context.q;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(QSpace.s8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: q.ink3),
            const SizedBox(height: QSpace.s4),
            if (title != null) ...[
              Text(
                title!,
                textAlign: TextAlign.center,
                style: QType.title.copyWith(color: q.ink),
              ),
              const SizedBox(height: QSpace.s2),
            ],
            Text(
              body,
              textAlign: TextAlign.center,
              style: QType.body.copyWith(color: q.ink2),
            ),
            if (detail != null) ...[
              const SizedBox(height: QSpace.s3),
              Text(
                detail!,
                textAlign: TextAlign.center,
                style: QType.title.copyWith(color: q.ink),
              ),
            ],
            if (action != null) ...[const SizedBox(height: QSpace.s6), action!],
          ],
        ),
      ),
    );
  }
}
