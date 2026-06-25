import 'package:flutter/material.dart';
import 'package:clean_boilerplate/config/util/dimensions.dart';
import 'package:clean_boilerplate/config/util/styles.dart';
import 'package:clean_boilerplate/core/extensions/context_extensions.dart';
import 'package:clean_boilerplate/features/home/presentation/widgets/dashboard_formatters.dart';
import 'package:clean_boilerplate/features/meal/domain/entities/meal_entity.dart';
import 'package:clean_boilerplate/features/meal/presentation/widgets/meal_formatters.dart';
import 'package:clean_boilerplate/features/meal/presentation/widgets/meal_stepper.dart';

/// Editable "today" card — breakfast / lunch / dinner steppers with a live
/// running total and estimated cost. Emits the full new triple on any change.
class MealTodayCard extends StatelessWidget {
  const MealTodayCard({
    required this.today,
    required this.mealRate,
    required this.onChanged,
    this.editable = true,
    super.key,
  });

  final MealEntity today;
  final double mealRate;

  /// When false the steppers are replaced with read-only value chips
  /// (e.g. for the non-admin "user" role).
  final bool editable;

  /// Called with the updated (breakfast, lunch, dinner) on any stepper change.
  final void Function(double breakfast, double lunch, double dinner) onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.customThemeColors;

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
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Today's meals",
                    style: AppTextStyles.sfProRoundedBold.copyWith(
                      fontSize: Dimensions.fontSizeExtraLarge,
                      color: colors.textPrimaryColor,
                    ),
                  ),
                  Text(
                    MealFormatters.dayLabel(today.date),
                    style: AppTextStyles.sfProRoundedMedium.copyWith(
                      fontSize: Dimensions.fontSizeSmall,
                      color: colors.textSecondaryColor,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              _TotalBadge(total: today.total),
            ],
          ),
          const SizedBox(height: Dimensions.paddingSizeLarge),
          _MealRow(
            icon: Icons.free_breakfast_rounded,
            label: 'Breakfast',
            accent: colors.warningColor,
            value: today.breakfast,
            editable: editable,
            onChanged: (v) => onChanged(v, today.lunch, today.dinner),
          ),
          const Divider(height: Dimensions.paddingSizeLarge),
          _MealRow(
            icon: Icons.lunch_dining_rounded,
            label: 'Lunch',
            accent: colors.primaryColor,
            value: today.lunch,
            editable: editable,
            onChanged: (v) => onChanged(today.breakfast, v, today.dinner),
          ),
          const Divider(height: Dimensions.paddingSizeLarge),
          _MealRow(
            icon: Icons.dinner_dining_rounded,
            label: 'Dinner',
            accent: colors.infoColor,
            value: today.dinner,
            editable: editable,
            onChanged: (v) => onChanged(today.breakfast, today.lunch, v),
          ),
          const SizedBox(height: Dimensions.paddingSizeLarge),
          Container(
            padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
            decoration: BoxDecoration(
              color: colors.primaryColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
            ),
            child: Row(
              children: [
                Icon(Icons.payments_rounded,
                    size: Dimensions.iconSizeSmall, color: colors.primaryColor),
                const SizedBox(width: Dimensions.paddingSizeSmall),
                Text(
                  "Today's cost",
                  style: AppTextStyles.sfProRoundedMedium.copyWith(
                    fontSize: Dimensions.fontSizeDefault,
                    color: colors.textSecondaryColor,
                  ),
                ),
                const Spacer(),
                Text(
                  DashboardFormatters.taka(today.total * mealRate),
                  style: AppTextStyles.sfProRoundedBold.copyWith(
                    fontSize: Dimensions.fontSizeLarge,
                    color: colors.primaryColor,
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

class _MealRow extends StatelessWidget {
  const _MealRow({
    required this.icon,
    required this.label,
    required this.accent,
    required this.value,
    required this.editable,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final Color accent;
  final double value;
  final bool editable;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.customThemeColors;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
          ),
          child: Icon(icon, color: accent, size: Dimensions.iconSizeDefault),
        ),
        const SizedBox(width: Dimensions.paddingSizeDefault),
        Expanded(
          child: Text(
            label,
            style: AppTextStyles.sfProRoundedSemiBold.copyWith(
              fontSize: Dimensions.fontSizeLarge,
              color: colors.textPrimaryColor,
            ),
          ),
        ),
        if (editable)
          MealStepper(value: value, onChanged: onChanged, accent: accent)
        else
          _ReadOnlyValue(value: value, accent: accent),
      ],
    );
  }
}

/// Read-only count chip shown in place of the stepper for non-editing roles.
class _ReadOnlyValue extends StatelessWidget {
  const _ReadOnlyValue({required this.value, required this.accent});
  final double value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 44),
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(
        horizontal: Dimensions.paddingSizeDefault,
        vertical: Dimensions.paddingSizeSmall,
      ),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
      ),
      child: Text(
        MealFormatters.count(value),
        style: AppTextStyles.sfProRoundedBold.copyWith(
          fontSize: Dimensions.fontSizeExtraLarge,
          color: accent,
        ),
      ),
    );
  }
}

class _TotalBadge extends StatelessWidget {
  const _TotalBadge({required this.total});
  final double total;

  @override
  Widget build(BuildContext context) {
    final colors = context.customThemeColors;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Dimensions.paddingSizeDefault,
        vertical: Dimensions.paddingSizeSmall,
      ),
      decoration: BoxDecoration(
        color: colors.primaryColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(Dimensions.radiusExtra2Large),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.restaurant_rounded,
              size: Dimensions.iconSizeSmall, color: colors.primaryColor),
          const SizedBox(width: Dimensions.paddingSizeExtraSmall),
          Text(
            '${MealFormatters.count(total)} meals',
            style: AppTextStyles.sfProRoundedBold.copyWith(
              fontSize: Dimensions.fontSizeDefault,
              color: colors.primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}
