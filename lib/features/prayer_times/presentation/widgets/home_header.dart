import 'package:flutter/material.dart';

import '../../../../core/theme/qalbee_typography.dart';
import '../../../../shared/extensions/context_ext.dart';

/// Home header (design §4.3): tappable location pill + tri-calendar date
/// line (Gregorian · Hijri · Bengali when locale-relevant).
final class HomeHeader extends StatelessWidget {
  const HomeHeader({
    required this.locationName,
    required this.dates,
    required this.onLocationTap,
    this.onQiblaTap,
    super.key,
  });

  final String locationName;

  /// Pre-formatted date strings, rendered dot-separated and wrapping.
  final List<String> dates;
  final VoidCallback onLocationTap;
  final VoidCallback? onQiblaTap;

  @override
  Widget build(BuildContext context) {
    final q = context.q;
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(22, 8, 22, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Flexible(
                child: Semantics(
                  button: true,
                  child: InkWell(
                    onTap: onLocationTap,
                    borderRadius: BorderRadius.circular(99),
                    child: Padding(
                      padding: const EdgeInsetsDirectional.fromSTEB(
                        4,
                        8,
                        10,
                        8,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.place_outlined,
                              size: 17, color: q.primary),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              locationName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: QType.titleSm.copyWith(
                                fontSize: 15.5,
                                color: q.ink,
                                fontVariations: const [
                                  FontVariation('wght', 700),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.keyboard_arrow_down,
                              size: 15, color: q.ink3),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: onQiblaTap,
                icon: Icon(Icons.explore_outlined, size: 22, color: q.ink2),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsetsDirectional.only(start: 4, top: 2),
            child: Wrap(
              spacing: 7,
              runSpacing: 2,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                for (final (i, d) in dates.indexed) ...[
                  if (i > 0)
                    Opacity(
                      opacity: 0.5,
                      child:
                          Text('·', style: QType.caption.copyWith(color: q.ink2)),
                    ),
                  Text(d, style: QType.caption.copyWith(color: q.ink2)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
