import 'package:flutter/material.dart';

import '../../../../core/theme/productive_muslim_tokens.dart';
import '../../../../core/theme/productive_muslim_typography.dart';
import '../../../../core/utils/locale_digits.dart';
import '../../../../shared/extensions/context_ext.dart';
import '../../../settings/domain/entities/prayer_params.dart';
import '../../../settings/presentation/widgets/setting_labels.dart';

/// Per-prayer rakaat counts (fard · sunnah · witr). Constant reference data
/// for the detail sheet; zero segments are not rendered.
const Map<Prayer, ({int fard, int sunnah, int witr})> _rakaat = {
  Prayer.fajr: (fard: 2, sunnah: 2, witr: 0),
  Prayer.dhuhr: (fard: 4, sunnah: 6, witr: 0),
  Prayer.asr: (fard: 4, sunnah: 0, witr: 0),
  Prayer.maghrib: (fard: 3, sunnah: 2, witr: 0),
  Prayer.isha: (fard: 4, sunnah: 2, witr: 3),
};

/// Opens the prayer detail bottom sheet (design: the app theme already gives
/// the sheet a 24pt top radius and surface background, so shape is not
/// re-specified here).
Future<void> showPrayerDetailSheet(
  BuildContext context, {
  required Prayer prayer,
  required String range,
  String? jamaatTime,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => PrayerDetailSheet(
      prayer: prayer,
      range: range,
      jamaatTime: jamaatTime,
    ),
  );
}

/// Purely presentational detail body for one prayer waqt. All data arrives via
/// the constructor (already-formatted strings) so it can be tested directly.
final class PrayerDetailSheet extends StatelessWidget {
  const PrayerDetailSheet({
    required this.prayer,
    required this.range,
    this.jamaatTime,
    super.key,
  });

  final Prayer prayer;

  /// Already-formatted window, e.g. "5:10 am – 6:40 am".
  final String range;

  /// Already-formatted jamaat instant, or null when none is set.
  final String? jamaatTime;

  @override
  Widget build(BuildContext context) {
    final q = context.q;
    final l10n = context.l10n;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(QSpace.s6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: q.line,
                  borderRadius: BorderRadius.circular(QRadius.full),
                ),
              ),
            ),
            const SizedBox(height: QSpace.s5),
            Text(
              l10n.prayerLabel(prayer),
              style: QType.title.copyWith(color: q.ink),
            ),
            const SizedBox(height: QSpace.s4),
            _InfoLine(label: l10n.prayerSheetWindow, value: range),
            const SizedBox(height: QSpace.s2),
            _InfoLine(
              label: l10n.jamaatLabel,
              value: jamaatTime ?? l10n.prayerSheetNoJamaat,
            ),
            const SizedBox(height: QSpace.s5),
            Text(
              l10n.prayerSheetRakaat,
              style: QType.label.copyWith(color: q.ink2),
            ),
            const SizedBox(height: QSpace.s2),
            _RakaatChips(prayer: prayer),
            const SizedBox(height: QSpace.s5),
            Text(
              _fazilat(context, prayer),
              style: QType.body.copyWith(color: q.ink2),
            ),
          ],
        ),
      ),
    );
  }
}

/// A label/value line: the small caption-style label and its tabular value.
final class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final q = context.q;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(label, style: QType.label.copyWith(color: q.ink2)),
        const SizedBox(width: QSpace.s3),
        Expanded(
          child: Text(
            value,
            style: QType.num_(QType.body).copyWith(color: q.ink),
          ),
        ),
      ],
    );
  }
}

/// Non-zero rakaat segments for [PrayerDetailSheet]'s prayer, as soft pills.
final class _RakaatChips extends StatelessWidget {
  const _RakaatChips({required this.prayer});

  final Prayer prayer;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final counts = _rakaat[prayer]!;
    return Wrap(
      spacing: QSpace.s2,
      runSpacing: QSpace.s2,
      children: [
        if (counts.fard > 0)
          _Pill(count: counts.fard, label: l10n.rakaatFard),
        if (counts.sunnah > 0)
          _Pill(count: counts.sunnah, label: l10n.rakaatSunnah),
        if (counts.witr > 0)
          _Pill(count: counts.witr, label: l10n.rakaatWitr),
      ],
    );
  }
}

final class _Pill extends StatelessWidget {
  const _Pill({required this.count, required this.label});

  final int count;
  final String label;

  @override
  Widget build(BuildContext context) {
    final q = context.q;
    final n = LocaleDigits.localize(
      '$count',
      Localizations.localeOf(context).languageCode,
    );
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: QSpace.s2,
        vertical: QSpace.s1,
      ),
      decoration: BoxDecoration(
        color: q.primarySoft,
        borderRadius: BorderRadius.circular(QRadius.full),
      ),
      child: Text(
        '$n $label',
        style: QType.num_(QType.label).copyWith(color: q.ink),
      ),
    );
  }
}

/// Short fazilat note keyed by prayer (no hardcoded strings — guide §6).
String _fazilat(BuildContext context, Prayer prayer) {
  final l10n = context.l10n;
  return switch (prayer) {
    Prayer.fajr => l10n.prayerFazilatFajr,
    Prayer.dhuhr => l10n.prayerFazilatDhuhr,
    Prayer.asr => l10n.prayerFazilatAsr,
    Prayer.maghrib => l10n.prayerFazilatMaghrib,
    Prayer.isha => l10n.prayerFazilatIsha,
  };
}
