import 'package:flutter/material.dart';

import '../../../../core/theme/productive_muslim_typography.dart';
import '../../../../core/utils/locale_digits.dart';
import '../../../../shared/extensions/context_ext.dart';
import '../../../../shared/painters/qalb_mark.dart';

/// Star8 medallion holding a surah/ayah number (design: list medallions —
/// the motif is never rotated off-axis, number digits follow the locale).
final class AyahMedallion extends StatelessWidget {
  const AyahMedallion({required this.number, this.size = 40, super.key});

  final int number;
  final double size;

  @override
  Widget build(BuildContext context) {
    final q = context.q;
    final label = LocaleDigits.localize(
      '$number',
      Localizations.localeOf(context).languageCode,
    );
    return SizedBox.square(
      dimension: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Star8(color: q.primary, size: size),
          Text(
            label,
            style: QType.num_(QType.caption).copyWith(color: q.ink),
          ),
        ],
      ),
    );
  }
}
