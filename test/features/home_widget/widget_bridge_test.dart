import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:productive_muslim/features/home_widget/data/widget_bridge.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('com.productivemuslim.app/widget');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  test('push forwards the payload over the updateWidget method', () async {
    MethodCall? captured;
    messenger.setMockMethodCallHandler(channel, (call) async {
      captured = call;
      return null;
    });

    const bridge = WidgetBridge();
    await bridge.push(const {
      'widget_configured': '1',
      'widget_prayer': 'Asr',
      'widget_time': '4:32 PM',
    });

    expect(captured?.method, 'updateWidget');
    final args = (captured?.arguments as Map).cast<String, Object?>();
    expect(args['widget_prayer'], 'Asr');
    expect(args['widget_time'], '4:32 PM');
  });
}
