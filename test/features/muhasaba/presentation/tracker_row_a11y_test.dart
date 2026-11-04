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

  testWidgets('tapping a yes/no row toggles it; the pencil edits', (
    tester,
  ) async {
    final changes = <int>[];
    var edits = 0;
    await tester.pumpWidget(
      _wrap(
        TrackerRow(
          item: const TrackerItem(
            id: 'custom_4',
            name: 'Tahajjud',
            kind: TrackerKind.yesNo,
            icon: 'moon',
          ),
          value: 0,
          displayName: 'Tahajjud',
          onChanged: changes.add,
          onEdit: () => edits++,
        ),
      ),
    );
    await tester.tap(find.text('Tahajjud'));
    expect(changes, [1]);
    expect(edits, 0);
    await tester.tap(find.byTooltip('Edit item'));
    expect(edits, 1);
  });

  testWidgets('durations read in hours and minutes', (tester) async {
    Future<void> pump(int value, int? target) => tester.pumpWidget(
      _wrap(
        TrackerRow(
          item: TrackerItem(
            id: 'custom_5',
            name: 'Sleep',
            kind: TrackerKind.duration,
            icon: 'moon',
            dailyTarget: target,
          ),
          value: value,
          displayName: 'Sleep',
          onChanged: (_) {},
        ),
      ),
    );
    await pump(90, 480);
    expect(find.text('1 h 30 min / 8 h'), findsOneWidget);
    await pump(45, null);
    expect(find.text('45 min'), findsOneWidget);
  });

  testWidgets('the duration dialog names its unit', (tester) async {
    await tester.pumpWidget(
      _wrap(
        TrackerRow(
          item: const TrackerItem(
            id: 'custom_6',
            name: 'Reading',
            kind: TrackerKind.duration,
            icon: 'book',
          ),
          value: 10,
          displayName: 'Reading',
          onChanged: (_) {},
        ),
      ),
    );
    await tester.tap(find.text('10'));
    await tester.pumpAndSettle();
    expect(find.text('minutes'), findsOneWidget);
  });

  testWidgets('at 2x text on 320dp the stepper sits under the name', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
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
    expect(tester.takeException(), isNull);
    final name = tester.getRect(find.text('Sadaqah'));
    final plus = tester.getRect(find.byIcon(Icons.add));
    expect(plus.top, greaterThanOrEqualTo(name.bottom));
    // The name keeps (nearly) the full row width.
    expect(name.width, greaterThan(150));
  });
}
