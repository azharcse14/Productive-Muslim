import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/productive_muslim_tokens.dart';
import '../../../../core/theme/productive_muslim_typography.dart';
import '../../../../core/utils/locale_digits.dart';
import '../../../../shared/extensions/context_ext.dart';
import '../../../../shared/widgets/q_banner.dart';
import '../../../../shared/widgets/q_button.dart';
import '../../../../shared/widgets/q_card.dart';
import '../../domain/usecases/qaza_calculator.dart';

/// Qaza Salah calculator: estimates outstanding obligatory prayers over a
/// chosen period so the user can plan to make them up. Deliberately calm,
/// no-guilt tone — the result is an estimate, not a verdict.
final class QazaScreen extends StatefulWidget {
  const QazaScreen({super.key});

  @override
  State<QazaScreen> createState() => _QazaScreenState();
}

final class _QazaScreenState extends State<QazaScreen> {
  DateTime? _startDate;
  DateTime? _endDate;
  bool _includeWitr = false;
  final _madeUp = TextEditingController();

  QazaResult? _result;

  @override
  void dispose() {
    _madeUp.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isStart}) async {
    final now = DateTime.now();
    final initial = (isStart ? _startDate : _endDate) ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900),
      lastDate: DateTime(now.year + 1, 12, 31),
    );
    if (picked == null) {
      return;
    }
    setState(() {
      if (isStart) {
        _startDate = picked;
      } else {
        _endDate = picked;
      }
      _result = null;
    });
  }

  bool get _inverted =>
      _startDate != null && _endDate != null && _endDate!.isBefore(_startDate!);

  void _calculate() {
    final start = _startDate;
    final end = _endDate;
    if (start == null || end == null) {
      return;
    }
    setState(() {
      _result = QazaCalculator.calculate(
        QazaInput(
          startDate: start,
          endDate: end,
          includeWitr: _includeWitr,
          alreadyMadeUpPerPrayer:
              int.tryParse(LocaleDigits.toAscii(_madeUp.text)) ?? 0,
        ),
      );
    });
  }

  String _formatCount(BuildContext context, int n) {
    final locale = Localizations.localeOf(context);
    return LocaleDigits.localize(
      NumberFormat.decimalPattern(locale.toString()).format(n),
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

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final q = context.q;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.qazaTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(QSpace.s5),
          children: [
            Text(l10n.qazaSubtitle, style: QType.body.copyWith(color: q.ink2)),
            const SizedBox(height: QSpace.s4),
            _DateTile(
              label: l10n.qazaStartDate,
              valueText: _startDate == null
                  ? l10n.qazaSelectDate
                  : _formatDate(context, _startDate!),
              hasValue: _startDate != null,
              onTap: () => _pickDate(isStart: true),
            ),
            const SizedBox(height: QSpace.s3),
            _DateTile(
              label: l10n.qazaEndDate,
              valueText: _endDate == null
                  ? l10n.qazaSelectDate
                  : _formatDate(context, _endDate!),
              hasValue: _endDate != null,
              onTap: () => _pickDate(isStart: false),
            ),
            const SizedBox(height: QSpace.s3),
            QCard(
              padding: EdgeInsets.zero,
              child: Material(
                type: MaterialType.transparency,
                child: SwitchListTile.adaptive(
                  value: _includeWitr,
                  // Any input change clears the result, so it never shows
                  // numbers from different inputs.
                  onChanged: (v) => setState(() {
                    _includeWitr = v;
                    _result = null;
                  }),
                  title: Text(
                    l10n.qazaIncludeWitr,
                    style: QType.body.copyWith(color: q.ink),
                  ),
                  activeThumbColor: q.primary,
                ),
              ),
            ),
            const SizedBox(height: QSpace.s3),
            TextField(
              controller: _madeUp,
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() => _result = null),
              style: QType.num_(QType.body).copyWith(color: q.ink),
              decoration: InputDecoration(labelText: l10n.qazaAlreadyMadeUp),
            ),
            const SizedBox(height: QSpace.s4),
            QButton(
              label: l10n.qazaCalculate,
              icon: Icons.calculate_outlined,
              expand: true,
              onPressed: _startDate == null || _endDate == null || _inverted
                  ? null
                  : _calculate,
            ),
            if (_inverted) ...[
              const SizedBox(height: QSpace.s3),
              QBanner(
                text: l10n.qazaEndBeforeStart,
                tone: q.warnSoft,
                foreground: q.ink,
              ),
            ],
            const SizedBox(height: QSpace.s4),
            QBanner(text: l10n.qazaNote),
            if (_result case final QazaResult result) ...[
              const SizedBox(height: QSpace.s4),
              QCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.qazaDays(_formatCount(context, result.days)),
                      style: QType.body.copyWith(color: q.ink2),
                    ),
                    const SizedBox(height: QSpace.s2),
                    Text(
                      l10n.qazaPerPrayer(
                        _formatCount(context, result.perPrayer),
                      ),
                      style: QType.body.copyWith(color: q.ink2),
                    ),
                    if (result.witr > 0) ...[
                      const SizedBox(height: QSpace.s2),
                      Text(
                        l10n.qazaWitr(_formatCount(context, result.witr)),
                        style: QType.body.copyWith(color: q.ink2),
                      ),
                    ],
                    const SizedBox(height: QSpace.s4),
                    Text(
                      l10n.qazaTotal(_formatCount(context, result.totalMissed)),
                      style: QType.num_(QType.title).copyWith(color: q.ok),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Tappable row that opens a date picker and shows the chosen date (or a
/// placeholder when none is selected yet).
final class _DateTile extends StatelessWidget {
  const _DateTile({
    required this.label,
    required this.valueText,
    required this.hasValue,
    required this.onTap,
  });

  final String label;
  final String valueText;
  final bool hasValue;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final q = context.q;
    return QCard(
      padding: EdgeInsets.zero,
      child: Material(
        type: MaterialType.transparency,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: QSpace.s4,
            vertical: QSpace.s1,
          ),
          leading: Icon(Icons.calendar_today_outlined, color: q.primary),
          title: Text(label, style: QType.label.copyWith(color: q.ink2)),
          subtitle: Text(
            valueText,
            style: QType.num_(
              QType.titleSm,
            ).copyWith(color: hasValue ? q.ink : q.ink2),
          ),
          trailing: Icon(Icons.chevron_right, color: q.ink2),
          onTap: onTap,
        ),
      ),
    );
  }
}
