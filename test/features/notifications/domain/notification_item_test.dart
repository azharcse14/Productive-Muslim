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
    expect(azan.id, 1425031924);
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
}
