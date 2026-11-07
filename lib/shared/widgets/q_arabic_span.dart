import 'package:flutter/painting.dart';

import '../../config/assets.dart';

const _arabicComma = '،';

/// [text] in [style] (the Hafs font), with every U+060C ARABIC COMMA drawn
/// in the UI Arabic font instead: UthmanicHafs maps U+060C to a dotted
/// circle, and `fontFamilyFallback` can't help because the glyph exists.
/// For dua, ruqyah and hadith Arabic — Quran text has no Arabic commas.
TextSpan hafsSpan(String text, TextStyle style) {
  if (!text.contains(_arabicComma)) return TextSpan(text: text, style: style);
  final commaStyle = style.copyWith(fontFamily: AppFonts.arabicUi);
  final parts = text.split(_arabicComma);
  return TextSpan(
    style: style,
    children: [
      for (var i = 0; i < parts.length; i++) ...[
        if (i > 0) TextSpan(text: _arabicComma, style: commaStyle),
        if (parts[i].isNotEmpty) TextSpan(text: parts[i]),
      ],
    ],
  );
}
