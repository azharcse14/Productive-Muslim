import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/productive_muslim_tokens.dart';
import '../../../../core/theme/productive_muslim_typography.dart';
import '../../../../core/utils/locale_digits.dart';
import '../../../../shared/extensions/context_ext.dart';
import '../../../../shared/widgets/q_banner.dart';
import '../../../../shared/widgets/q_button.dart';
import '../../../../shared/widgets/q_card.dart';
import '../../domain/usecases/inheritance_calculator.dart';

/// Spouse selection for the form.
enum _Spouse { none, husband, wife }

/// Islamic inheritance (Faraid) calculator screen. Wraps the pure
/// [InheritanceCalculator]; estimate-only, with a prominent scholar
/// disclaimer (this covers common heirs only).
final class InheritanceScreen extends StatefulWidget {
  const InheritanceScreen({super.key});

  @override
  State<InheritanceScreen> createState() => _InheritanceScreenState();
}

final class _InheritanceScreenState extends State<InheritanceScreen> {
  final _estate = TextEditingController();

  _Spouse _spouse = _Spouse.none;
  int _wives = 1;
  bool _father = false;
  bool _mother = false;
  int _sons = 0;
  int _daughters = 0;
  int _brothers = 0;
  int _sisters = 0;

  InheritanceResult? _result;

  @override
  void dispose() {
    _estate.dispose();
    super.dispose();
  }

  void _calculate() {
    setState(() {
      _result = InheritanceCalculator.calculate(
        InheritanceInput(
          estate: double.tryParse(LocaleDigits.toAscii(_estate.text)) ?? 0,
          hasHusband: _spouse == _Spouse.husband,
          wives: _spouse == _Spouse.wife ? _wives : 0,
          hasFather: _father,
          hasMother: _mother,
          sons: _sons,
          daughters: _daughters,
          fullBrothers: _brothers,
          fullSisters: _sisters,
        ),
      );
    });
  }

  String _money(BuildContext context, double amount) {
    final locale = Localizations.localeOf(context);
    return LocaleDigits.localize(
      NumberFormat.decimalPattern(locale.toString()).format(amount),
      locale.languageCode,
    );
  }

  String _heirName(BuildContext context, String key) {
    final l10n = context.l10n;
    return switch (key) {
      'husband' => l10n.faraidHeirHusband,
      'wife' => l10n.faraidHeirWife,
      'father' => l10n.faraidHeirFather,
      'mother' => l10n.faraidHeirMother,
      'son' => l10n.faraidHeirSon,
      'daughter' => l10n.faraidHeirDaughter,
      'brother' => l10n.faraidHeirBrother,
      'sister' => l10n.faraidHeirSister,
      _ => key,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final q = context.q;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.faraidTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(QSpace.s5),
          children: [
            Text(
              l10n.faraidSubtitle,
              style: QType.body.copyWith(color: q.ink2),
            ),
            const SizedBox(height: QSpace.s4),

            // Estate value.
            TextField(
              controller: _estate,
              keyboardType: TextInputType.number,
              style: QType.num_(QType.body).copyWith(color: q.ink),
              decoration: InputDecoration(labelText: l10n.faraidEstate),
            ),
            const SizedBox(height: QSpace.s4),

            // Spouse selector.
            Text(l10n.faraidSpouse, style: QType.label.copyWith(color: q.ink2)),
            const SizedBox(height: QSpace.s2),
            SegmentedButton<_Spouse>(
              segments: [
                ButtonSegment(
                  value: _Spouse.none,
                  label: Text(l10n.faraidNone),
                ),
                ButtonSegment(
                  value: _Spouse.husband,
                  label: Text(l10n.faraidHusband),
                ),
                ButtonSegment(
                  value: _Spouse.wife,
                  label: Text(l10n.faraidWife),
                ),
              ],
              selected: {_spouse},
              onSelectionChanged: (s) => setState(() => _spouse = s.first),
            ),
            if (_spouse == _Spouse.wife) ...[
              const SizedBox(height: QSpace.s3),
              _Stepper(
                label: l10n.faraidWives,
                value: _wives,
                min: 1,
                max: 4,
                onChanged: (v) => setState(() => _wives = v),
              ),
            ],
            const SizedBox(height: QSpace.s4),

            // Parent toggles.
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.faraidFather, style: QType.body),
              value: _father,
              onChanged: (v) => setState(() => _father = v),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.faraidMother, style: QType.body),
              value: _mother,
              onChanged: (v) => setState(() => _mother = v),
            ),
            const SizedBox(height: QSpace.s2),

