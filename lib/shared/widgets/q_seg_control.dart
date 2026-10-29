import 'package:flutter/material.dart';

import '../../core/theme/productive_muslim_tokens.dart';
import '../../core/theme/productive_muslim_typography.dart';
import '../../core/utils/haptics.dart';
import '../extensions/context_ext.dart';

/// Segmented control on a surface-2 track; the active segment is a lifted
/// surface pill (period selectors, mode switches).
final class QSegControl extends StatelessWidget {
  const QSegControl({
    required this.options,
    required this.activeIndex,
    required this.onChanged,
    this.semanticsPrefix,
    super.key,
  });

  final List<String> options;

  /// Spoken before each option (e.g. "Fajr" → "Fajr: Azan") when several
  /// controls on one screen share the same options; visuals unchanged.
  final String? semanticsPrefix;
  final int activeIndex;
  final ValueChanged<int> onChanged;

  void _select(int i) {
    if (i != activeIndex) {
      Haptics.selection();
    }
    onChanged(i);
  }

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
                label: semanticsPrefix == null
                    ? option
                    : '$semanticsPrefix: $option',
                onTap: () => _select(i),
                child: ExcludeSemantics(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _select(i),
                    child: AnimatedContainer(
                      duration: QMotion.fast,
                      curve: QMotion.ease,
                      // + the 4dp track inset = a 48dp tap target.
                      constraints: const BoxConstraints(
                        minHeight: QTouch.minTarget - 8,
                      ),
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(
                        vertical: 9,
                        horizontal: 8,
                      ),
                      decoration: BoxDecoration(
                        color: i == activeIndex
                            ? q.surface
                            : Colors.transparent,
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
                      // Shrink rather than break a word mid-glyph at
                      // large text scales.
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          option,
                          maxLines: 1,
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
              ),
            ),
        ],
      ),
    );
  }
}
