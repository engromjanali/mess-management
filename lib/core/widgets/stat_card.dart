import 'package:flutter/material.dart';
import 'package:mess_pilot/config/util/dimensions.dart';
import 'package:mess_pilot/config/util/styles.dart';
import 'package:mess_pilot/core/extensions/context_extensions.dart';
import 'package:mess_pilot/core/helpers/responsive_helper.dart';

/// A single dashboard metric (icon + value + label) rendered as a modern,
/// tappable card with a tinted icon chip and a soft accent wash.
class StatCard extends StatelessWidget {
  const StatCard({required this.label, required this.value, required this.icon, required this.accent, this.onTap, super.key});

  final String label;
  final String value;
  final IconData icon;
  final Color accent;
  final VoidCallback? onTap;

  /// Phones and small tablets get a denser card so metric grids stay compact.
  static bool isCompact(BuildContext context) =>
      ResponsiveHelper.isMobile(context) || ResponsiveHelper.isSmallTab(context);

  /// Grid row height that matches [StatCard]'s compact / regular density.
  static double gridMainAxisExtent(BuildContext context, {double regular = 168}) => isCompact(context) ? 132 : regular;

  @override
  Widget build(BuildContext context) {
    final colors = context.customThemeColors;
    final compact = isCompact(context);
    final radius = BorderRadius.circular(compact ? Dimensions.radiusLarge : Dimensions.radiusExtraLarge);

    return Material(
      color: colors.cardBackgroundColor,
      borderRadius: radius,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.all(compact ? Dimensions.paddingSizeDefault : Dimensions.paddingSizeLarge),
          decoration: BoxDecoration(
            borderRadius: radius,
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
                padding: EdgeInsets.all(compact ? Dimensions.paddingSizeExtraSmall + 2 : Dimensions.paddingSizeSmall),
                decoration: BoxDecoration(color: accent.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(Dimensions.radiusDefault)),
                child: Icon(icon, color: accent, size: compact ? 20 : Dimensions.iconSizeDefault),
              ),
              SizedBox(height: compact ? Dimensions.paddingSizeSmall : Dimensions.paddingSizeDefault),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  maxLines: 1,
                  style: AppTextStyles.sfProRoundedBold.copyWith(fontSize: compact ? Dimensions.fontSizeOverLarge : Dimensions.fontSizeExtraOverLarge, color: colors.textPrimaryColor),
                ),
              ),
              SizedBox(height: compact ? 2 : Dimensions.paddingSizeExtraSmall),
              Flexible(
                child: Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.sfProRoundedMedium.copyWith(fontSize: compact ? 11 : Dimensions.fontSizeSmall, color: colors.textSecondaryColor),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
