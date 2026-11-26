import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:mess_pilot/config/util/dimensions.dart';
import 'package:mess_pilot/core/widgets/stat_card.dart';

/// Width-adaptive grid of [StatCard]s.
///
/// Columns are packed within [maxCardExtent] and the compact row height
/// scales with the resulting card width (see [StatCard.gridMainAxisExtent])
/// so 2- and 3-column layouts keep balanced proportions.
class StatCardGrid extends StatelessWidget {
  const StatCardGrid({required this.itemCount, required this.itemBuilder, this.maxCardExtent = 200, this.regularExtent = 168, super.key});

  final int itemCount;
  final Widget Function(BuildContext context, int index) itemBuilder;
  final double maxCardExtent;
  final double regularExtent;

  @override
  Widget build(BuildContext context) {
    const spacing = Dimensions.paddingSizeDefault;
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisExtent = constraints.maxWidth;
        final columnCount = crossAxisExtent.isFinite && crossAxisExtent > 0 ? math.max(1, (crossAxisExtent / (maxCardExtent + spacing)).ceil()) : 1;
        final cardWidth = (crossAxisExtent - spacing * (columnCount - 1)) / columnCount;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columnCount,
            mainAxisExtent: StatCard.gridMainAxisExtent(context, cardWidth: cardWidth, regular: regularExtent),
            crossAxisSpacing: spacing,
            mainAxisSpacing: spacing,
          ),
          itemCount: itemCount,
          itemBuilder: itemBuilder,
        );
      },
    );
  }
}
