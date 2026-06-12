import 'package:flutter/widgets.dart';

import '../extensions/context_ext.dart';

/// Loading placeholder block (design: skeletons, not spinners).
final class QSkeleton extends StatelessWidget {
  const QSkeleton({
    this.width = double.infinity,
    this.height = 14,
    this.radius = 7,
    super.key,
  });

  final double width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: context.q.surface2,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
