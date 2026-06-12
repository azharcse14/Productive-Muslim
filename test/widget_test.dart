import 'package:flutter_test/flutter_test.dart';
import 'package:qalbee/main.dart';

void main() {
  testWidgets('app boots to the placeholder home', (tester) async {
    await tester.pumpWidget(const QalbeeApp());
    expect(find.text('Qalbee'), findsOneWidget);
  });
}
