/// Feature graphic for Google Play. Skipped by default
/// (see dart_test.yaml); run:
///   flutter test --tags store --run-skipped test/store
@Tags(['store'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:productive_muslim/core/theme/productive_muslim_colors.dart';
import 'package:productive_muslim/shared/extensions/context_ext.dart';
import 'package:productive_muslim/shared/painters/qalb_mark.dart';
import 'package:productive_muslim/shared/widgets/countdown_card.dart';

import 'store_capture.dart';

const _taglines = {
  'en':
      'A companion for the heart’s daily deen — prayer, Quran & muhasaba, '
      'fully offline.',
  'bn':
      'হৃদয়ের প্রতিদিনের দ্বীনের সঙ্গী — নামাজ, কুরআন ও মুহাসাবা, '
      'সম্পূর্ণ অফলাইনে।',
};

/// Design handoff `FeatureGraphic` (sec-rtl-notif-store.jsx), laid out on
/// its 614×300 artboard and rendered at 5/3 → 1024×500.
final class _FeatureGraphic extends StatelessWidget {
  const _FeatureGraphic({required this.locale});

  final String locale;

  @override
  Widget build(BuildContext context) {
    const q = ProductiveMuslimColors.light;
    final bn = locale == 'bn';
    final text = Theme.of(context).textTheme;
    return Material(
      color: q.primary,
      child: Stack(
        children: [
          const MotifBackground(
            color: Color(0xFFFFFFFF),
            opacity: 0.07,
            cell: 120,
          ),
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 44),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            QalbMark(
                              size: 44,
                              color: q.onPrimary,
                              accent: q.accent,
                              strokeWidth: 3,
                            ),
                            const SizedBox(width: 12),
                            Flexible(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  context.l10n.appTitle,
                                  style: text.headlineMedium!.copyWith(
                                    fontSize: 30,
                                    letterSpacing: -0.5,
                                    color: q.onPrimary,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 330),
                          child: Text(
                            _taglines[locale]!,
                            style: text.bodyLarge!.copyWith(
                              fontSize: 17,
                              height: 1.45,
                              color: q.onPrimary.withValues(alpha: 0.85),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 36),
                  SizedBox(
                    width: 168,
                    // A Column gives the card unbounded height, as Home's list does.
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Transform.rotate(
                          angle: 4 * 3.141592653589793 / 180,
                          child: Transform.scale(
                            scale: 0.92,
                            child: CountdownCard(
                              state: CountdownState.iftar,
                              skyPhase: SkyPhase.evening,
                              compact: true,
                              eyebrow: context.l10n.countdownIftarIn,
                              big: bn ? '১২:৩৩' : '12:33',
                              sub: bn
                                  ? '${context.l10n.prayerMaghrib} ৬:৪৯'
                                  : '${context.l10n.prayerMaghrib} 6:49 PM',
                              progress: 0.61,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

void main() {
  setUpAll(loadAppFonts);

  for (final locale in ['en', 'bn']) {
    storeShot('feature graphic $locale', (tester) async {
      setView(tester, const Size(1024, 500), 1024 / 614.4);
      await tester.pumpWidget(
        storeApp(_FeatureGraphic(locale: locale), locale: locale),
      );
      await tester.pumpAndSettle();
      await writeCapture(tester, 'store/play/feature_graphic_$locale.png');
    });
  }
}
