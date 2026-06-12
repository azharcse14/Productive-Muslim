import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/qalbee_tokens.dart';
import '../../../../core/theme/qalbee_typography.dart';
import '../../../../core/utils/locale_digits.dart';
import '../../../../shared/extensions/context_ext.dart';
import '../../../../shared/widgets/q_banner.dart';
import '../../../../shared/widgets/q_button.dart';
import '../../../../shared/widgets/q_card.dart';
import '../../domain/usecases/zakat_calculator.dart';

/// Zakat calculator (design §4.x): wealth + metal-price form over the pure
/// [ZakatCalculator]. Below-nisab is a neutral outcome, never an alarm.
final class ZakatScreen extends StatefulWidget {
  const ZakatScreen({super.key});

  @override
  State<ZakatScreen> createState() => _ZakatScreenState();
}

final class _ZakatScreenState extends State<ZakatScreen> {
  final _cash = TextEditingController();
  final _bank = TextEditingController();
  final _gold = TextEditingController();
  final _silver = TextEditingController();
  final _business = TextEditingController();
  final _investments = TextEditingController();
  final _owed = TextEditingController();
  final _debts = TextEditingController();
  final _goldPrice = TextEditingController();
  final _silverPrice = TextEditingController();

  ZakatResult? _result;

  @override
  void dispose() {
    for (final controller in [
      _cash,
      _bank,
      _gold,
      _silver,
      _business,
      _investments,
      _owed,
      _debts,
      _goldPrice,
      _silverPrice,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  double _valueOf(TextEditingController controller) =>
      double.tryParse(controller.text.trim()) ?? 0;

  void _calculate() {
    setState(() {
      _result = ZakatCalculator.calculate(
        ZakatInput(
          cashOnHand: _valueOf(_cash),
          bankBalance: _valueOf(_bank),
          goldGrams: _valueOf(_gold),
          silverGrams: _valueOf(_silver),
          businessAssets: _valueOf(_business),
          investments: _valueOf(_investments),
          moneyOwedToYou: _valueOf(_owed),
          debts: _valueOf(_debts),
          goldPricePerGram: _valueOf(_goldPrice),
          silverPricePerGram: _valueOf(_silverPrice),
        ),
      );
    });
  }

  String _formatAmount(BuildContext context, double amount) {
    final locale = Localizations.localeOf(context);
    return LocaleDigits.localize(
      NumberFormat.decimalPattern(locale.toString()).format(amount),
      locale.languageCode,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final q = context.q;
    final fields = <(String, TextEditingController)>[
      (l10n.zakatCash, _cash),
      (l10n.zakatBank, _bank),
      (l10n.zakatGold, _gold),
      (l10n.zakatSilver, _silver),
      (l10n.zakatBusiness, _business),
      (l10n.zakatInvestments, _investments),
      (l10n.zakatOwed, _owed),
      (l10n.zakatDebts, _debts),
      (l10n.zakatGoldPrice, _goldPrice),
      (l10n.zakatSilverPrice, _silverPrice),
    ];
    return Scaffold(
      appBar: AppBar(title: Text(l10n.zakatTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(QSpace.s5),
          children: [
            for (final (label, controller) in fields)
              Padding(
                padding: const EdgeInsets.only(bottom: QSpace.s3),
                child: TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  style: QType.num_(QType.body).copyWith(color: q.ink),
                  decoration: InputDecoration(labelText: label),
                ),
              ),
            const SizedBox(height: QSpace.s2),
            QButton(
              label: l10n.zakatCalculate,
              icon: Icons.calculate_outlined,
              expand: true,
              onPressed: _calculate,
            ),
            if (_result case final ZakatResult result) ...[
              const SizedBox(height: QSpace.s4),
              QCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.zakatNisab(
                        _formatAmount(context, result.nisabThreshold),
                      ),
                      style: QType.body.copyWith(color: q.ink2),
                    ),
                    const SizedBox(height: QSpace.s3),
                    if (result.isPayable)
                      Text(
                        l10n.zakatDue(
                          _formatAmount(context, result.zakatDue),
                        ),
                        style:
                            QType.num_(QType.title).copyWith(color: q.ok),
                      )
                    else
                      // Neutral tone on purpose: being below nisab is not
                      // a failure state.
                      QBanner(
                        text: l10n.zakatNotPayable,
                        tone: q.primarySoft,
                        foreground: q.onPrimarySoft,
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
