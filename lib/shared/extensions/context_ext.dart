import 'package:flutter/material.dart';
import '../../core/l10n/gen/app_localizations.dart';
import '../../core/theme/productive_muslim_colors.dart';
import '../../core/utils/locale_digits.dart';

/// Convenience accessors used across all presentation code.
extension ProductiveMuslimContext on BuildContext {
  /// Productive Muslim color tokens — the only way feature widgets obtain colors.
  ProductiveMuslimColors get q =>
      Theme.of(this).extension<ProductiveMuslimColors>()!;

  TextTheme get text => Theme.of(this).textTheme;

  AppLocalizations get l10n => AppLocalizations.of(this);

  /// How much the user's text-size setting enlarges text (never below 1).
  /// Divide fixed grid aspect ratios by it so tiles grow with their text.
  double get textGrowth {
    final growth = MediaQuery.textScalerOf(this).scale(14) / 14;
    return growth < 1 ? 1 : growth;
  }

  /// [input] with its ASCII digits in the current locale's digit set.
  String digits(String input) =>
      LocaleDigits.localize(input, Localizations.localeOf(this).languageCode);
}
