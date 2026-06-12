import 'package:flutter_test/flutter_test.dart';
import 'package:qalbee/core/di/locator.dart';
import 'package:qalbee/main.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  testWidgets('app boots to the shell with bottom navigation', (tester) async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    await setupLocator();
    await tester.pumpWidget(const QalbeeApp());
    await tester.pumpAndSettle();
    expect(find.text('Quran'), findsOneWidget);
    expect(find.text('Muhasaba'), findsOneWidget);
  });
}
