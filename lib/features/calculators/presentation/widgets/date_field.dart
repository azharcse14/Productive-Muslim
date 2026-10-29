import 'package:flutter/material.dart';

import '../../../../core/theme/productive_muslim_tokens.dart';
import '../../../../core/theme/productive_muslim_typography.dart';
import '../../../../shared/extensions/context_ext.dart';

/// Tappable, read-only field that opens a date picker. Uses the theme's
/// input decoration so it sits naturally beside the form's [TextField]s.
final class DateField extends StatelessWidget {
  const DateField({
    super.key,
    required this.label,
    required this.value,
    required this.onTap,
    this.hasValue = true,
    this.helperText,
  });

  final String label;

  /// The chosen date, or a placeholder when [hasValue] is false.
  final String value;
  final bool hasValue;
  final String? helperText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final q = context.q;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(QRadius.md),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          helperText: helperText,
          helperMaxLines: 2,
          suffixIcon: Icon(Icons.calendar_today_outlined, color: q.ink2),
        ),
        child: Text(
          value,
          style: QType.num_(
            QType.body,
          ).copyWith(color: hasValue ? q.ink : q.ink2),
        ),
      ),
    );
  }
}
