import 'package:productive_muslim/features/keep_awake/domain/screen_wake.dart';

/// Records [ScreenWake] holds instead of calling the platform.
final class FakeScreenWake implements ScreenWake {
  final calls = <bool>[];

  /// Open holds right now.
  int get holds => calls.fold(0, (n, on) => on ? n + 1 : n - 1);

  @override
  Future<void> hold({required bool on}) async => calls.add(on);
}
