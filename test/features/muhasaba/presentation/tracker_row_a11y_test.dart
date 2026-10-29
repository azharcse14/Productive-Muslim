import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:productive_muslim/core/l10n/gen/app_localizations.dart';
import 'package:productive_muslim/core/theme/app_theme.dart';
import 'package:productive_muslim/features/muhasaba/domain/entities/tracker_item.dart';
import 'package:productive_muslim/features/muhasaba/presentation/widgets/tracker_row.dart';

Widget _wrap(Widget child) => MaterialApp(
  theme: AppTheme.light(),
  locale: const Locale('en'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: child),
);

const _countItem = TrackerItem(
  id: 'custom_1',
  name: 'Sadaqah',
  kind: TrackerKind.count,
  icon: 'heart',
);

void main() {
  group('a11y — TrackerRow controls are labelled', () {
    testWidgets('count stepper +/- buttons name the item they change', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _wrap(
          TrackerRow(
            item: _countItem,
            value: 2,
            displayName: 'Sadaqah',
            onChanged: (_) {},
          ),
        ),
      );
      expect(find.bySemanticsLabel('Increase Sadaqah'), findsOneWidget);
      expect(find.bySemanticsLabel('Decrease Sadaqah'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('a yes/no item exposes a labelled switch', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _wrap(
          TrackerRow(
            item: const TrackerItem(
              id: 'custom_2',
              name: 'Tahajjud',
              kind: TrackerKind.yesNo,
              icon: 'moon',
              colorIndex: 1,
            ),
            value: 0,
            displayName: 'Tahajjud',
            onChanged: (_) {},
          ),
        ),
      );
      expect(
        tester.getSemantics(find.byType(Switch)),
        isSemantics(label: 'Tahajjud', isToggled: false),
      );
      handle.dispose();
    });
  });

  testWidgets('reaching the daily target adds a firmer buzz', (tester) async {
    final buzzes = <Object?>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'HapticFeedback.vibrate') {
          buzzes.add(call.arguments);
        }
        return null;
      },
    );
    await tester.pumpWidget(
      _wrap(
        TrackerRow(
          item: const TrackerItem(
            id: 'custom_3',
            name: 'Istighfar',
            kind: TrackerKind.count,
            icon: 'heart',
            dailyTarget: 3,
          ),
          value: 2,
          displayName: 'Istighfar',
          onChanged: (_) {},
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.add));
    expect(buzzes, [
      'HapticFeedbackType.selectionClick',
      'HapticFeedbackType.mediumImpact',
    ]);
  });

  testWidgets('typing a value saves it without a disposed-controller error', (
    tester,
  ) async {
    int? changed;
    await tester.pumpWidget(
      _wrap(
        TrackerRow(
          item: _countItem,
          value: 2,
          displayName: 'Sadaqah',
          onChanged: (v) => changed = v,
        ),
      ),
    );
    await tester.tap(find.text('2'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '45');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(changed, 45);
  });
}
