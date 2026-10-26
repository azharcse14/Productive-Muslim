import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../../core/di/locator.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/productive_muslim_tokens.dart';
import '../../../../shared/extensions/context_ext.dart';
import '../../../../shared/widgets/q_card.dart';
import '../../../../shared/widgets/q_list_row.dart';
import '../state/settings_store.dart';

/// More tab — entry point to Settings (Ramadan/Calendar entries arrive in
/// Phase 10). In debug builds it also links to the widget gallery.
final class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) => SignalBuilder(builder: _build);

  Widget _build(BuildContext context) {
    final q = context.q;
    final showAchievements =
        locator<SettingsStore>().settings.value.showAchievements;
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
                  icon: Icons.nightlight_outlined,
                  title: context.l10n.ramadanTitle,
                  trailing: Icon(Icons.chevron_right, color: q.ink3),
                  onTap: () => context.pushNamed(Routes.ramadan.name),
                ),
                const Divider(),
                QListRow(
                  icon: Icons.calendar_month_outlined,
                  title: context.l10n.calendarTitle,
                  trailing: Icon(Icons.chevron_right, color: q.ink3),
                  onTap: () => context.pushNamed(Routes.calendar.name),
                ),
                const Divider(),
                QListRow(
                  icon: Icons.format_quote_outlined,
                  title: context.l10n.hadithTitle,
                  subtitle: context.l10n.hadithSubtitle,
                  trailing: Icon(Icons.chevron_right, color: q.ink3),
                  onTap: () => context.pushNamed(Routes.hadith.name),
                ),
                const Divider(),
                QListRow(
                  icon: Icons.shield_outlined,
                  title: context.l10n.ruqyahTitle,
                  subtitle: context.l10n.ruqyahSubtitle,
                  trailing: Icon(Icons.chevron_right, color: q.ink3),
                  onTap: () => context.pushNamed(Routes.ruqyah.name),
                ),
                const Divider(),
                QListRow(
                  icon: Icons.no_food_outlined,
                  title: context.l10n.fastingTitle,
                  subtitle: context.l10n.fastingSubtitle,
                  trailing: Icon(Icons.chevron_right, color: q.ink3),
                  onTap: () => context.pushNamed(Routes.fasting.name),
                ),
                const Divider(),
                QListRow(
                  icon: Icons.account_balance_wallet_outlined,
                  title: context.l10n.expenseTitle,
                  subtitle: context.l10n.expenseSubtitle,
                  trailing: Icon(Icons.chevron_right, color: q.ink3),
                  onTap: () => context.pushNamed(Routes.expenses.name),
                ),
                if (showAchievements) ...[
                  const Divider(),
                  QListRow(
                    icon: Icons.emoji_events_outlined,
                    title: context.l10n.achievementsTitle,
                    subtitle: context.l10n.achievementsSubtitle,
                    trailing: Icon(Icons.chevron_right, color: q.ink3),
                    onTap: () => context.pushNamed(Routes.achievements.name),
                  ),
                ],
                const Divider(),
                QListRow(
                  icon: Icons.calculate_outlined,
                  title: context.l10n.calculatorsTitle,
                  subtitle: context.l10n.calculatorsSubtitle,
                  trailing: Icon(Icons.chevron_right, color: q.ink3),
                  onTap: () => context.pushNamed(Routes.calculators.name),
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
