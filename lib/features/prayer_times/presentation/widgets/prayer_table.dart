import 'package:flutter/material.dart';

import '../../../../core/theme/qalbee_tokens.dart';
import '../../../../core/theme/qalbee_typography.dart';
import '../../../../shared/extensions/context_ext.dart';
import '../../../my_mosque/domain/entities/jamaat_config.dart';
import '../../../settings/domain/entities/prayer_params.dart';
import '../../../settings/presentation/widgets/setting_labels.dart';
import '../../domain/entities/prayer_day.dart';

/// Daily prayer table (design §4.3): the 5 prayers; start–end range,
/// jamaat column (quiet "Set jamaat" affordance when unset), and a
/// check→Muhasaba affordance (wired in Phase 7). Current waqt highlighted.
final class PrayerTable extends StatelessWidget {
  const PrayerTable({
    required this.day,
    required this.activePrayer,
    required this.jamaat,
    required this.formatTime,
    this.onSetJamaat,
    this.prayed = const {},
    this.onTogglePrayed,
    this.locked = const {},
    this.onLockedTap,
    this.dense = false,
    super.key,
  });

  final PrayerDay day;
  final Prayer? activePrayer;
  final JamaatConfig jamaat;

  /// Prayers whose waqt hasn't started yet — check affordance disabled.
  final Set<Prayer> locked;

  /// Tapping a locked prayer's affordance (e.g. to explain why it's off).
  final void Function(Prayer)? onLockedTap;

  /// Locale-aware time formatter (digits included).
  final String Function(DateTime) formatTime;
  final VoidCallback? onSetJamaat;

  /// Prayers checked off in today's muhasaba.
  final Set<Prayer> prayed;

  /// Check affordance → muhasaba write (design §4.3).
  final void Function(Prayer)? onTogglePrayed;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final q = context.q;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: q.surface,
        borderRadius: BorderRadius.circular(QRadius.lg),
        border: Border.all(color: q.line),
        boxShadow: [
          BoxShadow(
            color: q.ink.withValues(alpha: 0.06),
            offset: const Offset(0, 1),
            blurRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(QRadius.lg),
        child: Column(
          children: [
            for (final (i, prayer) in Prayer.values.indexed) ...[
              _PrayerRow(
                  name: context.l10n.prayerLabel(prayer),
                  range:
                      '${formatTime(day.startOf(prayer))} – ${formatTime(day.endOf(prayer))}',
                  jamaatTime: switch (
                      jamaat.timeFor(prayer, day.startOf(prayer))) {
                    null => null,
                    final t => formatTime(t),
                  },
                  active: prayer == activePrayer,
                  first: i == 0,
                  dense: dense,
                  onSetJamaat: onSetJamaat,
                  done: prayed.contains(prayer),
                  locked: locked.contains(prayer),
                  onLockedTap: onLockedTap == null
                      ? null
                      : () => onLockedTap!(prayer),
                  onToggleDone: onTogglePrayed == null || locked.contains(prayer)
                      ? null
                      : () => onTogglePrayed!(prayer),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

final class _PrayerRow extends StatelessWidget {
  const _PrayerRow({
    required this.name,
    required this.range,
    required this.jamaatTime,
    required this.active,
    required this.first,
    required this.dense,
    required this.done,
    required this.locked,
    this.onSetJamaat,
    this.onToggleDone,
    this.onLockedTap,
  });

  final String name;
  final String range;
  final String? jamaatTime;
  final bool active;
  final bool first;
  final bool dense;
  final bool done;
  final bool locked;
  final VoidCallback? onSetJamaat;
  final VoidCallback? onToggleDone;
  final VoidCallback? onLockedTap;

  @override
  Widget build(BuildContext context) {
    final q = context.q;
    final fg = active ? q.onPrimarySoft : null;
    return Container(
      constraints: BoxConstraints(minHeight: dense ? 40 : 54),
      padding: EdgeInsetsDirectional.symmetric(horizontal: dense ? 12 : 16),
      decoration: BoxDecoration(
        color: active ? q.primarySoft : null,
        border: first ? null : Border(top: BorderSide(color: q.line)),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: active ? q.primary : q.line,
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: dense ? 64 : 84,
            child: Text(
              name,
              style: QType.titleSm.copyWith(
                fontSize: dense ? 13.5 : null,
                color: fg ?? q.ink,
                fontVariations: [FontVariation('wght', active ? 700 : 600)],
              ),
            ),
          ),
          Expanded(
            child: Text(
              range,
              style: QType.num_(QType.caption).copyWith(
                fontSize: dense ? 11 : 12.5,
                color: fg ?? q.ink2,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(
            width: dense ? 40 : 52,
            child: jamaatTime != null
                ? Text(
                    jamaatTime!,
                    textAlign: TextAlign.center,
                    style: QType.num_(QType.caption).copyWith(
                      color: fg ?? q.ink2,
                      fontVariations: const [FontVariation('wght', 600)],
                    ),
                  )
                : GestureDetector(
                    onTap: onSetJamaat,
                    child: Text(
                      context.l10n.setJamaat,
                      textAlign: TextAlign.center,
                      style: QType.caption.copyWith(
                        fontSize: 10.5,
                        color: q.ink3,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
          ),
          const SizedBox(width: 10),
          if (locked)
            // Waqt hasn't started — no check yet; a tap explains why.
            Semantics(
              button: onLockedTap != null,
              child: InkWell(
                onTap: onLockedTap,
                customBorder: const CircleBorder(),
                child: SizedBox(
                  width: 26,
                  height: 26,
                  child: Icon(Icons.schedule, size: 18, color: q.ink3),
                ),
              ),
            )
          else
            Semantics(
              button: onToggleDone != null,
              checked: done,
              child: InkWell(
                onTap: onToggleDone,
                customBorder: const CircleBorder(),
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: done ? q.ok : null,
                    border:
                        done ? null : Border.all(color: q.ink3, width: 1.8),
                  ),
                  child: done
                      ? Icon(Icons.check, size: 15, color: q.okSoft)
                      : null,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
