import 'package:flutter/material.dart';

import '../../../../core/theme/qalbee_tokens.dart';
import '../../../../core/theme/qalbee_typography.dart';
import '../../../../shared/extensions/context_ext.dart';

/// Bottom sheet with radio-style options (madhab/method/theme/etc.).
/// Returns the chosen value, or null if dismissed.
Future<T?> showOptionSheet<T>({
  required BuildContext context,
  required String title,
  required List<T> options,
  required T selected,
  required String Function(T) labelOf,
  String Function(T)? sublabelOf,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) {
      final q = sheetContext.q;
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            QSpace.s5,
            QSpace.s5,
            QSpace.s5,
            QSpace.s4,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: QType.title.copyWith(color: q.ink)),
              const SizedBox(height: QSpace.s3),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final option in options)
                      MergeSemantics(
                        child: Semantics(
                          button: true,
                          selected: option == selected,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(QRadius.md),
                            onTap: () => Navigator.of(sheetContext).pop(option),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: QSpace.s2,
                                vertical: QSpace.s3,
                              ),
                              child: Row(
                                children: [
                                  _RadioDot(on: option == selected),
                                  const SizedBox(width: QSpace.s4),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          labelOf(option),
                                          style: QType.titleSm.copyWith(
                                            color: q.ink,
                                          ),
                                        ),
                                        if (sublabelOf != null)
                                          Text(
                                            sublabelOf(option),
                                            style: QType.caption.copyWith(
                                              color: q.ink2,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

final class _RadioDot extends StatelessWidget {
  const _RadioDot({required this.on});

  final bool on;

  @override
  Widget build(BuildContext context) {
    final q = context.q;
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: on ? q.primary : q.ink3, width: on ? 6.5 : 2),
      ),
    );
  }
}
