import 'package:productive_muslim/features/share/domain/share_sheet.dart';

/// Records shared texts instead of opening the OS share sheet.
final class FakeShareSheet implements ShareSheet {
  final shared = <String>[];

  @override
  Future<void> shareText(String text) async => shared.add(text);
}
