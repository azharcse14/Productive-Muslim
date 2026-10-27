import 'package:flutter/widgets.dart';

import '../../core/theme/productive_muslim_tokens.dart';
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

/// A padded column of card-sized skeletons for a list still loading.
final class QSkeletonList extends StatelessWidget {
  const QSkeletonList({this.count = 4, this.height = 120, super.key});

  final int count;
  final double height;

  @override
  Widget build(BuildContext context) => ListView.separated(
    physics: const NeverScrollableScrollPhysics(),
    padding: const EdgeInsets.all(QSpace.s5),
    itemCount: count,
    separatorBuilder: (_, _) => const SizedBox(height: QSpace.s3),
    itemBuilder: (_, _) => QSkeleton(height: height, radius: QRadius.lg),
  );
}
