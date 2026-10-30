import 'package:flutter_test/flutter_test.dart';
import 'package:productive_muslim/features/notifications/domain/entities/notification_item.dart';
import 'package:productive_muslim/features/settings/domain/entities/prayer_params.dart';

void main() {
  test('id is a fixed 31-bit value per kind/prayer/minute', () {
    final at = DateTime(2026, 6, 12, 18, 45, 30);
    final azan = NotificationItem(
      kind: NotificationKind.azan,
      at: at,
      prayer: Prayer.maghrib,
    );
    // Pinned: must not change between runs (Object.hash is seeded per run).
    expect(azan.id, 702580228);
    expect(azan.id, inInclusiveRange(0, 0x7FFFFFFF));
    expect(
      NotificationItem(
        kind: NotificationKind.jamaat,
        at: at,
        prayer: Prayer.maghrib,
      ).id,
      isNot(azan.id),
    );
    expect(
      NotificationItem(
        kind: NotificationKind.azan,
        at: at,
        prayer: Prayer.isha,
      ).id,
      isNot(azan.id),
    );
  });

  test('kind codes are pinned (ids of pending notifications)', () {
    expect(NotificationKind.values.map((k) => k.code), [
      for (var i = 0; i <= 10; i++) i,
    ]);
    expect(
      NotificationKind.values.every(
        (k) => k.code < NotificationKind.kindCapacity,
      ),
      isTrue,
    );
  });

  test('ids never collide across kinds, prayers and neighbouring minutes', () {
    final base = DateTime(2026, 6, 12, 4);
    final ids = <int>{};
    var count = 0;
    for (var m = 0; m < 3; m++) {
      for (final kind in NotificationKind.values) {
        for (final prayer in [null, ...Prayer.values]) {
          ids.add(
            NotificationItem(
              kind: kind,
              at: base.add(Duration(minutes: m)),
              prayer: prayer,
            ).id,
          );
          count++;
        }
      }
    }
    expect(ids, hasLength(count));
  });

  test('items filed under different prayer days are not equal', () {
    NotificationItem isha(int day) => NotificationItem(
      kind: NotificationKind.azan,
      at: DateTime(2026, 6, 15, 0, 30),
      prayer: Prayer.isha,
      prayerDay: DateTime(2026, 6, day),
    );
    expect(isha(14), isNot(isha(15)));
    expect(isha(14), isha(14));
    expect(isha(14).hashCode, isha(14).hashCode);
  });
}
