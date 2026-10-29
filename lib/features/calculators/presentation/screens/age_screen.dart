import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/locator.dart';
import '../../../../core/theme/productive_muslim_tokens.dart';
import '../../../../core/theme/productive_muslim_typography.dart';
import '../../../../core/utils/locale_digits.dart';
import '../../../../shared/extensions/context_ext.dart';
import '../../../../shared/widgets/q_button.dart';
import '../../../../shared/widgets/q_card.dart';
import '../../../settings/presentation/state/settings_store.dart';
import '../../domain/usecases/age_calculator.dart';
import '../widgets/date_field.dart';

/// Age calculator screen: pick a date of birth and an "as of" date, then show
/// the elapsed age in BOTH the Gregorian and the Hijri calendar over the pure
/// [AgeCalculator]. Universally understandable — neither calendar is assumed.
final class AgeScreen extends StatefulWidget {
  const AgeScreen({super.key});

  @override
  State<AgeScreen> createState() => _AgeScreenState();
}

final class _AgeScreenState extends State<AgeScreen> {
  DateTime? _birthDate;
  DateTime _asOf = DateTime.now();
  AgeResult? _result;

  Future<void> _pickBirthDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _birthDate = picked;
        _result = null;
      });
    }
  }

  Future<void> _pickAsOf() async {
    // An age can't be measured before birth.
    final first = _birthDate ?? DateTime(1900);
    final picked = await showDatePicker(
      context: context,
      initialDate: _asOf.isBefore(first) ? first : _asOf,
      firstDate: first,
      lastDate: DateTime(2200),
    );
    if (picked != null) {
      setState(() {
        _asOf = picked;
        _result = null;
      });
    }
  }

  void _calculate() {
    final birth = _birthDate;
    if (birth == null) {
      return;
    }
    setState(() {
      _result = AgeCalculator.calculate(
        birthDate: birth,
        onDate: _asOf,
        hijriOffsetDays: locator<SettingsStore>().hijriOffsetDays.value,
      );
    });
  }

  String _number(BuildContext context, int value) {
    final locale = Localizations.localeOf(context);
    return LocaleDigits.localize(
      NumberFormat.decimalPattern(locale.toString()).format(value),
      locale.languageCode,
    );
  }

  String _formatDate(BuildContext context, DateTime date) {
    final locale = Localizations.localeOf(context);
    return LocaleDigits.localize(
      DateFormat.yMMMd(locale.toString()).format(date),
      locale.languageCode,
    );
  }

  String _ageValue(BuildContext context, AgeBreakdown b) {
    final l10n = context.l10n;
    return l10n.ageValue(
      _number(context, b.years),
      _number(context, b.months),
      _number(context, b.days),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final q = context.q;
    final birthDate = _birthDate;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.ageTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(QSpace.s5),
          children: [
            Text(l10n.ageSubtitle, style: QType.body.copyWith(color: q.ink2)),
            const SizedBox(height: QSpace.s4),
            DateField(
              label: l10n.ageBirthDate,
              value: birthDate == null
                  ? l10n.ageSelectDate
                  : _formatDate(context, birthDate),
              hasValue: birthDate != null,
              onTap: _pickBirthDate,
            ),
            const SizedBox(height: QSpace.s3),
            DateField(
              label: l10n.ageAsOf,
              value: _formatDate(context, _asOf),
              onTap: _pickAsOf,
            ),
            const SizedBox(height: QSpace.s4),
            QButton(
              label: l10n.ageCalculate,
              icon: Icons.calculate_outlined,
              expand: true,
              onPressed: birthDate == null ? null : _calculate,
            ),
            if (_result case final AgeResult result) ...[
              const SizedBox(height: QSpace.s4),
              QCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.ageGregorian,
                      style: QType.label.copyWith(color: q.ink2),
                    ),
                    const SizedBox(height: QSpace.s1),
                    Text(
                      _ageValue(context, result.gregorian),
                      style: QType.num_(QType.title).copyWith(color: q.ink),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: QSpace.s3),
              QCard(
                tone: q.primarySoft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.ageHijri,
                      style: QType.label.copyWith(color: q.onPrimarySoft),
                    ),
                    const SizedBox(height: QSpace.s1),
                    Text(
                      _ageValue(context, result.hijri),
                      style: QType.num_(
                        QType.title,
                      ).copyWith(color: q.onPrimarySoft),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: QSpace.s3),
              Text(
                l10n.ageTotalDays(_number(context, result.totalDays)),
                style: QType.num_(QType.body).copyWith(color: q.ink2),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
