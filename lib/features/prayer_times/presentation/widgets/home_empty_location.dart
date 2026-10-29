import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/productive_muslim_tokens.dart';
import '../../../../core/theme/productive_muslim_typography.dart';
import '../../../../shared/extensions/context_ext.dart';
import '../../../../shared/painters/qalb_mark.dart';
import '../../../../shared/widgets/q_button.dart';

/// Home before any location is set: a single call to pick one. [failed]:
/// a location is set but its times couldn't be computed.
final class HomeEmptyLocation extends StatelessWidget {
  const HomeEmptyLocation({required this.l10n, this.failed = false, super.key});

  final AppLocalizations l10n;
  final bool failed;

  @override
  Widget build(BuildContext context) {
    final q = context.q;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(QSpace.s8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            QalbMark(size: 72, color: q.ink3, accent: q.primary),
            const SizedBox(height: QSpace.s5),
            Text(
              failed
                  ? l10n.prayerTimesComputeFailedTitle
                  : l10n.homeSetLocationTitle,
              textAlign: TextAlign.center,
              style: QType.title.copyWith(color: q.ink),
            ),
            const SizedBox(height: QSpace.s2),
            Text(
              failed
                  ? l10n.prayerTimesComputeFailedBody
                  : l10n.homeSetLocationBody,
              textAlign: TextAlign.center,
              style: QType.body.copyWith(color: q.ink2),
            ),
            const SizedBox(height: QSpace.s6),
            QButton(
              label: l10n.homeSetLocationCta,
              icon: Icons.place_outlined,
              onPressed: () => context.pushNamed(Routes.locationPicker.name),
            ),
            if (failed) ...[
              const SizedBox(height: QSpace.s2),
              // The method lives on the Settings screen (no route of its own).
              QButton(
                label: l10n.settingMethod,
                kind: QButtonKind.ghost,
                icon: Icons.tune,
                onPressed: () => context.goNamed(Routes.settings.name),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
