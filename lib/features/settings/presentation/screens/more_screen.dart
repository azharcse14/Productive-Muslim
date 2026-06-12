import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/theme/qalbee_tokens.dart';
import '../../../../shared/extensions/context_ext.dart';
import '../../../../shared/widgets/q_card.dart';
import '../../../../shared/widgets/q_list_row.dart';

/// More tab — entry point to Settings (Ramadan/Calendar entries arrive in
/// Phase 10). In debug builds it also links to the widget gallery.
final class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final q = context.q;
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.tabMore)),
      body: ListView(
        padding: const EdgeInsets.all(QSpace.s5),
        children: [
          QCard(
            padding: const EdgeInsets.symmetric(
              horizontal: QSpace.s4,
              vertical: QSpace.s1,
            ),
            child: Column(
              children: [
                QListRow(
                  icon: Icons.explore_outlined,
                  title: context.l10n.qiblaTitle,
                  trailing: Icon(Icons.chevron_right, color: q.ink3),
                  onTap: () => context.pushNamed(Routes.qibla.name),
                ),
                const Divider(),
                QListRow(
                  icon: Icons.mosque_outlined,
                  title: context.l10n.myMosqueTitle,
                  subtitle: context.l10n.myMosqueSubtitle,
                  trailing: Icon(Icons.chevron_right, color: q.ink3),
                  onTap: () => context.pushNamed(Routes.myMosque.name),
                ),
                const Divider(),
                QListRow(
                  icon: Icons.settings_outlined,
                  title: context.l10n.settingsTitle,
                  trailing: Icon(Icons.chevron_right, color: q.ink3),
                  onTap: () => context.goNamed(Routes.settings.name),
                ),
                if (kDebugMode) ...[
                  const Divider(),
                  QListRow(
                    icon: Icons.palette_outlined,
                    title: context.l10n.galleryTitle,
                    trailing: Icon(Icons.chevron_right, color: q.ink3),
                    onTap: () => context.pushNamed(Routes.gallery.name),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
