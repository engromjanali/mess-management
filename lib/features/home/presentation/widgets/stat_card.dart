import 'package:flutter/material.dart';
import '../../../../config/util/dimensions.dart';
import '../../../../config/util/styles.dart';
import '../../../../core/extensions/context_extensions.dart';

/// A single dashboard metric (icon + value + label) rendered as a modern,
/// tappable card with a tinted icon chip and a soft accent wash.
class StatCard extends StatelessWidget {
  const StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
    this.onTap,
    super.key,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color accent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.customThemeColors;

    return Material(
      color: colors.cardBackgroundColor,
      borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge),
            border: Border.all(color: colors.borderColor.withValues(alpha: 0.4)),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                accent.withValues(alpha: context.isDarkMode ? 0.18 : 0.10),
                colors.cardBackgroundColor.withValues(alpha: 0),
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                ),
                child: Icon(icon, color: accent, size: Dimensions.iconSizeDefault),
              ),
              const SizedBox(height: Dimensions.paddingSizeDefault),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  maxLines: 1,
                  style: AppTextStyles.sfProRoundedBold.copyWith(
                    fontSize: Dimensions.fontSizeExtraOverLarge,
                    color: colors.textPrimaryColor,
                  ),
                ),
              ),
              const SizedBox(height: Dimensions.paddingSizeExtraSmall),
              Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.sfProRoundedMedium.copyWith(
                  fontSize: Dimensions.fontSizeSmall,
                  color: colors.textSecondaryColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
