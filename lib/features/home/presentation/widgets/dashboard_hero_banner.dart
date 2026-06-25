import 'package:flutter/material.dart';
import 'package:clean_boilerplate/config/util/dimensions.dart';
import 'package:clean_boilerplate/config/util/styles.dart';
import 'package:clean_boilerplate/core/extensions/context_extensions.dart';
import 'package:clean_boilerplate/features/home/presentation/widgets/dashboard_formatters.dart';

/// Gradient summary banner for the tablet & desktop dashboards.
///
/// Mirrors the phone hero (greeting + headline total balance + meal/fund
/// chips) but as a self-contained rounded card. Internally responsive: places
/// the balance and chips side-by-side when wide, stacked when narrow.
class DashboardHeroBanner extends StatelessWidget {
  const DashboardHeroBanner({
    required this.userName,
    required this.totalBalance,
    required this.mealBalance,
    required this.fundBalance,
    super.key,
  });

  final String userName;
  final double totalBalance;
  final double mealBalance;
  final double fundBalance;

  @override
  Widget build(BuildContext context) {
    final colors = context.customThemeColors;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Dimensions.paddingSizeExtraLarge32),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Dimensions.radiusExtra2Large),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.primaryDarkColor,
            colors.primaryColor,
            colors.primaryLightColor,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: colors.primaryColor.withValues(alpha: 0.3),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth > 640;
          final chips = [
            _HeaderChip(
              icon: Icons.restaurant_rounded,
              label: 'Meal',
              value: DashboardFormatters.taka(mealBalance),
            ),
            _HeaderChip(
              icon: Icons.savings_rounded,
              label: 'Fund',
              value: DashboardFormatters.taka(fundBalance),
            ),
          ];

          if (wide) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(child: _balanceBlock(context)),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    chips[0],
                    const SizedBox(height: Dimensions.paddingSizeSmall),
                    chips[1],
                  ],
                ),
              ],
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _balanceBlock(context),
              const SizedBox(height: Dimensions.paddingSizeLarge),
              Wrap(
                spacing: Dimensions.paddingSizeSmall,
                runSpacing: Dimensions.paddingSizeSmall,
                children: chips,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _balanceBlock(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Welcome back,',
          style: AppTextStyles.sfProRoundedMedium.copyWith(
            color: Colors.white.withValues(alpha: 0.85),
            fontSize: Dimensions.fontSizeDefault,
          ),
        ),
        Text(
          userName,
          style: AppTextStyles.sfProRoundedBold.copyWith(
            color: Colors.white,
            fontSize: Dimensions.fontSizeExtraOverLarge,
          ),
        ),
        const SizedBox(height: Dimensions.paddingSizeExtraLarge),
        Text(
          'Total balance',
          style: AppTextStyles.sfProRoundedMedium.copyWith(
            color: Colors.white.withValues(alpha: 0.85),
            fontSize: Dimensions.fontSizeSmall,
          ),
        ),
        const SizedBox(height: Dimensions.paddingSizeExtraSmall),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            DashboardFormatters.taka(totalBalance),
            style: AppTextStyles.sfProRoundedBold.copyWith(
              color: Colors.white,
              fontSize: 36,
            ),
          ),
        ),
      ],
    );
  }
}

class _HeaderChip extends StatelessWidget {
  const _HeaderChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Dimensions.paddingSizeDefault,
        vertical: Dimensions.paddingSizeSmall,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(Dimensions.radiusExtra2Large),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: Dimensions.iconSizeSmall, color: Colors.white),
          const SizedBox(width: Dimensions.paddingSizeExtraSmall),
          Text(
            '$label · $value',
            style: AppTextStyles.sfProRoundedSemiBold.copyWith(
              color: Colors.white,
              fontSize: Dimensions.fontSizeSmall,
            ),
          ),
        ],
      ),
    );
  }
}
