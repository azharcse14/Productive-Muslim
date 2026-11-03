import 'package:flutter_test/flutter_test.dart';
import 'package:productive_muslim/features/quran/domain/entities/ayah.dart';

Ayah _ayah({String bn = 'বাংলা'}) => Ayah(
  id: 1,
  surah: 1,
  number: 1,
  arabic: 'ع',
  translationEn: 'English',
  translationBn: bn,
);

void main() {
  test('Bangla UI gets the Bangla translation, credited as bn', () {
    expect(_ayah().translationFor('bn'), 'বাংলা');
    expect(_ayah().translationLanguageFor('bn'), 'bn');
  });

  test(
    'a missing Bangla translation falls back to English, credited as en',
    () {
      expect(_ayah(bn: '').translationFor('bn'), 'English');
      expect(_ayah(bn: '').translationLanguageFor('bn'), 'en');
    },
  );

  test('any other UI language gets English', () {
    expect(_ayah().translationFor('en'), 'English');
    expect(_ayah().translationLanguageFor('ar'), 'en');
  });
}
