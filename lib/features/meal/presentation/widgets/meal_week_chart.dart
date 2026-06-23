import 'package:flutter/material.dart';
import '../../../../config/util/dimensions.dart';
import '../../../../config/util/styles.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../domain/entities/meal_entity.dart';
import 'meal_formatters.dart';

/// A lightweight (dependency-free) bar chart of the last seven days' meal
/// totals. Today's bar is accented; bars animate up on first build.
class MealWeekChart extends StatelessWidget {
  const MealWeekChart({required this.days, super.key});

  /// Oldest-to-newest, up to seven entries.
  final List<MealEntity> days;

  @override
  Widget build(BuildContext context) {
    final colors = context.customThemeColors;
    final now = DateTime.now();
    final maxTotal = days.fold<double>(
      0,
      (m, d) => d.total > m ? d.total : m,
    );
    // Avoid divide-by-zero when everything is empty.
    final denominator = maxTotal == 0 ? 1.0 : maxTotal;

    return Container(
      padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
      decoration: BoxDecoration(
        color: colors.cardBackgroundColor,
        borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge),
        border: Border.all(color: colors.borderColor.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'This week',
            style: AppTextStyles.sfProRoundedBold.copyWith(
              fontSize: Dimensions.fontSizeLarge,
              color: colors.textPrimaryColor,
            ),
          ),
          const SizedBox(height: Dimensions.paddingSizeLarge),
          SizedBox(
            height: 140,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final day in days)
                  Expanded(
                    child: _Bar(
                      heightFactor: day.total / denominator,
                      value: day.total,
                      label: MealFormatters.weekdayInitial(day.date),
                      isToday: day.date.year == now.year &&
                          day.date.month == now.month &&
                          day.date.day == now.day,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({
    required this.heightFactor,
    required this.value,
    required this.label,
    required this.isToday,
  });

  final double heightFactor;
  final double value;
  final String label;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    final colors = context.customThemeColors;
    final barColor =
        isToday ? colors.primaryColor : colors.primaryColor.withValues(alpha: 0.35);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Dimensions.paddingSizeExtraSmall,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            MealFormatters.count(value),
            style: AppTextStyles.sfProRoundedSemiBold.copyWith(
              fontSize: Dimensions.fontSizeExtraSmall,
              color: colors.textSecondaryColor,
            ),
          ),
          const SizedBox(height: Dimensions.paddingSizeExtraSmall),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final fullHeight = constraints.maxHeight;
                // Keep a small stub visible even for zero-meal days.
                final target = (fullHeight * heightFactor).clamp(4.0, fullHeight);
                return Align(
                  alignment: Alignment.bottomCenter,
                  child: TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOutCubic,
                    tween: Tween(begin: 0, end: target),
                    builder: (context, height, _) => Container(
                      height: height,
                      decoration: BoxDecoration(
                        color: barColor,
                        borderRadius:
                            BorderRadius.circular(Dimensions.radiusSmall),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: Dimensions.paddingSizeSmall),
          Text(
            label,
            style: AppTextStyles.sfProRoundedMedium.copyWith(
              fontSize: Dimensions.fontSizeSmall,
              color: isToday ? colors.primaryColor : colors.textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }
}
