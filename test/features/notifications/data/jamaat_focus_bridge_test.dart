import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:productive_muslim/features/notifications/data/jamaat_focus_bridge.dart';
import 'package:productive_muslim/features/notifications/domain/entities/notification_texts.dart';
import 'package:productive_muslim/features/notifications/domain/usecases/build_focus_windows.dart';
import 'package:productive_muslim/features/settings/domain/entities/city.dart';
import 'package:productive_muslim/features/settings/domain/entities/location_config.dart';
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

DateTime _same(DateTime wall) => wall;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('com.productivemuslim.app/focus');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  /// Schedules with block + nafs on against a native side that does or
  /// doesn't have the blocking service; returns the 'schedule' arguments.
  Future<Map<Object?, Object?>> scheduled({
    required Object? blocking,
    NotificationTexts texts = _texts,
    DateTime Function(DateTime wall) toUtc = _same,
    LocationConfig? location,
  }) async {
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
          prayerDay: DateTime(2026, 10, 29),
        ),
      ],
      enabled: true,
      block: true,
      strict: false,
      nafs: true,
      nafsDuration: const Duration(minutes: 5),
      texts: texts,
      toUtc: toUtc,
      location: location,
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

  test('nafs countdown texts are pushed for the native cover', () async {
    const texts = NotificationTexts(
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
      nafsLockPending: 'Locking in {seconds} s',
      nafsLockCancel: 'Cancel',
    );
    final args = await scheduled(blocking: true, texts: texts);
    expect(args['nafs.pending'], 'Locking in {seconds} s');
    expect(args['nafs.cancel'], 'Cancel');
  });

  test('each window carries its jamaat key (prayer day + prayer)', () async {
    final args = await scheduled(blocking: true);
    expect(args['windows'], [
      [
        DateTime.utc(2026, 10, 29, 13).millisecondsSinceEpoch,
        DateTime.utc(2026, 10, 29, 13, 20).millisecondsSinceEpoch,
        202610292,
      ],
    ]);
  });

  test('the end goes as the app shows it: app language, wall clock', () async {
    await initializeDateFormatting('en');
    const en = NotificationTexts(
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
      localeCode: 'en',
    );
    final args = await scheduled(
      blocking: true,
      texts: en,
      // The city is UTC+6: the instant moves, the label keeps 1:20 PM.
      toUtc: (wall) => wall.subtract(const Duration(hours: 6)),
    );
    final window = (args['windows']! as List<Object?>).single! as List<Object?>;
    expect(window, hasLength(4));
    expect(window[1], DateTime.utc(2026, 10, 29, 7, 20).millisecondsSinceEpoch);
    expect(window[3], matches(RegExp(r'^1:20\sPM$')));
  });

  test(
    'nafs ends (set natively) get the app format, digits and city zone',
    () async {
      await initializeDateFormatting('bn');
      const bn = NotificationTexts(
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
        localeCode: 'bn',
      );
      final city = await scheduled(
        blocking: true,
        texts: bn,
        location: const ManualCityLocation(
          City(
            name: 'Dhaka',
            countryCode: 'BD',
            latitude: 23.7,
            longitude: 90.4,
            timezone: 'Asia/Dhaka',
          ),
        ),
      );
      expect(city['clockPattern'], 'h:mm a');
      expect(city['clockAm'], isNotEmpty);
      expect(city['clockPm'], isNotEmpty);
      expect(city['clockDigits'], '০১২৩৪৫৬৭৮৯');
      expect(city['clockZone'], 'Asia/Dhaka');
      // GPS: the device zone is the location's zone.
      final gps = await scheduled(
        blocking: true,
        texts: bn,
        location: const GpsLocation(latitude: 23.7, longitude: 90.4),
      );
      expect(gps['clockZone'], '');
      // Locale unknown: native keeps the device format.
      expect((await scheduled(blocking: true))['clockPattern'], '');
    },
  );
}
