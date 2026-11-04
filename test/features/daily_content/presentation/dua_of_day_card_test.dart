import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:productive_muslim/core/l10n/gen/app_localizations.dart';
import 'package:productive_muslim/core/theme/app_theme.dart';
import 'package:productive_muslim/features/daily_content/presentation/widgets/dua_of_day_card.dart';
import 'package:productive_muslim/shared/reader/reader_text_size.dart';

void main() {
  testWidgets('the reference uses Bangla digits in Bangla', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('bn'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) =>
            ReaderTextSizeScope(textSize: ReaderTextSize(), child: child!),
        home: const Scaffold(
          body: DuaOfDayCard(
            arabic: 'بِسْمِ اللَّهِ',
            translation: 'আল্লাহর নামে',
            reference: 'Muslim 2723',
          ),
        ),
      ),
    );
    expect(find.text('Muslim ২৭২৩'), findsOneWidget);
  });
}
