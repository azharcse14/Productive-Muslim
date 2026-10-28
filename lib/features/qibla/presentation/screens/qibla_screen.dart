import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../../core/di/locator.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/productive_muslim_tokens.dart';
import '../../../../core/theme/productive_muslim_typography.dart';
import '../../../../core/utils/locale_digits.dart';
import '../../../../shared/extensions/context_ext.dart';
import '../../../../shared/widgets/q_banner.dart';
import '../../../../shared/widgets/q_button.dart';
import '../../domain/usecases/compass_math.dart';
import '../state/qibla_store.dart';
import '../widgets/compass_dial.dart';

/// Full-screen qibla compass (design §4.4/§06): live dial, gold aligned
/// state with haptic, calibration prompt, sensor-unavailable verbal
/// fallback, and location-needed state. Distance to the Kaaba as a quiet
/// detail.
final class QiblaScreen extends StatefulWidget {
  const QiblaScreen({super.key});

  @override
  State<QiblaScreen> createState() => _QiblaScreenState();
}

final class _QiblaScreenState extends State<QiblaScreen> {
  late final QiblaStore _store = locator<QiblaStore>();
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      onHide: _store.pause,
      onShow: _store.resume,
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _store.dispose();
    super.dispose();
  }

  String _digits(BuildContext context, String text) =>
      LocaleDigits.localize(text, Localizations.localeOf(context).languageCode);

  /// Localized 16-point compass label for [degrees].
  String _point(BuildContext context, double degrees) =>
      context.l10n.qiblaCompassPoint(CompassMath.cardinal16(degrees));

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final q = context.q;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.qiblaTitle)),
      body: SafeArea(
        child: SignalBuilder(
          builder: (context) {
            final status = _store.status.value;
            final bearing = _store.bearing.value;
            return switch (status) {
              QiblaStatus.needsLocation => _CenteredNote(
                icon: Icons.place_outlined,
                text: l10n.qiblaNeedsLocation,
                action: QButton(
                  label: l10n.homeSetLocationCta,
                  icon: Icons.place_outlined,
                  onPressed: () =>
                      context.pushNamed(Routes.locationPicker.name),
                ),
              ),
              QiblaStatus.sensorUnavailable => _CenteredNote(
                icon: Icons.explore_off_outlined,
                text: l10n.qiblaSensorUnavailable,
                detail: bearing == null
                    ? null
                    : l10n.qiblaVerbalBearing(
                        _digits(context, bearing.round().toString()),
                        _point(context, bearing),
                      ),
              ),
              QiblaStatus.calibrating || QiblaStatus.ready => Stack(
                children: [
                  LayoutBuilder(
                    builder: (context, box) => SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minHeight: box.maxHeight),
                        child: Center(
                          child: SignalBuilder(
                            builder: (context) {
                              final reading = _store.heading.value;
                              final heading = reading ?? 0;
                              final aligned = _store.aligned.value;
                              return Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // The dial is a visual aid only; screen readers get
                                  // the spoken status (live region) and the standing
                                  // qibla-bearing line below instead.
                                  ExcludeSemantics(
                                    child: CompassDial(
                                      heading: heading,
                                      bearing: bearing ?? 0,
                                      aligned: aligned,
                                      size: math.min(
                                        300,
                                        0.8 * box.biggest.shortestSide,
                                      ),
                                      cardinals: [
                                        for (final c in const [
                                          'N',
                                          'E',
                                          'S',
                                          'W',
                                        ])
                                          l10n.qiblaCompassPoint(c),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: QSpace.s6),
                                  // Live only once aligned: a live heading would
                                  // be re-announced on every sensor tick.
                                  Semantics(
                                    liveRegion: aligned,
                                    child: AnimatedDefaultTextStyle(
                                      duration: QMotion.med,
                                      curve: QMotion.ease,
                                      style: QType.title.copyWith(
                                        color: aligned ? q.accentStrong : q.ink,
                                      ),
                                      child: Text(
                                        aligned
                                            ? l10n.qiblaAligned
                                            : reading == null
                                            // No sensor event yet: don't pass
                                            // a 0° placeholder off as real.
                                            ? l10n.qiblaFinding
                                            : l10n.qiblaHeading(
                                                _digits(
                                                  context,
                                                  heading.round().toString(),
                                                ),
                                                _point(context, heading),
                                              ),
                                      ),
                                    ),
                                  ),
                                  if (bearing != null) ...[
                                    const SizedBox(height: QSpace.s2),
                                    Text(
                                      l10n.qiblaVerbalBearing(
                                        _digits(
                                          context,
                                          bearing.round().toString(),
                                        ),
                                        _point(context, bearing),
                                      ),
                                      textAlign: TextAlign.center,
                                      style: QType.caption.copyWith(
                                        color: q.ink3,
                                      ),
                                    ),
                                  ],
                                  if (_store.distanceKm.value
                                      case final double km) ...[
                                    const SizedBox(height: QSpace.s2),
                                    Text(
                                      l10n.qiblaDistance(
                                        _digits(context, km.round().toString()),
                                      ),
                                      style: QType.caption.copyWith(
                                        color: q.ink3,
                                      ),
                                    ),
                                  ],
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Overlaid rather than stacked above, so the flag coming
                  // and going doesn't shove the dial.
                  if (status == QiblaStatus.calibrating)
                    PositionedDirectional(
                      top: QSpace.s2,
                      start: QSpace.s5,
                      end: QSpace.s5,
                      child: QBanner(
                        text: l10n.qiblaCalibrate,
                        icon: Icons.all_inclusive,
                        tone: q.warnSoft,
                        foreground: q.warn,
                      ),
                    ),
                ],
              ),
            };
          },
        ),
      ),
    );
  }
}

final class _CenteredNote extends StatelessWidget {
  const _CenteredNote({
    required this.icon,
    required this.text,
    this.detail,
    this.action,
  });

  final IconData icon;
  final String text;
  final String? detail;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final q = context.q;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(QSpace.s8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 56, color: q.ink3),
            const SizedBox(height: QSpace.s4),
            Text(
              text,
              textAlign: TextAlign.center,
              style: QType.body.copyWith(color: q.ink2),
            ),
            if (detail != null) ...[
              const SizedBox(height: QSpace.s3),
              Text(
                detail!,
                textAlign: TextAlign.center,
                style: QType.title.copyWith(color: q.ink),
              ),
            ],
            if (action != null) ...[const SizedBox(height: QSpace.s6), action!],
          ],
        ),
      ),
    );
  }
}
