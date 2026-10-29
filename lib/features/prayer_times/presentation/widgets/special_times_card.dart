import 'package:flutter/material.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/productive_muslim_tokens.dart';
import '../../../../core/theme/productive_muslim_typography.dart';
import '../../../../shared/extensions/context_ext.dart';
import '../../../../shared/widgets/q_card.dart';
import '../../domain/entities/special_time.dart';

/// Localized labels for [SpecialTime] (no hardcoded strings — guide §6).
extension SpecialTimeLabels on AppLocalizations {
  String specialTimeLabel(SpecialTime t) => switch (t) {
    SpecialTime.forbiddenSunrise => specialTimeForbiddenSunrise,
    SpecialTime.forbiddenZawal => specialTimeForbiddenZawal,
    SpecialTime.forbiddenSunset => specialTimeForbiddenSunset,
    SpecialTime.ishraq => specialTimeIshraq,
    SpecialTime.duha => specialTimeDuha,
    SpecialTime.salatZawal => specialTimeSalatZawal,
    SpecialTime.awwabin => specialTimeAwwabin,
    SpecialTime.tahajjud => specialTimeTahajjud,
  };

  String specialTimeDetail(SpecialTime t) => switch (t) {
    SpecialTime.forbiddenSunrise => specialDetailForbiddenSunrise,
    SpecialTime.forbiddenZawal => specialDetailForbiddenZawal,
    SpecialTime.forbiddenSunset => specialDetailForbiddenSunset,
    SpecialTime.ishraq => specialDetailIshraq,
    SpecialTime.duha => specialDetailDuha,
    SpecialTime.salatZawal => specialDetailSalatZawal,
    SpecialTime.awwabin => specialDetailAwwabin,
    SpecialTime.tahajjud => specialDetailTahajjud,
  };
}

/// Home row (design §4.3): one compact line for the special window running
/// now ("Now: …") or starting next ("Next: …"), with the forbidden-time
/// caveat under a forbidden window. Tapping opens that kind's detail page.
final class SpecialTimeRow extends StatelessWidget {
  const SpecialTimeRow({
    required this.window,
    required this.active,
    required this.formatTime,
    this.onTap,
    super.key,
  });

  final SpecialWindow window;

  /// Whether the clock is inside [window] (else it is the next one).
  final bool active;

  /// Formats a wall-clock instant in the user's locale/digits.
  final String Function(DateTime) formatTime;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final q = context.q;
    final forbidden = window.kind == SpecialKind.forbidden;
    final accent = forbidden ? q.urgent : q.ok;
    final range =
        '${formatTime(window.start)}\u00A0– ${formatTime(window.end)}';
    return QCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(
        horizontal: QSpace.s4,
        vertical: QSpace.s3,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                forbidden ? Icons.block_outlined : Icons.auto_awesome_outlined,
                size: 16,
                color: accent,
              ),
              const SizedBox(width: QSpace.s2),
              Expanded(
                child: Text(
                  '${active ? l10n.specialNow : l10n.specialNext}: '
                  '${l10n.specialTimeLabel(window.time)}',
                  style: QType.body.copyWith(
                    color: q.ink,
                    fontWeight: active ? FontWeight.w600 : null,
                  ),
                ),
              ),
              const SizedBox(width: QSpace.s2),
              Text(
                range,
                style: QType.num_(QType.caption).copyWith(color: q.ink2),
              ),
              if (onTap != null)
                Icon(Icons.chevron_right, size: 20, color: q.ink3),
            ],
          ),
          if (forbidden) ...[
            const SizedBox(height: 2),
            Text(
              l10n.forbiddenTimesSubtitle,
              style: QType.caption.copyWith(color: q.ink3),
            ),
          ],
        ],
      ),
    );
  }
}
