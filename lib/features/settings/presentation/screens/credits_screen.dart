import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/di/locator.dart';

import '../../../../core/theme/productive_muslim_tokens.dart';
import '../../../../core/theme/productive_muslim_typography.dart';
import '../../../../shared/extensions/context_ext.dart';
import '../../../../shared/widgets/q_card.dart';
import '../../../../shared/widgets/q_list_row.dart';
import '../../../nearby_mosques/domain/external_launcher.dart';

/// Tanzil's terms ask apps to name the source and link to tanzil.net.
final _tanzilUrl = Uri.parse('https://tanzil.net');

/// Sources & licenses of bundled content (see docs/DEPENDENCIES.md and the
/// tool/ build scripts). Source names are proper nouns, so they stay as
/// written; only the labels are localized.
final class CreditsScreen extends StatelessWidget {
  const CreditsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final q = context.q;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingCredits)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(QSpace.s5, 0, QSpace.s5, QSpace.s5),
        children: [
          const SizedBox(height: QSpace.s4),
          QCard(
            padding: const EdgeInsets.symmetric(
              horizontal: QSpace.s4,
              vertical: QSpace.s1,
            ),
            child: QListRow(
              icon: Icons.menu_book_outlined,
              title: l10n.creditsQuranText,
              subtitle: l10n.creditsQuranTextLink,
              trailing: Icon(Icons.open_in_new, color: q.ink3),
              onTap: () =>
                  unawaited(locator<ExternalLauncher>().launch(_tanzilUrl)),
            ),
          ),
          _Group(l10n.quranTitle, [
            (
              l10n.creditsArabicText,
              'Tanzil Quran Text (Simple), Tanzil.net · '
                  'fawazahmed0/quran-api (Unlicense)',
            ),
            (
              l10n.creditsEnTranslation,
              'Mohammed Marmaduke William Pickthall, “The Meaning of the '
                  'Glorious Koran” (public domain) · Tanzil.net',
            ),
            (l10n.creditsBnTranslation, 'Muhiuddin Khan · Tanzil.net'),
          ]),
          _Group(l10n.hadithTitle, [
            (l10n.creditsHadithText, 'fawazahmed0/hadith-api (Unlicense)'),
            (l10n.creditsBnTranslation, 'azharcse14/hadithbangla'),
          ]),
          _Group(l10n.duaTitle, const [
            ('Hisnul Muslim', 'aminurdev/dua-ruqya-server'),
          ]),
          _Group(l10n.creditsGroupPlaces, [
            (l10n.creditsPrayerCalc, l10n.creditsPrayerCalcValue),
            (l10n.creditsCities, '© GeoNames (CC BY 4.0)'),
          ]),
          _Group(l10n.creditsGroupFonts, [
            (
              l10n.creditsFontsUi,
              'Schibsted Grotesk, Noto Sans Bengali, IBM Plex Sans Arabic '
                  '(OFL 1.1)',
            ),
            (
              l10n.creditsFontQuran,
              'KFGQPC Uthmanic Script HAFS © King Fahd Glorious Quran '
                  'Printing Complex',
            ),
          ]),
          const SizedBox(height: QSpace.s4),
          Text(
            l10n.creditsReferences,
            style: QType.caption.copyWith(color: q.ink2),
          ),
        ],
      ),
    );
  }
}

/// A headed card of (label, source) rows.
final class _Group extends StatelessWidget {
  const _Group(this.title, this.rows);

  final String title;
  final List<(String, String)> rows;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Padding(
        padding: const EdgeInsetsDirectional.only(
          top: QSpace.s6,
          bottom: QSpace.s3,
          start: QSpace.s1,
        ),
        child: Text(title.toUpperCase(), style: context.text.labelSmall),
      ),
      QCard(
        padding: const EdgeInsets.symmetric(
          horizontal: QSpace.s4,
          vertical: QSpace.s1,
        ),
        child: Column(
          children: [
            for (final (i, (label, source)) in rows.indexed) ...[
              if (i > 0) const Divider(),
              QListRow(title: label, subtitle: source),
            ],
          ],
        ),
      ),
    ],
  );
}