            // Count steppers.
            _Stepper(
              label: l10n.faraidSons,
              value: _sons,
              onChanged: (v) => setState(() => _sons = v),
            ),
            const SizedBox(height: QSpace.s2),
            _Stepper(
              label: l10n.faraidDaughters,
              value: _daughters,
              onChanged: (v) => setState(() => _daughters = v),
            ),
            const SizedBox(height: QSpace.s2),
            _Stepper(
              label: l10n.faraidBrothers,
              value: _brothers,
              onChanged: (v) => setState(() => _brothers = v),
            ),
            const SizedBox(height: QSpace.s2),
            _Stepper(
              label: l10n.faraidSisters,
              value: _sisters,
              onChanged: (v) => setState(() => _sisters = v),
            ),
            const SizedBox(height: QSpace.s4),

            QButton(
              label: l10n.faraidCalculate,
              icon: Icons.calculate_outlined,
              expand: true,
              onPressed: _calculate,
            ),

            if (_result case final InheritanceResult result) ...[
              const SizedBox(height: QSpace.s4),
              QCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final s in result.shares)
                      Padding(
                        padding: const EdgeInsets.only(bottom: QSpace.s3),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                s.heirKey == 'unallocated'
                                    ? l10n.faraidUnallocated(
                                        _money(context, s.amount),
                                      )
                                    : '${_heirName(context, s.heirKey)}'
                                          '${s.count > 1 ? ' ×${s.count}' : ''}'
                                          ' · ${s.shareLabel}',
                                style: QType.body.copyWith(color: q.ink),
                              ),
                            ),
                            if (s.heirKey != 'unallocated') ...[
                              const SizedBox(width: QSpace.s3),
                              Text(
                                _money(context, s.amount),
                                style: QType.num_(
                                  QType.titleSm,
                                ).copyWith(color: q.ink),
                              ),
                            ],
                          ],
                        ),
                      ),
                    if (result.isAwl)
                      QBanner(
                        text: l10n.faraidAwlNote,
                        tone: q.warnSoft,
                        foreground: q.ink,
                      ),
                    if (result.isRadd)
                      QBanner(
                        text: l10n.faraidRaddNote,
                        tone: q.primarySoft,
                        foreground: q.onPrimarySoft,
                      ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: QSpace.s4),
            QBanner(
              text: l10n.faraidDisclaimer,
              icon: Icons.warning_amber_rounded,
              tone: q.warnSoft,
              foreground: q.ink,
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact label + [-] value [+] stepper, value clamped to [min]..[max].
final class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.label,
    required this.value,
    required this.onChanged,
    this.min = 0,
    this.max = 20,
  });

  final String label;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final q = context.q;
    return Row(
      children: [
        Expanded(
          child: Text(label, style: QType.body.copyWith(color: q.ink)),
        ),
        IconButton(
          icon: const Icon(Icons.remove_circle_outline),
          tooltip: context.l10n.a11yDecrease(label),
          onPressed: value > min ? () => onChanged(value - 1) : null,
        ),
        Text(
          LocaleDigits.localize(
            '$value',
            Localizations.localeOf(context).languageCode,
          ),
          style: QType.num_(QType.titleSm).copyWith(color: q.ink),
        ),
        IconButton(
          icon: const Icon(Icons.add_circle_outline),
          tooltip: context.l10n.a11yIncrease(label),
          onPressed: value < max ? () => onChanged(value + 1) : null,
        ),
      ],
    );
  }
}
