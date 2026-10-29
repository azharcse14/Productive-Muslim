import 'package:flutter_test/flutter_test.dart';
import 'package:productive_muslim/core/utils/locale_digits.dart';

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

  group('LocaleDigits.toAscii', () {
    test('maps Bengali and Arabic-Indic digits, strips separators', () {
      expect(LocaleDigits.toAscii('১২,৫০০'), '12500');
      expect(LocaleDigits.toAscii(' ١٬٢٣٤٫٥ '), '1234.5');
      expect(LocaleDigits.toAscii('۱۲۳'), '123');
      expect(double.tryParse(LocaleDigits.toAscii('1,234.50')), 1234.5);
    });

    test('a lone comma not followed by 3 digits is a decimal comma', () {
      expect(double.tryParse(LocaleDigits.toAscii('12,5')), 12.5);
      expect(double.tryParse(LocaleDigits.toAscii('০,৭৫')), 0.75);
      expect(LocaleDigits.toAscii('1,000'), '1000');
      expect(LocaleDigits.toAscii('1,00,000'), '100000');
      expect(int.tryParse(LocaleDigits.toAscii('12,5')), isNull);
    });

    test('round-trips localize', () {
      expect(LocaleDigits.toAscii(LocaleDigits.localize('9876', 'bn')), '9876');
    });
  });
}
