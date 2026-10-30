import 'package:flutter_test/flutter_test.dart';
import 'package:productive_muslim/features/muhasaba/domain/entities/tracker_item.dart';

void main() {
  TrackerItem item(int? target) => TrackerItem(
    id: 'x',
    name: 'x',
    kind: TrackerKind.count,
    dailyTarget: target,
  );

  test('isDone matches the SQL done rule (no positive target → any value)', () {
    for (final target in [null, 0, -1]) {
      expect(item(target).isDone(0), isFalse, reason: '$target');
      expect(item(target).isDone(1), isTrue, reason: '$target');
    }
    expect(item(3).isDone(2), isFalse);
    expect(item(3).isDone(3), isTrue);
  });
}
