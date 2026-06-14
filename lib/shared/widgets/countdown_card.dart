import 'package:flutter/widgets.dart';

import '../../core/theme/qalbee_colors.dart';
import '../../core/theme/qalbee_tokens.dart';
import '../../core/theme/qalbee_typography.dart';
import '../extensions/context_ext.dart';
import '../painters/qalb_mark.dart';

/// Visual states of the smart countdown hero (design §02):
/// calm → amber (jamaat ≤10 min) → urgent (last 20 min of waqt),
/// plus the Ramadan overrides sahri ("Sahri ends in") and iftar ("Iftar in").
/// Color transitions animate at 240ms. Urgent is a time-pressure color —
/// never used for missed deeds.
enum CountdownState { calm, amber, urgent, sahri, iftar }

/// The countdown hero card shell: eyebrow overline, large tabular numeral,
/// caption, and a thin progress bar, over a ≤6% motif tiling.
/// Phase 3 drives it from the prayer-times state machine.
final class CountdownCard extends StatelessWidget {
  const CountdownCard({
    required this.state,
    required this.eyebrow,
    required this.big,
    required this.sub,
    required this.progress,
    this.footer = const [],
    this.compact = false,
    super.key,
  });

  final CountdownState state;

  /// Overline label, e.g. "ASR ENDS IN".
  final String eyebrow;

  /// The hero numeral, e.g. "01:24:36".
  final String big;

  /// Caption beneath, e.g. "Jamaat at 7:15 pm".
  final String sub;

  /// 0..1 elapsed fraction of the current window.
  final double progress;

  /// Optional pre-formatted info items under the progress bar
  /// (e.g. sunrise/sunset context for the active waqt).
  final List<({IconData icon, String text})> footer;

  /// Small-screen variant (360×640): 36px numeral.
  final bool compact;

  ({Color bg, Color fg, Color sub, Color bar, Color ring}) _colors(
    QalbeeColors q,
  ) {
    const none = Color(0x00000000);
    return switch (state) {
      CountdownState.calm => (
          bg: q.surface,
          fg: q.ink,
          sub: q.ink2,
          bar: q.primary,
          ring: q.line,
        ),
      CountdownState.amber => (
          bg: q.warnSoft,
          fg: q.warn,
          sub: q.warn,
          bar: q.warn,
          ring: none,
        ),
      CountdownState.urgent => (
          bg: q.urgentSoft,
          fg: q.urgent,
          sub: q.urgent,
          bar: q.urgent,
          ring: none,
        ),
      CountdownState.sahri => (
          bg: q.primary,
          fg: q.onPrimary,
          sub: q.onPrimary,
          bar: q.accent,
          ring: none,
        ),
      CountdownState.iftar => (
          bg: q.accentSoft,
          fg: q.onAccentSoft,
          sub: q.onAccentSoft,
          bar: q.accent,
          ring: none,
        ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final c = _colors(context.q);
    final numeralSize = compact ? 36.0 : 56.0;
    return AnimatedContainer(
      duration: QMotion.med,
      curve: QMotion.ease,
      decoration: BoxDecoration(
        color: c.bg,
        borderRadius: BorderRadius.circular(QRadius.xl),
        border: Border.all(color: c.ring),
        boxShadow: [
          BoxShadow(
            color: context.q.ink.withValues(alpha: 0.06),
            offset: const Offset(0, 1),
            blurRadius: 2,
          ),
          BoxShadow(
            color: context.q.ink.withValues(alpha: 0.07),
            offset: const Offset(0, 4),
            blurRadius: 14,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(QRadius.xl),
        child: Stack(
          children: [
            MotifBackground(color: c.fg, opacity: 0.055, cell: 120),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 22, 24, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    eyebrow.toUpperCase(),
                    style: QType.overline.copyWith(
                      color: c.sub.withValues(alpha: 0.85),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(
                      top: compact ? 5 : 8,
                      bottom: compact ? 4 : 6,
                    ),
                    child: Text(
                      big,
                      style: QType.countdown.copyWith(
                        fontSize: numeralSize,
                        color: c.fg,
                      ),
                    ),
                  ),
                  Text(
                    sub,
                    style: QType.caption.copyWith(
                      fontSize: 12.5,
                      color: c.sub.withValues(alpha: 0.85),
                    ),
                  ),
                  SizedBox(height: compact ? 10 : 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: SizedBox(
                      height: 5,
                      width: double.infinity,
                      child: ColoredBox(
                        color: c.fg.withValues(alpha: 0.14),
                        child: FractionallySizedBox(
                          alignment: AlignmentDirectional.centerStart,
                          widthFactor: progress.clamp(0, 1),
                          child: ColoredBox(color: c.bar),
                        ),
                      ),
                    ),
                  ),
                  if (footer.isNotEmpty) ...[
                    SizedBox(height: compact ? 8 : 12),
                    Wrap(
                      spacing: QSpace.s4,
                      runSpacing: QSpace.s1,
                      children: [
                        for (final item in footer)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                item.icon,
                                size: 14,
                                color: c.sub.withValues(alpha: 0.85),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                item.text,
                                style: QType.num_(QType.caption).copyWith(
                                  fontSize: 12,
                                  color: c.sub.withValues(alpha: 0.85),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
