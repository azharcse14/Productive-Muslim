import 'package:flutter/material.dart';

import '../../core/l10n/gen/app_localizations.dart';
import '../../core/theme/qalbee_colors.dart';

/// Convenience accessors used across all presentation code.
extension QalbeeContext on BuildContext {
  /// Qalbee color tokens — the only way feature widgets obtain colors.
  QalbeeColors get q => Theme.of(this).extension<QalbeeColors>()!;

  TextTheme get text => Theme.of(this).textTheme;

  AppLocalizations get l10n => AppLocalizations.of(this);
}
