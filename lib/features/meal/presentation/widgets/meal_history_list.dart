import 'package:flutter/material.dart';
import 'package:clean_boilerplate/config/util/dimensions.dart';
import 'package:clean_boilerplate/config/util/styles.dart';
import 'package:clean_boilerplate/core/extensions/context_extensions.dart';
import 'package:clean_boilerplate/features/home/presentation/widgets/dashboard_formatters.dart';
import 'package:clean_boilerplate/features/meal/domain/entities/meal_entity.dart';
import 'package:clean_boilerplate/features/meal/presentation/widgets/meal_formatters.dart';

/// Scrollable-free meal history card: one row per day with the B/L/D breakdown,
/// the day's meal total and its cost. Designed to sit inside an outer scroll.
class MealHistoryList extends StatelessWidget {
  const MealHistoryList({
    required this.days,
    required this.mealRate,
    super.key,
  });

  /// Most-recent-first list of days.
  final List<MealEntity> days;
  final double mealRate;

  @override
  Widget build(BuildContext context) {
    final colors = context.customThemeColors;
    final now = DateTime.now();

    return Container(
      decoration: BoxDecoration(
        color: colors.cardBackgroundColor,
        borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge),
        border: Border.all(color: colors.borderColor.withValues(alpha: 0.4)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < days.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                color: colors.dividerColor.withValues(alpha: 0.3),
              ),
            _HistoryRow(
              day: days[i],
              mealRate: mealRate,
              isToday: days[i].date.year == now.year &&
                  days[i].date.month == now.month &&
                  days[i].date.day == now.day,
            ),
          ],
        ],
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({
    required this.day,
    required this.mealRate,
    required this.isToday,
  });

  final MealEntity day;
  final double mealRate;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    final colors = context.customThemeColors;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Dimensions.paddingSizeLarge,
        vertical: Dimensions.paddingSizeDefault,
      ),
      child: Row(
        children: [
          // Date + today chip.
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    MealFormatters.dayLabel(day.date),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.sfProRoundedSemiBold.copyWith(
                      fontSize: Dimensions.fontSizeDefault,
                      color: colors.textPrimaryColor,
                    ),
                  ),
                ),
                if (isToday) ...[
                  const SizedBox(width: Dimensions.paddingSizeSmall),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Dimensions.paddingSizeSmall,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: colors.primaryColor.withValues(alpha: 0.14),
                      borderRadius:
                          BorderRadius.circular(Dimensions.radiusSmall),
                    ),
                    child: Text(
                      'Today',
                      style: AppTextStyles.sfProRoundedSemiBold.copyWith(
                        fontSize: Dimensions.fontSizeExtraSmall,
                        color: colors.primaryColor,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          // B / L / D mini badges.
          Expanded(
            flex: 3,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _Mini(label: 'B', value: day.breakfast, accent: colors.warningColor),
                _Mini(label: 'L', value: day.lunch, accent: colors.primaryColor),
                _Mini(label: 'D', value: day.dinner, accent: colors.infoColor),
              ],
            ),
          ),
          // Total + cost.
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${MealFormatters.count(day.total)} meals',
                  style: AppTextStyles.sfProRoundedBold.copyWith(
                    fontSize: Dimensions.fontSizeDefault,
                    color: colors.textPrimaryColor,
                  ),
                ),
                Text(
                  DashboardFormatters.taka(day.total * mealRate),
                  style: AppTextStyles.sfProRoundedMedium.copyWith(
                    fontSize: Dimensions.fontSizeSmall,
                    color: colors.textSecondaryColor,
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

class _Mini extends StatelessWidget {
  const _Mini({required this.label, required this.value, required this.accent});
  final String label;
  final double value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final muted = value == 0;
    final colors = context.customThemeColors;
    final color = muted ? colors.textHintColor : accent;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Dimensions.paddingSizeExtraSmall,
      ),
      child: Tooltip(
        message: '$label · ${MealFormatters.count(value)}',
        child: Container(
          width: 30,
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color.withValues(alpha: muted ? 0.06 : 0.14),
            shape: BoxShape.circle,
          ),
          child: Text(
            MealFormatters.count(value),
            style: AppTextStyles.sfProRoundedBold.copyWith(
              fontSize: Dimensions.fontSizeSmall,
              color: color,
            ),
          ),
        ),
      ),
    );
  }
}
