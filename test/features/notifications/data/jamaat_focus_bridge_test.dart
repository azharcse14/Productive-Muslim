import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:productive_muslim/features/notifications/data/jamaat_focus_bridge.dart';
import 'package:productive_muslim/features/notifications/domain/entities/notification_texts.dart';
import 'package:productive_muslim/features/notifications/domain/usecases/build_focus_windows.dart';
import 'package:productive_muslim/features/settings/domain/entities/prayer_params.dart';

const _texts = NotificationTexts(
  azanTitle: '',
  azanBody: '',
  jamaatTitle: '',
  jamaatBody: '',
  sahriTitle: '',
  sahriBody: '',
  iftarTitle: '',
  iftarBody: '',
  muhasabaTitle: '',
  muhasabaBody: '',
  dailyReminderTitle: '',
  dailyReminderBody: '',
  dailyReminderRoute: '/hadith',
  keepAliveTitle: '',
  keepAliveBody: '',
  markAsPrayedAction: '',
  channelAzanName: '',
  channelRemindersName: '',
  channelSilentName: '',
  channelBeepName: '',
  prayerNames: {},
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('com.productivemuslim.app/focus');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  /// Schedules with block + nafs on against a native side that does or
  /// doesn't have the blocking service; returns the 'schedule' arguments.
  Future<Map<Object?, Object?>> scheduled({required Object? blocking}) async {
    Map<Object?, Object?>? sent;
    messenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'isBlockingAvailable') {
        return blocking;
      }
      if (call.method == 'schedule') {
        sent = call.arguments as Map<Object?, Object?>;
      }
      return null;
    });
    addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
    await const JamaatFocusBridge().schedule(
      windows: [
        FocusWindow(
          prayer: Prayer.dhuhr,
          start: DateTime.utc(2026, 10, 29, 13),
          end: DateTime.utc(2026, 10, 29, 13, 20),
        ),
      ],
      enabled: true,
      block: true,
      strict: false,
      nafs: true,
      nafsDuration: const Duration(minutes: 5),
      texts: _texts,
      toUtc: (wall) => wall,
    );
    return sent!;
  }

  test(
    'without the blocking service: DND-only focus still schedules',
    () async {
      final args = await scheduled(blocking: false);
      expect(args['enabled'], isTrue);
      expect(args['windows'], hasLength(1));
      expect(args['block'], isFalse);
      expect(args['nafs'], isFalse);
    },
  );

  test('with the service the stored choices pass through', () async {
    final args = await scheduled(blocking: true);
    expect(args['block'], isTrue);
    expect(args['nafs'], isTrue);
  });
}
