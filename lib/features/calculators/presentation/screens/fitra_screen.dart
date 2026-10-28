import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/productive_muslim_tokens.dart';
import '../../../../core/theme/productive_muslim_typography.dart';
import '../../../../core/utils/locale_digits.dart';
import '../../../../shared/extensions/context_ext.dart';
import '../../../../shared/widgets/q_banner.dart';
import '../../../../shared/widgets/q_button.dart';
import '../../../../shared/widgets/q_card.dart';
import '../../domain/usecases/fitra_calculator.dart';

/// Sadaqatul Fitr (Fitra) calculator: pick a staple, enter the local price
/// per kg and the household size over the pure [FitraCalculator].
final class FitraScreen extends StatefulWidget {
  const FitraScreen({super.key});

  @override
  State<FitraScreen> createState() => _FitraScreenState();
}

final class _FitraScreenState extends State<FitraScreen> {
  final _price = TextEditingController();
  final _people = TextEditingController(text: '1');

  FitraStaple _staple = FitraStaple.wheat;
  FitraResult? _result;

  /// Fields whose non-empty text didn't parse; shown as field errors.
  Set<TextEditingController> _invalid = {};

  @override
  void dispose() {
    _price.dispose();
    _people.dispose();
    super.dispose();
  }

  /// Drops the result on any input change, so it never shows numbers for
  /// different inputs.
  void _edit(VoidCallback change) => setState(() {
    change();
    _result = null;
    _invalid = {};
  });

  void _calculate() {
    final priceText = LocaleDigits.toAscii(_price.text).trim();
    final peopleText = LocaleDigits.toAscii(_people.text).trim();
    final price = double.tryParse(priceText);
    final people = int.tryParse(peopleText);
    setState(() {
      _invalid = {
        if (priceText.isNotEmpty && (price == null || !price.isFinite)) _price,
        if (peopleText.isNotEmpty && people == null) _people,
      };
      if (_invalid.isNotEmpty) {
        _result = null;
        return;
      }
      _result = FitraCalculator.calculate(
        FitraInput(
          staple: _staple,
          pricePerKg: price ?? 0,
          numberOfPeople: people ?? 0,
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

  String _stapleLabel(BuildContext context, FitraStaple staple) {
    final l10n = context.l10n;
    return switch (staple) {
      FitraStaple.wheat || FitraStaple.flour => l10n.fitraStapleWheat,
      FitraStaple.barley => l10n.fitraStapleBarley,
      FitraStaple.dates => l10n.fitraStapleDates,
      FitraStaple.raisins => l10n.fitraStapleRaisins,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final q = context.q;
    // Wheat and flour share a label/weight, so we offer one entry for them.
    const staples = [
      FitraStaple.wheat,
      FitraStaple.barley,
      FitraStaple.dates,
      FitraStaple.raisins,
    ];
    return Scaffold(
      appBar: AppBar(title: Text(l10n.fitraTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(QSpace.s5),
          children: [
            Text(
              l10n.fitraSubtitle,
              style: QType.body.copyWith(color: q.ink2),
            ),
            const SizedBox(height: QSpace.s4),
            QBanner(text: l10n.fitraBeforeEid),
            const SizedBox(height: QSpace.s4),
            DropdownButtonFormField<FitraStaple>(
              initialValue: _staple,
              decoration: InputDecoration(labelText: l10n.fitraStaple),
              style: QType.num_(QType.body).copyWith(color: q.ink),
              items: [
                for (final staple in staples)
                  DropdownMenuItem(
                    value: staple,
                    child: Text(_stapleLabel(context, staple)),
                  ),
              ],
              onChanged: (value) {
                if (value != null) _edit(() => _staple = value);
              },
            ),
            const SizedBox(height: QSpace.s3),
            TextField(
              controller: _price,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              onChanged: (_) => _edit(() {}),
              style: QType.num_(QType.body).copyWith(color: q.ink),
              decoration: InputDecoration(
                labelText: l10n.fitraPricePerKg,
                errorText: _invalid.contains(_price)
                    ? l10n.fitraInvalidNumber
                    : null,
              ),
            ),
            const SizedBox(height: QSpace.s3),
            TextField(
              controller: _people,
              keyboardType: TextInputType.number,
              onChanged: (_) => _edit(() {}),
              style: QType.num_(QType.body).copyWith(color: q.ink),
              decoration: InputDecoration(
                labelText: l10n.fitraPeople,
                errorText: _invalid.contains(_people)
                    ? l10n.fitraInvalidNumber
                    : null,
              ),
            ),
            const SizedBox(height: QSpace.s4),
            QButton(
              label: l10n.fitraCalculate,
              icon: Icons.calculate_outlined,
              expand: true,
              onPressed: _calculate,
            ),
            if (_result case final FitraResult result) ...[
              const SizedBox(height: QSpace.s4),
              QCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.fitraPerPerson(
                        _formatAmount(context, result.perPersonAmount),
                      ),
                      style: QType.body.copyWith(color: q.ink2),
                    ),
                    const SizedBox(height: QSpace.s3),
                    Text(
                      l10n.fitraTotal(
                        _formatAmount(context, result.totalAmount),
                      ),
                      style: QType.num_(QType.title).copyWith(color: q.ok),
                    ),
                    const SizedBox(height: QSpace.s3),
                    Text(
                      l10n.fitraWeightNote(
                        _formatAmount(context, result.weightKgPerPerson),
                      ),
                      style: QType.caption.copyWith(color: q.ink2),
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
