import 'package:flutter/material.dart';

import '../../core/theme/productive_muslim_tokens.dart';
import '../extensions/context_ext.dart';
import '../painters/qalb_mark.dart';
import '../widgets/countdown_card.dart';
import '../widgets/q_banner.dart';
import '../widgets/q_button.dart';
import '../widgets/q_card.dart';
import '../widgets/q_chip.dart';
import '../widgets/q_heatmap.dart';
import '../widgets/q_list_row.dart';
import '../widgets/q_progress_ring.dart';
import '../widgets/q_seg_control.dart';
import '../widgets/q_skeleton.dart';

/// Debug-only living catalogue of the shared component library — the visual
/// regression surface for the design system. Toggle the OS theme to review
/// both palettes.
final class WidgetGalleryScreen extends StatefulWidget {
  const WidgetGalleryScreen({super.key});

  @override
  State<WidgetGalleryScreen> createState() => _WidgetGalleryScreenState();
}

final class _WidgetGalleryScreenState extends State<WidgetGalleryScreen> {
  int _segIndex = 0;

  @override
  Widget build(BuildContext context) {
    final q = context.q;
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.galleryTitle)),
      body: ListView(
        padding: const EdgeInsets.all(QSpace.s5),
        children: [
          _section('Motif'),
          Row(
            children: [
              QalbMark(size: 72, color: q.primary, accent: q.primary),
              const SizedBox(width: QSpace.s6),
              Star8(size: 32, color: q.ink2),
            ],
          ),
          _section('Countdown card — 5 states'),
          for (final (state, eyebrow, sub) in const [
            (CountdownState.calm, 'Asr ends in', 'Jamaat at 5:15 pm'),
            (CountdownState.amber, 'Jamaat in', 'Asr jamaat 5:15 pm'),
            (CountdownState.urgent, 'Asr ends in', 'Maghrib at 6:42 pm'),
            (CountdownState.sahri, 'Sahri ends in', 'Fajr at 3:51 am'),
            (CountdownState.iftar, 'Iftar in', 'Maghrib at 6:42 pm'),
          ]) ...[
            CountdownCard(
              state: state,
              eyebrow: eyebrow,
              big: '01:24:36',
              sub: sub,
              progress: 0.42,
            ),
            const SizedBox(height: QSpace.s3),
          ],
          _section('Buttons'),
          Wrap(
            spacing: QSpace.s3,
            runSpacing: QSpace.s3,
            children: [
              QButton(label: 'Primary', onPressed: () {}),
              QButton(
                label: 'Tonal',
                kind: QButtonKind.tonal,
                onPressed: () {},
              ),
              QButton(
                label: 'Outline',
                kind: QButtonKind.outline,
                onPressed: () {},
              ),
              QButton(
                label: 'Ghost',
                kind: QButtonKind.ghost,
                onPressed: () {},
              ),
              QButton(
                label: 'Accent',
                kind: QButtonKind.accent,
                onPressed: () {},
              ),
              const QButton(label: 'Disabled', onPressed: null),
              QButton(
                label: 'Small',
                small: true,
                icon: Icons.add,
                onPressed: () {},
              ),
            ],
          ),
          _section('Chips & segmented control'),
          Wrap(
            spacing: QSpace.s2,
            children: [
              QChip(label: 'Active', active: true, onTap: () {}),
              QChip(label: 'Inactive', onTap: () {}),
              QChip(label: 'With icon', icon: Icons.star_outline, onTap: () {}),
            ],
          ),
          const SizedBox(height: QSpace.s3),
          QSegControl(
            options: const ['Today', 'Week', 'Month', 'Year'],
            activeIndex: _segIndex,
            onChanged: (i) => setState(() => _segIndex = i),
          ),
          _section('Progress ring & heatmap'),
          Row(
            children: [
              QProgressRing(
                progress: 0.72,
                child: Text('72%', style: context.text.titleMedium),
              ),
              const SizedBox(width: QSpace.s8),
              const QHeatmap(
                weeks: [
                  [0, 1, 2, 3, 4, 2, 1],
                  [1, 0, 3, 4, 2, 0, 2],
                  [2, 3, 4, 1, 0, 1, 3],
                  [4, 2, 1, 0, 3, 4, -1],
                ],
              ),
            ],
          ),
          _section('Card, list row, banner, skeleton'),
          QCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                QListRow(
                  title: 'List row title',
                  subtitle: 'Supporting caption',
                  icon: Icons.notifications_outlined,
                  trailing: Icon(Icons.chevron_right, color: q.ink3),
                  onTap: () {},
                ),
                const Divider(),
                const SizedBox(height: QSpace.s3),
                const QBanner(
                  text: 'Inline banner with an informational message that '
                      'wraps across lines without truncation.',
                ),
                const SizedBox(height: QSpace.s3),
                const QSkeleton(width: 180),
                const SizedBox(height: QSpace.s2),
                const QSkeleton(),
              ],
            ),
          ),
          const SizedBox(height: QSpace.s10),
        ],
      ),
    );
  }

  Widget _section(String title) => Padding(
        padding: const EdgeInsets.only(top: QSpace.s6, bottom: QSpace.s3),
        child: Text(
          title.toUpperCase(),
          style: context.text.labelSmall,
        ),
      );
}
