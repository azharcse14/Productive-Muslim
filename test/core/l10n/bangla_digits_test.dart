import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:productive_muslim/core/l10n/gen/app_localizations.dart';

/// Every int placeholder carries `"format": "decimalPattern"`, so counts
/// render in the locale's own digits without call-site conversion.
void main() {
  test('Bangla messages use Bengali digits for counts', () async {
    final bn = await AppLocalizations.delegate.load(const Locale('bn'));
    expect(bn.minutesShort(15), '১৫ মিনিট');
    expect(bn.currentStreakLabel(12), contains('১২'));
    expect(bn.achievementsCount(3, 17), isNot(matches(RegExp('[0-9]'))));
  });

  test('English keeps Western digits', () async {
    final en = await AppLocalizations.delegate.load(const Locale('en'));
    expect(en.minutesShort(15), '15 min');
  });
}
