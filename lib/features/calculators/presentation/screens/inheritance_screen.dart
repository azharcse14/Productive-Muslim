import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/productive_muslim_tokens.dart';
import '../../../../core/theme/productive_muslim_typography.dart';
import '../../../../core/utils/locale_digits.dart';
import '../../../../shared/extensions/context_ext.dart';
import '../../../../shared/widgets/q_banner.dart';
import '../../../../shared/widgets/q_button.dart';
import '../../../../shared/widgets/q_card.dart';
import '../../../../shared/widgets/q_form.dart';
import '../../../../shared/widgets/q_seg_control.dart';
import '../../../../shared/widgets/q_step_button.dart';
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
  bool _otherRelatives = false;

  InheritanceResult? _result;
  final _resultKey = GlobalKey();

  /// The estate text didn't parse as a finite, non-negative number.
  bool _estateInvalid = false;

  @override
  void dispose() {
    _estate.dispose();
    super.dispose();
  }

  /// Applies an input change and drops the result, so it never shows a
  /// distribution for different inputs.
  void _edit(VoidCallback change) => setState(() {
    change();
    _result = null;
  });

  void _calculate() {
    FocusScope.of(context).unfocus();
    final text = LocaleDigits.toAscii(_estate.text).trim();
    final estate = double.tryParse(text);
    setState(() {
      _estateInvalid =
          text.isNotEmpty && (estate == null || !estate.isFinite || estate < 0);
      if (_estateInvalid) {
        _result = null;
        return;
      }
      _result = InheritanceCalculator.calculate(
        InheritanceInput(
          estate: estate ?? 0,
          hasHusband: _spouse == _Spouse.husband,
          wives: _spouse == _Spouse.wife ? _wives : 0,
          hasFather: _father,
          hasMother: _mother,
          sons: _sons,
          daughters: _daughters,
          fullBrothers: _brothers,
          fullSisters: _sisters,
          hasOtherRelatives: _otherRelatives,
        ),
      );
    });
    if (_result != null) {
      revealAfterFrame(context, _resultKey);
    }
  }

  String _basisLabel(BuildContext context, ShareBasis basis) {
    final l10n = context.l10n;
    return switch (basis) {
      ShareBasis.half => '1/2',
      ShareBasis.quarter => '1/4',
      ShareBasis.eighth => '1/8',
      ShareBasis.sixth => '1/6',
      ShareBasis.third => '1/3',
      ShareBasis.twoThirdsShared => l10n.faraidBasisTwoThirdsShared,
      ShareBasis.thirdOfResidue => l10n.faraidBasisThirdOfResidue,
      ShareBasis.residuary => l10n.faraidBasisResiduary,
      ShareBasis.sixthPlusResiduary => l10n.faraidBasisSixthPlusResiduary,
      ShareBasis.residuaryTwoToOne => l10n.faraidBasisResiduaryTwoToOne,
      ShareBasis.unallocated => '',
    };
  }

  String _money(BuildContext context, double amount) {
    final locale = Localizations.localeOf(context);
    return LocaleDigits.localize(
      (NumberFormat.decimalPattern(
        locale.toString(),
      )..maximumFractionDigits = 2).format(amount),
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
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
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
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: QInputFormat.decimal,
              textInputAction: TextInputAction.done,
              onTapOutside: unfocusOnTapOutside,
              onChanged: (_) => _edit(() => _estateInvalid = false),
              style: QType.num_(QType.body).copyWith(color: q.ink),
              decoration: InputDecoration(
                labelText: l10n.faraidEstate,
                helperText: l10n.faraidEstateHelper,
                helperMaxLines: 2,
                errorText: _estateInvalid ? l10n.faraidInvalidNumber : null,
              ),
            ),
            const SizedBox(height: QSpace.s4),

            // Spouse selector.
            Text(l10n.faraidSpouse, style: QType.label.copyWith(color: q.ink2)),
            const SizedBox(height: QSpace.s2),
            QSegControl(
              options: [l10n.faraidNone, l10n.faraidHusband, l10n.faraidWife],
              activeIndex: _spouse.index,
              onChanged: (i) => _edit(() => _spouse = _Spouse.values[i]),
            ),
            if (_spouse == _Spouse.wife) ...[
              const SizedBox(height: QSpace.s3),
              _Stepper(
                label: l10n.faraidWives,
                value: _wives,
                min: 1,
                max: 4,
                onChanged: (v) => _edit(() => _wives = v),
              ),
            ],
            const SizedBox(height: QSpace.s4),

            // Parent toggles.
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.faraidFather, style: QType.body),
              value: _father,
              onChanged: (v) => _edit(() => _father = v),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.faraidMother, style: QType.body),
              value: _mother,
              onChanged: (v) => _edit(() => _mother = v),
            ),
            const SizedBox(height: QSpace.s2),

            // Count steppers.
            _Stepper(
              label: l10n.faraidSons,
              value: _sons,
              onChanged: (v) => _edit(() => _sons = v),
            ),
            const SizedBox(height: QSpace.s2),
            _Stepper(
              label: l10n.faraidDaughters,
              value: _daughters,
              onChanged: (v) => _edit(() => _daughters = v),
            ),
            const SizedBox(height: QSpace.s2),
            _Stepper(
              label: l10n.faraidBrothers,
              value: _brothers,
              onChanged: (v) => _edit(() => _brothers = v),
            ),
            const SizedBox(height: QSpace.s2),
            _Stepper(
              label: l10n.faraidSisters,
              value: _sisters,
              onChanged: (v) => _edit(() => _sisters = v),
            ),
            const SizedBox(height: QSpace.s2),
            // Out-of-scope heirs: answering yes skips the distribution
            // rather than give a wrong radd / "unallocated" answer.
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.faraidOtherRelatives, style: QType.body),
              value: _otherRelatives,
              onChanged: (v) => _edit(() => _otherRelatives = v),
            ),
            const SizedBox(height: QSpace.s4),

            QButton(
              label: l10n.faraidCalculate,
              icon: Icons.calculate_outlined,
              expand: true,
              onPressed: _calculate,
            ),

            if (_result case final InheritanceResult result
                when result.outOfScope) ...[
              const SizedBox(height: QSpace.s4),
              QBanner(
                key: _resultKey,
                text: l10n.faraidOutOfScope,
                tone: q.warnSoft,
                foreground: q.ink,
              ),
            ] else if (_result case final InheritanceResult result) ...[
              const SizedBox(height: QSpace.s4),
              QCard(
                key: _resultKey,
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
                                    : context.digits(
                                        '${_heirName(context, s.heirKey)}'
                                        '${s.count > 1 ? ' ×${s.count}' : ''}'
                                        ' · ${_basisLabel(context, s.basis)}',
                                      ),
                                style: QType.body.copyWith(color: q.ink),
                              ),
                            ),
                            if (s.heirKey != 'unallocated') ...[
                              const SizedBox(width: QSpace.s3),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    _money(context, s.amount),
                                    style: QType.num_(
                                      QType.titleSm,
                                    ).copyWith(color: q.ink),
                                  ),
                                  if (s.count > 1)
                                    Text(
                                      l10n.faraidPerHead(
                                        _money(context, s.amount / s.count),
                                      ),
                                      style: QType.num_(
                                        QType.caption,
                                      ).copyWith(color: q.ink2),
                                    ),
                                ],
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
                    if (result.note == 'umariyyatayn')
                      QBanner(
                        text: l10n.faraidUmariyyataynNote,
                        tone: q.primarySoft,
                        foreground: q.onPrimarySoft,
                      ),
                    if (result.note == 'unallocated')
                      QBanner(
                        text: l10n.faraidUnallocatedNote,
                        tone: q.warnSoft,
                        foreground: q.ink,
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

/// Label + [QStepButton] −/+ pair, value clamped to [min]..[max].
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
        QStepButton(
          icon: Icons.remove,
          semanticLabel: context.l10n.a11yDecrease(label),
          fill: q.surface2,
          onTap: value > min ? () => onChanged(value - 1) : null,
        ),
        ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 32),
          child: Text(
            LocaleDigits.localize(
              '$value',
              Localizations.localeOf(context).languageCode,
            ),
            textAlign: TextAlign.center,
            style: QType.num_(QType.titleSm).copyWith(color: q.ink),
          ),
        ),
        QStepButton(
          icon: Icons.add,
          semanticLabel: context.l10n.a11yIncrease(label),
          fill: q.surface2,
          onTap: value < max ? () => onChanged(value + 1) : null,
        ),
      ],
    );
  }
}
