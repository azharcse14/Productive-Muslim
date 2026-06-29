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

/// Home card (design §4.3): the day's forbidden (makruh) windows and the
/// nafl windows, as two separate cards. The [active] window (computed once
/// per boundary, not per second) gets a soft highlight and a "Now" pill.
final class SpecialTimesCard extends StatelessWidget {
  const SpecialTimesCard({
    required this.windows,
    required this.active,
    required this.formatTime,
    this.onTap,
    super.key,
  });

  final List<SpecialWindow> windows;

  /// The window the clock is currently inside, or null.
  final SpecialTime? active;

  /// Formats a wall-clock instant in the user's locale/digits.
  final String Function(DateTime) formatTime;

  /// Opens the explanatory detail page for the tapped group's [SpecialKind].
  /// When null the cards aren't tappable.
  final void Function(SpecialKind)? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final q = context.q;
    final forbidden =
        windows.where((w) => w.kind == SpecialKind.forbidden).toList();
    final nafl = windows.where((w) => w.kind == SpecialKind.nafl).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _GroupCard(
          title: l10n.forbiddenTimesTitle,
          subtitle: l10n.forbiddenTimesSubtitle,
          icon: Icons.block_outlined,
          accent: q.urgent,
          windows: forbidden,
          active: active,
          formatTime: formatTime,
          onTap: onTap == null ? null : () => onTap!(SpecialKind.forbidden),
        ),
        const SizedBox(height: QSpace.s4),
        _GroupCard(
          title: l10n.naflTimesTitle,
          subtitle: l10n.naflTimesSubtitle,
          icon: Icons.auto_awesome_outlined,
          accent: q.ok,
          windows: nafl,
          active: active,
          formatTime: formatTime,
          onTap: onTap == null ? null : () => onTap!(SpecialKind.nafl),
        ),
      ],
    );
  }
}

final class _GroupCard extends StatelessWidget {
  const _GroupCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.windows,
    required this.active,
    required this.formatTime,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final List<SpecialWindow> windows;
  final SpecialTime? active;
  final String Function(DateTime) formatTime;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final q = context.q;
    final card = QCard(
      padding: const EdgeInsets.symmetric(
        horizontal: QSpace.s5,
        vertical: QSpace.s4,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: accent),
              const SizedBox(width: QSpace.s2),
              Expanded(
                child: Text(
                  title,
                  style: QType.label.copyWith(color: q.ink2),
                ),
              ),
              if (onTap != null)
                Icon(Icons.chevron_right, size: 20, color: q.ink3),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: QType.caption.copyWith(color: q.ink3),
          ),
          const SizedBox(height: QSpace.s3),
          for (final w in windows)
            _Row(
              window: w,
              accent: accent,
              active: w.time == active,
              formatTime: formatTime,
            ),
        ],
      ),
    );
    if (onTap == null) {
      return card;
    }
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: card,
    );
  }
}

final class _Row extends StatelessWidget {
  const _Row({
    required this.window,
    required this.accent,
    required this.active,
    required this.formatTime,
  });

  final SpecialWindow window;
  final Color accent;
  final bool active;
  final String Function(DateTime) formatTime;

  /// A window-specific glyph standing in for a generic bullet (design §4.3).
  static IconData _iconFor(SpecialTime t) => switch (t) {
        SpecialTime.forbiddenSunrise => Icons.wb_sunny_outlined,
        SpecialTime.forbiddenZawal => Icons.brightness_7_outlined,
        SpecialTime.forbiddenSunset => Icons.wb_twilight_outlined,
        SpecialTime.ishraq => Icons.brightness_low,
        SpecialTime.duha => Icons.brightness_5_outlined,
        SpecialTime.salatZawal => Icons.brightness_6_outlined,
        SpecialTime.awwabin => Icons.brightness_4_outlined,
        SpecialTime.tahajjud => Icons.nightlight_outlined,
      };

  @override
  Widget build(BuildContext context) {
    final q = context.q;
    final l10n = context.l10n;
    final range = '${formatTime(window.start)} – ${formatTime(window.end)}';
    return Container(
      margin: const EdgeInsets.only(top: QSpace.s1),
      padding: const EdgeInsets.symmetric(
        horizontal: QSpace.s2,
        vertical: QSpace.s2,
      ),
      decoration: BoxDecoration(
        color: active ? accent.withValues(alpha: 0.10) : null,
        borderRadius: BorderRadius.circular(QRadius.sm),
      ),
      child: Row(
        children: [
          Icon(_iconFor(window.time), size: 16, color: accent),
          const SizedBox(width: QSpace.s3),
          Expanded(
            child: Text(
              l10n.specialTimeLabel(window.time),
              style: QType.body.copyWith(
                color: q.ink,
                fontWeight: active ? FontWeight.w600 : null,
              ),
            ),
          ),
          if (active) ...[
            _NowPill(accent: accent, label: l10n.specialNow),
            const SizedBox(width: QSpace.s2),
          ],
          Text(
            range,
            style: QType.num_(QType.caption).copyWith(color: q.ink2),
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
