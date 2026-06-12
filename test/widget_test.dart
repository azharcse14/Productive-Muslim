import 'package:flutter_test/flutter_test.dart';
import 'package:qalbee/core/di/locator.dart';
import 'package:qalbee/main.dart';

void main() {
  testWidgets('app boots to the shell with bottom navigation', (tester) async {
    await setupLocator();
    await tester.pumpWidget(const QalbeeApp());
    await tester.pumpAndSettle();
    expect(find.text('Quran'), findsOneWidget);
    expect(find.text('Muhasaba'), findsOneWidget);
  });
}
