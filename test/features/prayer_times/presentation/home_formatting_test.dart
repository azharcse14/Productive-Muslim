import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:productive_muslim/core/l10n/gen/app_localizations.dart';
import 'package:productive_muslim/features/prayer_times/presentation/screens/home_formatting.dart';

void main() {
  test(
    'spokenDuration speaks seconds in the last minute, not "0 minutes"',
    () async {
      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      expect(spokenDuration(l10n, const Duration(seconds: 42)), '42 seconds');
      expect(spokenDuration(l10n, const Duration(seconds: 1)), '1 second');
      expect(
        spokenDuration(l10n, const Duration(minutes: 5, seconds: 9)),
        '5 minutes',
      );
      expect(
        spokenDuration(
          l10n,
          const Duration(hours: 1, minutes: 24, seconds: 36),
        ),
        '1 hour 24 minutes',
      );
    },
  );
}
