import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/theme/productive_muslim_tokens.dart';
import '../../../../shared/extensions/context_ext.dart';
import '../../../../shared/widgets/q_card.dart';
import '../../../../shared/widgets/q_list_row.dart';

/// Hub listing every Islamic calculator in one place — reachable from the
/// More tab. Each row pushes the matching top-level route. Zakat lives here
/// too (it is also linked directly from More and from the Ramadan hub).
final class CalculatorsScreen extends StatelessWidget {
  const CalculatorsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final q = context.q;
    final l10n = context.l10n;
    final tools = <({IconData icon, String title, String? subtitle, String route})>[
      (
        icon: Icons.volunteer_activism_outlined,
        title: l10n.zakatTitle,
        subtitle: l10n.zakatSubtitle,
        route: Routes.zakat.name,
      ),
      (
        icon: Icons.rice_bowl_outlined,
        title: l10n.fitraTitle,
        subtitle: l10n.fitraSubtitle,
        route: Routes.fitra.name,
      ),
      (
        icon: Icons.event_repeat_outlined,
        title: l10n.qazaTitle,
        subtitle: l10n.qazaSubtitle,
        route: Routes.qaza.name,
      ),
      (
        icon: Icons.account_tree_outlined,
        title: l10n.faraidTitle,
        subtitle: l10n.faraidSubtitle,
        route: Routes.faraid.name,
      ),
      (
        icon: Icons.cake_outlined,
        title: l10n.ageTitle,
        subtitle: l10n.ageSubtitle,
        route: Routes.age.name,
      ),
    ];
    return Scaffold(
      appBar: AppBar(title: Text(l10n.calculatorsTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(QSpace.s5),
          children: [
            QCard(
              padding: const EdgeInsets.symmetric(
                horizontal: QSpace.s4,
                vertical: QSpace.s1,
              ),
              child: Column(
                children: [
                  for (final (index, tool) in tools.indexed) ...[
                    if (index > 0) const Divider(),
                    QListRow(
                      icon: tool.icon,
                      title: tool.title,
                      subtitle: tool.subtitle,
                      trailing: Icon(Icons.chevron_right, color: q.ink3),
                      onTap: () => context.pushNamed(tool.route),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
