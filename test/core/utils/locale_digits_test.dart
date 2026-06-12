import 'package:flutter_test/flutter_test.dart';
import 'package:qalbee/core/utils/locale_digits.dart';

void main() {
  group('LocaleDigits.localize', () {
    test('converts ASCII digits to Bengali for bn', () {
      expect(LocaleDigits.localize('0123456789', 'bn'), '০১২৩৪৫৬৭৮৯');
    });

    test('converts ASCII digits to Eastern Arabic for ar', () {
      expect(LocaleDigits.localize('0123456789', 'ar'), '٠١٢٣٤٥٦٧٨٩');
    });

    test('converts for Urdu using Eastern Arabic digits', () {
      expect(LocaleDigits.localize('12:34', 'ur'), '١٢:٣٤');
    });

    test('passes through unchanged for en', () {
      expect(LocaleDigits.localize('12:34 pm', 'en'), '12:34 pm');
    });

    test('preserves non-digit characters', () {
      expect(LocaleDigits.localize('5:41 — Fajr', 'bn'), '৫:৪১ — Fajr');
    });

    test('handles empty input', () {
      expect(LocaleDigits.localize('', 'bn'), '');
    });

    test('handles mixed scripts already present', () {
      expect(LocaleDigits.localize('৫ and 5', 'bn'), '৫ and ৫');
    });
  });
}
