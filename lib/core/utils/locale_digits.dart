/// Per-locale digit rendering (design: Western 123 / Bengali ১২৩ /
/// Eastern Arabic ١٢٣). Use for any user-facing number or time string.
abstract final class LocaleDigits {
  static const _bengali = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];
  static const _easternArabic = [
    '٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩', //
  ];

  /// Converts ASCII digits in [input] to the digit set of [languageCode].
  /// Unknown locales pass through unchanged (Western digits).
  static String localize(String input, String languageCode) {
    final digits = switch (languageCode) {
      'bn' => _bengali,
      'ar' || 'ur' => _easternArabic,
      _ => null,
    };
    if (digits == null) {
      return input;
    }
    final buffer = StringBuffer();
    for (final code in input.codeUnits) {
      if (code >= 0x30 && code <= 0x39) {
        buffer.write(digits[code - 0x30]);
      } else {
        buffer.writeCharCode(code);
      }
    }
    return buffer.toString();
  }

  /// Inverse of [localize] for parsing user input: maps Bengali (০-৯),
  /// Arabic-Indic (٠-٩) and Extended Arabic-Indic (۰-۹) digits to ASCII,
  /// the Arabic decimal separator (٫) to '.', and strips thousands
  /// separators ('٬' and whitespace). Then ',' versus '.':
  /// - both present: whichever comes last is the decimal separator and the
  ///   other is grouping ("1,234.50" → 1234.50, "1.000,50" → 1000.50);
  /// - several commas: grouping ("1,00,000" → 100000);
  /// - one comma: grouping only in the "1,000" shape (non-zero integer part
  ///   of 1–3 digits, exactly 3 digits after); otherwise a decimal comma
  ///   ("12,5", "0,500", ",500").
  /// Feed the result to `double.tryParse` / `int.tryParse`.
  static String toAscii(String input) {
    final buffer = StringBuffer();
    for (final rune in input.runes) {
      if (rune >= 0x09E6 && rune <= 0x09EF) {
        buffer.writeCharCode(0x30 + rune - 0x09E6);
      } else if (rune >= 0x0660 && rune <= 0x0669) {
        buffer.writeCharCode(0x30 + rune - 0x0660);
      } else if (rune >= 0x06F0 && rune <= 0x06F9) {
        buffer.writeCharCode(0x30 + rune - 0x06F0);
      } else if (rune == 0x066B) {
        buffer.write('.');
      } else if (rune == 0x066C || _isSpace(rune)) {
        continue;
      } else {
        buffer.writeCharCode(rune);
      }
    }
    final out = buffer.toString();
    final comma = out.lastIndexOf(',');
    if (comma == -1) return out;
    final dot = out.lastIndexOf('.');
    final decimalComma = dot != -1
        ? comma > dot
        : comma == out.indexOf(',') && !_thousands.hasMatch(out);
    if (!decimalComma) return out.replaceAll(',', '');
    return '${out.substring(0, comma).replaceAll(RegExp('[.,]'), '')}'
        '.${out.substring(comma + 1)}';
  }

  /// A lone comma that reads as grouping: "1,000" but not "0,500".
  static final _thousands = RegExp(r'^[-+]?[1-9]\d{0,2},\d{3}$');

  static bool _isSpace(int rune) => String.fromCharCode(rune).trim().isEmpty;
}
