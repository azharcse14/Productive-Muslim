import 'package:flutter/material.dart';

import '../../core/theme/qalbee_tokens.dart';
import '../../core/theme/qalbee_typography.dart';
import '../extensions/context_ext.dart';

/// Segmented control on a surface-2 track; the active segment is a lifted
/// surface pill (period selectors, mode switches).
final class QSegControl extends StatelessWidget {
  const QSegControl({
    required this.options,
    required this.activeIndex,
    required this.onChanged,
    super.key,
  });

  final List<String> options;
  final int activeIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final q = context.q;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: q.surface2,
        borderRadius: BorderRadius.circular(QRadius.md),
      ),
      child: Row(
        children: [
          for (final (i, option) in options.indexed)
            Expanded(
              child: Semantics(
                button: true,
                selected: i == activeIndex,
                child: GestureDetector(
                  onTap: () => onChanged(i),
                  child: AnimatedContainer(
                    duration: QMotion.fast,
                    curve: QMotion.ease,
                    padding: const EdgeInsets.symmetric(
                      vertical: 9,
                      horizontal: 8,
                    ),
                    decoration: BoxDecoration(
                      color: i == activeIndex ? q.surface : Colors.transparent,
                      borderRadius: BorderRadius.circular(QRadius.sm),
                      boxShadow: i == activeIndex
                          ? [
                              BoxShadow(
                                color: q.ink.withValues(alpha: 0.07),
                                offset: const Offset(0, 2),
                                blurRadius: 6,
                              ),
                            ]
                          : null,
                    ),
                    child: Text(
                      option,
                      textAlign: TextAlign.center,
                      style: QType.label.copyWith(
                        fontSize: 13.5,
                        color: i == activeIndex ? q.ink : q.ink2,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
