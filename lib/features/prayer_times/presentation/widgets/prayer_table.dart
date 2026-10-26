import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/productive_muslim_tokens.dart';
import '../../../../core/theme/productive_muslim_typography.dart';
import '../../../../shared/extensions/context_ext.dart';
import '../../../my_mosque/domain/entities/jamaat_config.dart';
import '../../../settings/domain/entities/prayer_params.dart';
import '../../../settings/presentation/widgets/setting_labels.dart';
import '../../domain/entities/prayer_day.dart';

/// Daily prayer table (design §4.3): the 5 prayers; start–end range,
/// jamaat column (the time, or an em-dash placeholder when unset — with a
/// single centered "Set jamaat" CTA at the foot of the table), and a
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
    this.onPrayerTap,
    this.mosqueName,
    this.mosqueBadge,
    this.onSwitchMosque,
    this.dense = false,
    super.key,
  });

  final PrayerDay day;
  final Prayer? activePrayer;
  final JamaatConfig jamaat;

  /// Active mosque name shown in a header strip; null hides the strip
  /// (e.g. when no profiles exist yet).
  final String? mosqueName;

  /// Small status chip beside the name, e.g. "Auto" or "Override".
  final String? mosqueBadge;

  /// Tapping the header strip opens the mosque switcher.
  final VoidCallback? onSwitchMosque;

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

  /// Tapping a row (away from its check/jamaat affordances) opens the
  /// prayer detail sheet.
  final void Function(Prayer)? onPrayerTap;
  final bool dense;

  /// Each time stays whole (non-breaking spaces), so on a narrow phone, in
  /// Bangla or at a large text scale the range wraps after the dash rather
  /// than ellipsizing away the end time.
  static String _range(String start, String end) {
    String keep(String time) => time.replaceAll(' ', '\u00A0');
    return '${keep(start)}\u00A0– ${keep(end)}';
  }

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
            if (mosqueName case final name?)
              _MosqueStrip(
                name: name,
                badge: mosqueBadge,
                onTap: onSwitchMosque,
              ),
            for (final (i, prayer) in Prayer.values.indexed) ...[
              _PrayerRow(
                  prayer: prayer,
                  name: context.l10n.prayerLabel(prayer),
                  range: _range(
                    formatTime(day.startOf(prayer)),
                    formatTime(day.endOf(prayer)),
                  ),
                  jamaatTime: switch (
                      jamaat.timeFor(prayer, day.startOf(prayer))) {
                    null => null,
                    final t => formatTime(t),
                  },
                  active: prayer == activePrayer,
                  first: i == 0 && mosqueName == null,
                  dense: dense,
                  done: prayed.contains(prayer),
                  locked: locked.contains(prayer),
                  onLockedTap: onLockedTap == null
                      ? null
                      : () => onLockedTap!(prayer),
                  onToggleDone: onTogglePrayed == null || locked.contains(prayer)
                      ? null
                      : () => onTogglePrayed!(prayer),
                  onTap: onPrayerTap == null ? null : () => onPrayerTap!(prayer),
                ),
            ],
            if (onSetJamaat != null)
              _SetJamaatButton(dense: dense, onTap: onSetJamaat!),
          ],
        ),
      ),
    );
  }
}

/// A single centered "Set jamaat" CTA pinned to the foot of the table
/// (replaces the per-row affordance) → opens the My Mosque jamaat editor.
final class _SetJamaatButton extends StatelessWidget {
  const _SetJamaatButton({required this.dense, required this.onTap});

