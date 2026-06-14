import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qalbee/core/l10n/gen/app_localizations.dart';
import 'package:qalbee/core/theme/app_theme.dart';
import 'package:qalbee/features/muhasaba/domain/entities/tracker_item.dart';
import 'package:qalbee/features/muhasaba/presentation/widgets/tracker_row.dart';

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
}
