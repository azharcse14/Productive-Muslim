import 'package:flutter/foundation.dart' show mergeSort;
import 'package:flutter/material.dart';

import '../../../../core/theme/productive_muslim_tokens.dart';
import '../../../../core/theme/productive_muslim_typography.dart';
import '../../../../shared/extensions/context_ext.dart';
import '../../../settings/domain/entities/prayer_params.dart';
import '../../../settings/presentation/widgets/setting_labels.dart';
import '../../domain/entities/prayer_day.dart';
import '../../domain/entities/special_time.dart';
import 'special_times_card.dart';

/// Opens [DayTimelineSheet] as a modal bottom sheet (theme supplies the
/// 24pt top radius and surface background — no shape override here).
Future<void> showDayTimelineSheet(
  BuildContext context, {
  required PrayerDay day,
  required DateTime now,
  required String Function(DateTime) formatTime,
  Prayer? activePrayer,
  List<SpecialWindow> forbidden = const [],
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => DayTimelineSheet(
      day: day,
      now: now,
      formatTime: formatTime,
      activePrayer: activePrayer,
      forbidden: forbidden,
    ),
  );
}

enum _Tone { prayer, quiet, warn, now }

/// The day on a vertical timeline rail: sahri end, the five waqts, sunrise,
/// the [forbidden] windows and a "Now" marker, in time order. The active
/// prayer is emphasised. Purely presentational.
final class DayTimelineSheet extends StatelessWidget {
  const DayTimelineSheet({
    required this.day,
    required this.now,
    required this.formatTime,
    this.activePrayer,
    this.forbidden = const [],
    super.key,
  });

  final PrayerDay day;
  final DateTime now;

  /// Formats a wall-clock instant in the user's locale/digits.
  final String Function(DateTime) formatTime;

  /// The waqt the clock is currently inside, or null.
  final Prayer? activePrayer;

  /// Today's forbidden (makruh) windows.
  final List<SpecialWindow> forbidden;

  @override
  Widget build(BuildContext context) {
    final q = context.q;
    final l10n = context.l10n;
    final rows =
        <
          ({DateTime at, String label, String time, _Tone tone, Prayer? prayer})
        >[
          // With no safety margin sahri ends at Fajr, already on the rail.
          if (day.sahriEnd != day.fajr)
            (
              at: day.sahriEnd,
              label: l10n.sahriEndsLabel,
              time: formatTime(day.sahriEnd),
              tone: _Tone.quiet,
              prayer: null,
            ),
          for (final p in Prayer.values)
            (
              at: day.startOf(p),
              label: l10n.prayerLabelOn(p, day.dhuhr),
              time: formatTime(day.startOf(p)),
              tone: _Tone.prayer,
              prayer: p,
            ),
          (
            at: day.sunrise,
            label: l10n.sunriseLabel,
            time: formatTime(day.sunrise),
            tone: _Tone.quiet,
            prayer: null,
          ),
          for (final w in forbidden)
            (
              at: w.start,
              label: l10n.specialTimeLabel(w.time),
              time: '${formatTime(w.start)} – ${formatTime(w.end)}',
              tone: _Tone.warn,
              prayer: null,
            ),
        ];
    // Stable: equal times keep list order (the marker after them).
    mergeSort(rows, compare: (a, b) => a.at.compareTo(b.at));
    final nowIndex = rows.indexWhere((r) => r.at.isAfter(now));
    rows.insert(nowIndex < 0 ? rows.length : nowIndex, (
      at: now,
      label: l10n.specialNow,
      time: formatTime(now),
      tone: _Tone.now,
      prayer: null,
    ));

    return SafeArea(
      child: SingleChildScrollView(
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
            for (final (i, r) in rows.indexed)
              _TimelineRow(
                label: r.label,
                time: r.time,
                tone: r.tone,
                isActive: r.prayer != null && r.prayer == activePrayer,
                isFirst: i == 0,
                isLast: i == rows.length - 1,
              ),
          ],
        ),
      ),
    );
  }
}

final class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.label,
    required this.time,
    required this.tone,
    required this.isActive,
    required this.isFirst,
    required this.isLast,
  });

  final String label;
  final String time;
  final _Tone tone;
  final bool isActive;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final q = context.q;
    final color = switch (tone) {
      _Tone.prayer => isActive ? q.ink : q.ink2,
      _Tone.quiet => q.ink3,
      _Tone.warn => q.urgent,
      _Tone.now => q.primary,
    };
    final prayer = tone == _Tone.prayer;

    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: prayer ? 44 : 32),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Rail(
              isActive: isActive || tone == _Tone.now,
              isFirst: isFirst,
              isLast: isLast,
            ),
            const SizedBox(width: QSpace.s3),
            Expanded(
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: tone == _Tone.now
                    ? _NowPill(accent: q.primary, label: label)
                    : Text(
                        label,
                        style: (prayer ? QType.titleSm : QType.caption)
                            .copyWith(
                              color: color,
                              fontVariations: [
                                FontVariation('wght', isActive ? 700 : 600),
                              ],
                            ),
                      ),
              ),
            ),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: Text(
                time,
                style: QType.num_(QType.caption).copyWith(color: color),
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
          Expanded(child: Container(width: 1, color: isFirst ? null : q.line)),
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive ? q.primary : q.line,
            ),
          ),
          Expanded(child: Container(width: 1, color: isLast ? null : q.line)),
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
        // onPrimary flips with the theme: light text on the deep light-mode
        // accents, dark text on the pale dark-mode ones.
        style: QType.caption.copyWith(
          color: context.q.onPrimary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