  final bool dense;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final q = context.q;
    return InkWell(
      onTap: onTap,
      child: Container(
        constraints: BoxConstraints(minHeight: dense ? 40 : 48),
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: q.line)),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.more_time, size: 17, color: q.primary),
            const SizedBox(width: 7),
            Text(
              context.l10n.setJamaat,
              style: QType.titleSm.copyWith(
                fontSize: dense ? 13 : 14,
                color: q.primary,
                fontVariations: const [FontVariation('wght', 600)],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final class _PrayerRow extends StatelessWidget {
  const _PrayerRow({
    required this.prayer,
    required this.name,
    required this.range,
    required this.jamaatTime,
    required this.active,
    required this.first,
    required this.dense,
    required this.done,
    required this.locked,
    this.onToggleDone,
    this.onLockedTap,
    this.onTap,
  });

  final Prayer prayer;
  final String name;
  final String range;
  final String? jamaatTime;

  /// A waqt-specific glyph standing in for a generic bullet (design §4.3).
  static IconData _iconFor(Prayer prayer) => switch (prayer) {
        Prayer.fajr => Icons.wb_twilight,
        Prayer.dhuhr => Icons.wb_sunny_outlined,
        Prayer.asr => Icons.brightness_6_outlined,
        Prayer.maghrib => Icons.brightness_4_outlined,
        Prayer.isha => Icons.nightlight_outlined,
      };
  final bool active;
  final bool first;
  final bool dense;
  final bool done;
  final bool locked;
  final VoidCallback? onToggleDone;
  final VoidCallback? onLockedTap;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final q = context.q;
    final fg = active ? q.onPrimarySoft : null;
    final iconColor = active ? (fg ?? q.primary) : q.ink3;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
      constraints: BoxConstraints(minHeight: dense ? 40 : 54),
      // End inset is reduced by the check's 11dp hit-box overhang.
      padding: EdgeInsetsDirectional.only(
        start: dense ? 12 : 16,
        end: (dense ? 12 : 16) - _HitBox.overhang,
      ),
      decoration: BoxDecoration(
        color: active ? q.primarySoft : null,
        border: first ? null : Border(top: BorderSide(color: q.line)),
      ),
      child: Row(
        children: [
          _WaqtIcon(icon: _iconFor(prayer), color: iconColor, pulsing: active),
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
              maxLines: 2,
            ),
          ),
          SizedBox(
            width: dense ? 40 : 52,
            // Jamaat time, or a quiet em-dash placeholder when unset — the
            // single "Set jamaat" CTA lives at the foot of the table.
            // Scales down rather than wrapping "12:45 PM" in a narrow cell.
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                jamaatTime ?? '—',
                maxLines: 1,
                textAlign: TextAlign.center,
                style: QType.num_(QType.caption).copyWith(
                  color: jamaatTime == null ? (fg ?? q.ink3) : (fg ?? q.ink2),
                  fontVariations: const [FontVariation('wght', 600)],
                ),
              ),
            ),
          ),
          // The 48dp hit boxes below carry their own 11dp side inset, so
          // the visual 26dp circle sits where it did with a 10dp gap.
          if (locked)
            // Waqt hasn't started — no check yet; a tap explains why.
            // container: its own node, not merged into the row's tap node.
            Semantics(
              container: true,
              button: onLockedTap != null,
              label: context.l10n.a11yPrayerLocked(name),
              excludeSemantics: true,
              child: _HitBox(
                onTap: onLockedTap,
                child: Icon(Icons.schedule, size: 18, color: q.ink3),
              ),
            )
          else
            Semantics(
              container: true,
              button: onToggleDone != null,
              checked: done,
              label: context.l10n.a11yMarkPrayed(name),
              excludeSemantics: true,
              child: _HitBox(
                onTap: onToggleDone == null
                    ? null
                    : () {
                        unawaited(HapticFeedback.selectionClick());
                        onToggleDone!();
                      },
                child: AnimatedContainer(
                  duration: QMotion.fast,
                  curve: QMotion.ease,
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: done ? q.ok : null,
                    border:
                        done ? null : Border.all(color: q.ink3, width: 1.8),
                  ),
                  child: AnimatedSwitcher(
                    duration: QMotion.fast,
                    transitionBuilder: (child, anim) =>
                        ScaleTransition(scale: anim, child: child),
                    child: done
                        ? Icon(Icons.check,
                            key: const ValueKey(true),
                            size: 15,
                            color: q.okSoft)
                        : const SizedBox.shrink(key: ValueKey(false)),
                  ),
                ),
              ),
            ),
        ],
      ),
      ),
    );
  }
}

/// Header strip naming the active mosque (with an Auto/Override chip) — tap to
/// open the home mosque switcher. Shown only when ≥1 profile exists.
final class _MosqueStrip extends StatelessWidget {
  const _MosqueStrip({required this.name, this.badge, this.onTap});

  final String name;
  final String? badge;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final q = context.q;
    return InkWell(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 40),
        padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 12, 8),
        child: Row(
          children: [
            Icon(Icons.mosque_outlined, size: 16, color: q.primary),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: QType.titleSm.copyWith(
                  fontSize: 13.5,
                  color: q.ink,
                  fontVariations: const [FontVariation('wght', 600)],
                ),
              ),
            ),
            if (badge case final b?) ...[
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: q.primarySoft,
                  borderRadius: BorderRadius.circular(QRadius.full),
                ),
                child: Text(
                  b,
                  style: QType.caption.copyWith(
                    fontSize: 10.5,
                    color: q.onPrimarySoft,
                    fontVariations: const [FontVariation('wght', 600)],
                  ),
                ),
              ),
            ],
            if (onTap != null) ...[
              const SizedBox(width: 6),
              Icon(Icons.unfold_more, size: 18, color: q.ink3),
            ],
          ],
        ),
      ),
    );
  }
}

/// The waqt glyph; gently pulses while its prayer is the active waqt to
/// signal "live now" without distracting (design §4.3 motion).
final class _WaqtIcon extends StatefulWidget {
  const _WaqtIcon({
    required this.icon,
    required this.color,
    required this.pulsing,
  });

  final IconData icon;
  final Color color;
  final bool pulsing;

  @override
  State<_WaqtIcon> createState() => _WaqtIconState();
}

class _WaqtIconState extends State<_WaqtIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    // Created eagerly here (not lazily) so dispose() never triggers a
    // first-time AnimationController init — which would do an unsafe
    // TickerMode ancestor lookup on a deactivated element.
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _scale = Tween(begin: 1.0, end: 1.14).animate(
      CurvedAnimation(parent: _c, curve: Curves.easeInOut),
    );
    if (widget.pulsing) {
      unawaited(_c.repeat(reverse: true));
    }
  }

  @override
  void didUpdateWidget(_WaqtIcon old) {
    super.didUpdateWidget(old);
    if (widget.pulsing && !_c.isAnimating) {
      unawaited(_c.repeat(reverse: true));
    } else if (!widget.pulsing && _c.isAnimating) {
      _c
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final icon = Icon(widget.icon, size: 18, color: widget.color);
    if (!widget.pulsing) {
      return icon;
    }
    return ScaleTransition(scale: _scale, child: icon);
  }
}

/// A ≥48×48dp tap target around a smaller visual (Material minimum touch
/// target), so the check doesn't compete with the row's own tap.
final class _HitBox extends StatelessWidget {
  const _HitBox({required this.child, this.onTap});

  static const size = 48.0;

  /// How far the box extends past a 26dp visual on each side.
  static const overhang = (size - 26) / 2;

  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => SizedBox.square(
        dimension: size,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Center(child: child),
        ),
      );
}
