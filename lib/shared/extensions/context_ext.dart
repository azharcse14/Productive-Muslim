import 'package:flutter/material.dart';
import '../../core/l10n/gen/app_localizations.dart';
import '../../core/theme/productive_muslim_colors.dart';

/// Convenience accessors used across all presentation code.
extension ProductiveMuslimContext on BuildContext {
  /// Productive Muslim color tokens — the only way feature widgets obtain colors.
  ProductiveMuslimColors get q => Theme.of(this).extension<ProductiveMuslimColors>()!;

  TextTheme get text => Theme.of(this).textTheme;

  AppLocalizations get l10n => AppLocalizations.of(this);
}
