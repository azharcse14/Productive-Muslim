import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:signals_flutter/signals_flutter.dart';

import '../../../../core/di/locator.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/settings/settings_store.dart';
import '../../../../core/theme/productive_muslim_tokens.dart';
import '../../../../core/utils/hijri_date.dart';
import '../../../../core/utils/wall_time.dart';
import '../../../../shared/extensions/context_ext.dart';
import '../../../../shared/widgets/q_card.dart';
import '../../../../shared/widgets/q_list_row.dart';
import '../../../../shared/widgets/q_section_header.dart';
import '../../../../shared/widgets/staggered_entrance.dart';
import '../../../ramadan/domain/usecases/ramadan_utils.dart';
import '../../domain/repositories/zoned_clock.dart';

/// More tab — every secondary destination, grouped (Worship / Tools / You)
/// rather than one long list. Ramadan rises to the top while it's in
/// season. In debug builds it also links to the widget gallery.
final class MoreScreen extends StatefulWidget {
  const MoreScreen({super.key});

  @override
  State<MoreScreen> createState() => _MoreScreenState();
}

final class _MoreScreenState extends State<MoreScreen> {
  final _settings = locator<SettingsStore>();

  /// The tab stays alive in the shell: re-read the day each minute so
  /// Ramadan rises (and drops after Eid) without a restart.
  final _minute = signal(0);
  late final Timer _ticker;

  /// Only notifies on change, so the minute tick rebuilds nothing until
  /// the season flips.
  late final _inRamadan = computed(() {
    _minute.value;
    // Today at the user's location, like every other "today" in the app.
    final location = _settings.location.value;
    final now = location == null
        ? floatingNow()
        : locator<ZonedClock>().nowAt(location);
    return RamadanUtils.isRamadan(
      HijriDate.fromGregorian(
        now,
        offsetDays: _settings.settings.value.hijriOffsetDays,
      ),
    );
  });

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _minute.value++,
    );
  }

  @override
  void dispose() {
    _ticker.cancel();
    _inRamadan.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SignalBuilder(builder: _build);

  Widget _build(BuildContext context) {
    final l10n = context.l10n;
    final showAchievements = _settings.settings.value.showAchievements;
    final inRamadan = _inRamadan.value;
    final ramadan = _Entry(
      Icons.nightlight_outlined,
      l10n.ramadanTitle,
      null,
      () => context.pushNamed(Routes.ramadan.name),
    );
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.tabMore),
        actions: [
          IconButton(
            tooltip: l10n.settingsTitle,
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.goNamed(Routes.settings.name),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(QSpace.s5, 0, QSpace.s5, QSpace.s5),
        children: staggered([
          if (inRamadan) ...[
            const SizedBox(height: QSpace.s5),
            _Group([ramadan]),
          ],
          QSectionHeader(l10n.moreGroupWorship),
          _Group([
            _Entry(
              Icons.explore_outlined,
              l10n.qiblaTitle,
              null,
              () => context.pushNamed(Routes.qibla.name),
            ),
            _Entry(
              Icons.calendar_month_outlined,
              l10n.calendarTitle,
              null,
              () => context.pushNamed(Routes.calendar.name),
            ),
            _Entry(
              Icons.no_food_outlined,
              l10n.fastingTitle,
              l10n.fastingSubtitle,
              () => context.pushNamed(Routes.fasting.name),
            ),
            if (!inRamadan) ramadan,
            _Entry(
              Icons.auto_awesome_outlined,
              l10n.asmaulHusnaTitle,
              null,
              () => context.pushNamed(Routes.asmaulHusna.name),
            ),
            _Entry(
              Icons.person_outline,
              l10n.rasulNamesTitle,
              null,
              () => context.pushNamed(Routes.rasulNames.name),
            ),
            _Entry(
              Icons.format_quote_outlined,
              l10n.hadithTitle,
              l10n.hadithSubtitle,
              () => context.pushNamed(Routes.hadith.name),
            ),
            _Entry(
              Icons.shield_outlined,
              l10n.ruqyahTitle,
              l10n.ruqyahSubtitle,
              () => context.pushNamed(Routes.ruqyah.name),
            ),
          ]),
          QSectionHeader(l10n.moreGroupTools),
          _Group([
            _Entry(
              Icons.mosque_outlined,
              l10n.myMosqueTitle,
              l10n.myMosqueSubtitle,
              () => context.pushNamed(Routes.myMosque.name),
            ),
            _Entry(
              Icons.calculate_outlined,
              l10n.calculatorsTitle,
              l10n.calculatorsSubtitle,
              () => context.pushNamed(Routes.calculators.name),
            ),
            _Entry(
              Icons.account_balance_wallet_outlined,
              l10n.expenseTitle,
              l10n.expenseSubtitle,
              () => context.pushNamed(Routes.expenses.name),
            ),
            _Entry(
              Icons.monitor_heart_outlined,
              l10n.healthTitle,
              l10n.healthSubtitle,
              () => context.pushNamed(Routes.health.name),
            ),
            _Entry(
              Icons.spa_outlined,
              l10n.tibbNabawiTitle,
              l10n.tibbNabawiSubtitle,
              () => context.pushNamed(Routes.tibbNabawi.name),
            ),
          ]),
          QSectionHeader(l10n.moreGroupYou),
          _Group([
            if (showAchievements)
              _Entry(
                Icons.emoji_events_outlined,
                l10n.achievementsTitle,
                l10n.achievementsSubtitle,
                () => context.pushNamed(Routes.achievements.name),
              ),
            _Entry(
              Icons.settings_outlined,
              l10n.settingsTitle,
              null,
              () => context.goNamed(Routes.settings.name),
            ),
            if (kDebugMode)
              _Entry(
                Icons.palette_outlined,
                l10n.galleryTitle,
                null,
                () => context.pushNamed(Routes.gallery.name),
              ),
          ]),
        ]),
      ),
    );
  }
}

final class _Entry {
  const _Entry(this.icon, this.title, this.subtitle, this.onTap);

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
}

/// One card of rows separated by dividers.
final class _Group extends StatelessWidget {
  const _Group(this.entries);

  final List<_Entry> entries;

  @override
  Widget build(BuildContext context) {
    final q = context.q;
    return QCard(
      padding: const EdgeInsets.symmetric(
        horizontal: QSpace.s4,
        vertical: QSpace.s1,
      ),
      child: Column(
        children: [
          for (final (i, entry) in entries.indexed) ...[
            if (i > 0) const Divider(),
            QListRow(
              icon: entry.icon,
              title: entry.title,
              subtitle: entry.subtitle,
              trailing: Icon(Icons.chevron_right, color: q.ink3),
              onTap: entry.onTap,
            ),
          ],
        ],
      ),
    );
  }
}
