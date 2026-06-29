import 'package:flutter/material.dart';

import '../../../../core/theme/productive_muslim_tokens.dart';
import '../../../../core/theme/productive_muslim_typography.dart';
import '../../../../shared/extensions/context_ext.dart';

/// One entry in the home [QuickActionsRow]: a round icon button + caption.
/// [label] is already localized; the tap is reported via [onTap].
final class QuickAction {
  const QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
}

/// Home-screen quick-actions row (design §4.3 hub): a row of round, soft-tinted
/// icon buttons sitting just under the header for one-tap access to the key
/// features (Quran · Qibla · Tasbih · Dua). Purely presentational — labels and
/// taps come in via [actions].
final class QuickActionsRow extends StatelessWidget {
  const QuickActionsRow({required this.actions, super.key});

  /// Typically four actions, distributed evenly across the row.
  final List<QuickAction> actions;

  @override
  Widget build(BuildContext context) {
    final q = context.q;
    return Row(
      children: [
        for (final action in actions)
          Expanded(
            child: Semantics(
              button: true,
              label: action.label,
              child: InkWell(
                onTap: action.onTap,
                borderRadius: BorderRadius.circular(QRadius.md),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: QSpace.s2),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: q.primarySoft,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(action.icon, size: 24, color: q.primary),
                      ),
                      const SizedBox(height: QSpace.s2),
                      Text(
                        action.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: QType.caption.copyWith(color: q.ink2),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
