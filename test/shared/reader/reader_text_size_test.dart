import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:productive_muslim/core/l10n/gen/app_localizations.dart';
import 'package:productive_muslim/core/theme/app_theme.dart';
import 'package:productive_muslim/shared/reader/reader_settings_sheet.dart';
import 'package:productive_muslim/shared/reader/reader_text_size.dart';

ReaderTextSize _failing() =>
    ReaderTextSize(write: (_) async => throw PlatformException(code: 'prefs'));

void main() {
  test('a failed write reports false but keeps the size', () async {
    final textSize = _failing();
    expect(await textSize.set(32), isFalse);
    expect(textSize.size.value, 32);
    expect(await ReaderTextSize().set(30), isTrue);
  });

  testWidgets('the sheet tells the user when the size was not saved', (
    tester,
  ) async {
    final textSize = _failing();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ReaderTextSizeScope(
          textSize: textSize,
          child: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => unawaited(showReaderSettingsSheet(context)),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(Slider), const Offset(100, 0));
    await tester.pumpAndSettle();
    expect(find.text("Couldn't save. Please try again."), findsOneWidget);
  });
}
