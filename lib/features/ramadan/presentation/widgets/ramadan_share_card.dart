import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/productive_muslim_colors.dart';
import '../../../../core/theme/productive_muslim_tokens.dart';
import '../../../../core/theme/productive_muslim_typography.dart';
import '../../../../core/utils/hijri_date.dart';
import '../../../../core/utils/locale_digits.dart';
import '../../../../shared/extensions/context_ext.dart';
import '../../../../shared/painters/qalb_mark.dart';

/// Exportable Ramadan progress card (design `MhShareCard`, 4:5). Always the
/// light palette, like the design's `q-light` artboard, and fixed text
/// scale so every export has the same layout. Positive framing only: the
/// fasts line is left out at zero rather than showing a gap.
final class RamadanShareCard extends StatelessWidget {
  const RamadanShareCard({
    required this.rozaDay,
    required this.total,
    required this.fastsLogged,
    required this.hijri,
    required this.date,
    super.key,
  });

  /// Logical size; × [pixelRatio] = a 1080×1350 PNG.
  static const size = Size(432, 540);
  static const pixelRatio = 2.5;

  final int rozaDay;
  final int total;
  final int fastsLogged;
  final HijriDate hijri;
  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context);
    final language = locale.languageCode;
    String digits(String s) => LocaleDigits.localize(s, language);
    const q = ProductiveMuslimColors.light;
    final fg = q.onPrimary;
    final muted = fg.withValues(alpha: 0.78);
    final ramadan = l10n.hijriMonthName('m${HijriDate.ramadanMonth}');
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
      // Its own text defaults: the root overlay has no Material ancestor,
      // which would leave Text in the debug (underlined) fallback style.
      child: Material(
        type: MaterialType.transparency,
        child: SizedBox.fromSize(
          size: size,
          child: ColoredBox(
            color: q.primary,
            child: Stack(
              children: [
                MotifBackground(color: fg, opacity: 0.06, cell: 110),
                Padding(
                  padding: const EdgeInsets.all(QSpace.s8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          QalbMark(
                            size: 36,
                            color: fg,
                            accent: q.accent,
                            strokeWidth: 3.2,
                          ),
                          const SizedBox(width: QSpace.s3),
                          Expanded(
                            child: Text(
                              l10n.appTitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: QType.titleSm.copyWith(color: fg),
                            ),
                          ),
                          Text(
                            digits('$ramadan ${hijri.year}'),
                            style: QType.captionLg.copyWith(color: muted),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Text(
                        l10n.ramadanShareHeading.toUpperCase(),
                        style: QType.overline.copyWith(color: muted),
                      ),
                      const SizedBox(height: QSpace.s3),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: AlignmentDirectional.centerStart,
                        child: Text(
                          digits(l10n.rozaDayOf(rozaDay, total)),
                          style: QType.num_(
                            QType.display,
                          ).copyWith(color: fg, fontSize: 52),
                        ),
                      ),
                      if (fastsLogged > 0) ...[
                        const SizedBox(height: QSpace.s4),
                        Text(
                          digits(l10n.ramadanShareFastsLogged(fastsLogged)),
                          style: QType.title.copyWith(color: q.accent),
                        ),
                      ],
                      const SizedBox(height: QSpace.s6),
                      Text(
                        digits(
                          '${hijri.day} ${l10n.hijriMonthName('m${hijri.month}')} '
                          '${hijri.year}',
                        ),
                        style: QType.body.copyWith(color: fg),
                      ),
                      Text(
                        digits(
                          DateFormat.yMMMMd(locale.toString()).format(date),
                        ),
                        style: QType.body.copyWith(color: muted),
                      ),
                      const Spacer(),
                      Text(
                        l10n.ramadanShareBlessing,
                        style: QType.captionLg.copyWith(color: muted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Paints [card] (sized [RamadanShareCard.size]) once in an off-screen
/// overlay entry and returns it as PNG bytes; the user never sees it. The
/// entry inherits the app's localizations, so the export follows the
/// current locale.
Future<Uint8List> renderShareCard(BuildContext context, Widget card) async {
  final key = GlobalKey();
  final entry = OverlayEntry(
    builder: (_) => Positioned(
      // Far left of the screen: laid out and painted, never on screen.
      left: -RamadanShareCard.size.width * 4,
      top: 0,
      width: RamadanShareCard.size.width,
      height: RamadanShareCard.size.height,
      child: ExcludeSemantics(
        child: RepaintBoundary(key: key, child: card),
      ),
    ),
  );
  Overlay.of(context, rootOverlay: true).insert(entry);
  try {
    await WidgetsBinding.instance.endOfFrame;
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(
      pixelRatio: RamadanShareCard.pixelRatio,
    );
    try {
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      return data!.buffer.asUint8List();
    } finally {
      image.dispose();
    }
  } finally {
    entry.remove();
  }
}
