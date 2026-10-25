import 'package:flutter/material.dart';

import '../../../../core/theme/productive_muslim_tokens.dart';
import '../../../../core/theme/productive_muslim_typography.dart';
import '../../../../shared/extensions/context_ext.dart';
import '../../../settings/domain/entities/prayer_params.dart';
import '../../../settings/presentation/widgets/setting_labels.dart';
import '../../domain/entities/prayer_day.dart';

/// Opens [DayTimelineSheet] as a modal bottom sheet (theme supplies the
/// 24pt top radius and surface background — no shape override here).
Future<void> showDayTimelineSheet(
  BuildContext context, {
  required PrayerDay day,
  required DateTime now,
  required String Function(DateTime) formatTime,
  Prayer? activePrayer,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => DayTimelineSheet(
      day: day,
      now: now,
      formatTime: formatTime,
      activePrayer: activePrayer,
    ),
  );
}

/// Today's five waqts on a vertical timeline rail, with the active prayer
/// highlighted and tagged with a "Now" pill. Purely presentational.
final class DayTimelineSheet extends StatelessWidget {
  const DayTimelineSheet({
    required this.day,
    required this.now,
    required this.formatTime,
    this.activePrayer,
    super.key,
  });

  final PrayerDay day;
  final DateTime now;

  /// Formats a wall-clock instant in the user's locale/digits.
  final String Function(DateTime) formatTime;

  /// The waqt the clock is currently inside, or null.
  final Prayer? activePrayer;

  @override
  Widget build(BuildContext context) {
    final q = context.q;
    final l10n = context.l10n;
    const prayers = Prayer.values;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(QSpace.s6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: q.line,
                  borderRadius: BorderRadius.circular(QRadius.full),
                ),
              ),
            ),
            const SizedBox(height: QSpace.s4),
            Text(
              l10n.dayTimelineTitle,
              style: QType.title.copyWith(color: q.ink),
            ),
            const SizedBox(height: QSpace.s4),
            for (var i = 0; i < prayers.length; i++)
              _TimelineRow(
                prayer: prayers[i],
                start: day.startOf(prayers[i]),
                isActive: prayers[i] == activePrayer,
                isFirst: i == 0,
                isLast: i == prayers.length - 1,
                formatTime: formatTime,
              ),
          ],
        ),
      ),
    );
  }
}

final class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.prayer,
    required this.start,
    required this.isActive,
    required this.isFirst,
    required this.isLast,
    required this.formatTime,
  });

  final Prayer prayer;
  final DateTime start;
  final bool isActive;
  final bool isFirst;
  final bool isLast;
  final String Function(DateTime) formatTime;

  @override
  Widget build(BuildContext context) {
    final q = context.q;
    final l10n = context.l10n;

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 44),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
          _Rail(
            isActive: isActive,
            isFirst: isFirst,
            isLast: isLast,
          ),
          const SizedBox(width: QSpace.s3),
          Expanded(
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                l10n.prayerLabel(prayer),
                style: QType.titleSm.copyWith(
                  color: isActive ? q.ink : q.ink2,
                  fontVariations: [
                    FontVariation('wght', isActive ? 700 : 600),
                  ],
                ),
              ),
            ),
          ),
          if (isActive) ...[
            _NowPill(accent: q.primary, label: l10n.specialNow),
            const SizedBox(width: QSpace.s2),
          ],
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: Text(
              formatTime(start),
              style: QType.num_(QType.caption).copyWith(
                color: isActive ? q.ink : q.ink2,
              ),
            ),
          ),
          ],
        ),
      ),
    );
  }
}

final class _Rail extends StatelessWidget {
  const _Rail({
    required this.isActive,
    required this.isFirst,
    required this.isLast,
  });

  final bool isActive;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final q = context.q;
    return SizedBox(
      width: 10,
      child: Column(
        children: [
          Expanded(
            child: Container(
              width: 1,
              color: isFirst ? null : q.line,
            ),
          ),
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive ? q.primary : q.line,
            ),
          ),
          Expanded(
            child: Container(
              width: 1,
              color: isLast ? null : q.line,
            ),
          ),
        ],
      ),
    );
  }
}

final class _NowPill extends StatelessWidget {
  const _NowPill({required this.accent, required this.label});

  final Color accent;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: QSpace.s2, vertical: 1),
      decoration: BoxDecoration(
        color: accent,
        borderRadius: BorderRadius.circular(QRadius.full),
      ),
      child: Text(
        label,
        style: QType.caption.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
