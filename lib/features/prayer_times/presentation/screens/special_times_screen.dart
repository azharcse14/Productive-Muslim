import 'package:flutter/material.dart';

import '../../../../core/theme/productive_muslim_tokens.dart';
import '../../../../core/theme/productive_muslim_typography.dart';
import '../../../../shared/extensions/context_ext.dart';
import '../../../../shared/widgets/q_card.dart';
import '../../domain/entities/special_time.dart';
import '../widgets/special_times_card.dart';

/// Explanatory detail page for one home card — either the forbidden
/// (makruh) windows or the nafl windows (design §4.3 hand-off): what each
/// window is, when it falls today, and why. Opened by tapping its card.
final class SpecialTimesScreen extends StatelessWidget {
  const SpecialTimesScreen({
    required this.kind,
    required this.windows,
    super.key,
  });

  final SpecialKind kind;

  /// The windows of [kind] for today (already filtered).
  final List<SpecialWindow> windows;

  String _formatTime(BuildContext context, DateTime time) {
    return context.clockTime(time);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final q = context.q;
    final isForbidden = kind == SpecialKind.forbidden;
    final accent = isForbidden ? q.urgent : q.ok;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isForbidden ? l10n.forbiddenTimesTitle : l10n.naflTimesTitle,
        ),
      ),
      body: ListView(
        // Edge-to-edge: clear the system nav bar at the end.
        padding:
            const EdgeInsets.all(QSpace.s5) +
            EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom),
        children: [
          Row(
            children: [
              Icon(
                isForbidden
                    ? Icons.block_outlined
                    : Icons.auto_awesome_outlined,
                size: 20,
                color: accent,
              ),
              const SizedBox(width: QSpace.s2),
              Expanded(
                child: Text(
                  isForbidden ? l10n.forbiddenTimesIntro : l10n.naflTimesIntro,
                  style: QType.body.copyWith(color: q.ink2),
                ),
              ),
            ],
          ),
          const SizedBox(height: QSpace.s5),
          if (windows.isEmpty)
            Text(
              l10n.specialTimesEmpty,
              style: QType.body.copyWith(color: q.ink3),
            ),
          for (final w in windows) ...[
            _DetailCard(
              window: w,
              accent: accent,
              formatTime: (t) => _formatTime(context, t),
            ),
            const SizedBox(height: QSpace.s3),
          ],
        ],
      ),
    );
  }
}

final class _DetailCard extends StatelessWidget {
  const _DetailCard({
    required this.window,
    required this.accent,
    required this.formatTime,
  });

  final SpecialWindow window;
  final Color accent;
  final String Function(DateTime) formatTime;

  @override
  Widget build(BuildContext context) {
    final q = context.q;
    final l10n = context.l10n;
    final range = '${formatTime(window.start)} – ${formatTime(window.end)}';
    return QCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: accent,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: QSpace.s3),
              Expanded(
                flex: 3,
                child: Text(
                  l10n.specialTimeLabel(window.time),
                  style: QType.titleSm.copyWith(color: q.ink),
                ),
              ),
              // Long label or large text: the range wraps instead of overflowing.
              Flexible(
                flex: 2,
                child: Text(
                  range,
                  textAlign: TextAlign.end,
                  style: QType.num_(QType.caption).copyWith(color: q.ink2),
                ),
              ),
            ],
          ),
          const SizedBox(height: QSpace.s2),
          Text(
            l10n.specialTimeDetail(window.time),
            style: QType.body.copyWith(color: q.ink2),
          ),
        ],
      ),
    );
  }
}
