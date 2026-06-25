import 'package:flutter/material.dart';
import 'package:clean_boilerplate/config/util/dimensions.dart';
import 'package:clean_boilerplate/config/util/styles.dart';
import 'package:clean_boilerplate/core/extensions/context_extensions.dart';

/// A section title that stays pinned to the top of the viewport while its
/// content scrolls beneath it. Used via [SliverPersistentHeader].
class PinnedSectionHeader extends SliverPersistentHeaderDelegate {
  PinnedSectionHeader({
    required this.title,
    this.icon,
    this.trailing,
    this.horizontalPadding = Dimensions.paddingSizeLarge,
  });

  final String title;
  final IconData? icon;
  final Widget? trailing;
  final double horizontalPadding;

  static const double _height = 52;

  @override
  double get minExtent => _height;

  @override
  double get maxExtent => _height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final colors = context.customThemeColors;
    // Fade in a subtle background + shadow only once the header is pinned and
    // content is scrolling underneath it.
    final pinned = (overlapsContent || shrinkOffset > 0);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      decoration: BoxDecoration(
        color: pinned
            ? context.theme.scaffoldBackgroundColor
            : context.theme.scaffoldBackgroundColor.withValues(alpha: 0),
        boxShadow: pinned
            ? [
                BoxShadow(
                  color: colors.shadowColor,
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      alignment: Alignment.centerLeft,
      child: Row(
        children: [
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              color: colors.primaryColor,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: Dimensions.paddingSizeSmall),
          if (icon != null) ...[
            Icon(icon, size: Dimensions.iconSizeSmall, color: colors.primaryColor),
            const SizedBox(width: Dimensions.paddingSizeExtraSmall),
          ],
          Expanded(
            child: Text(
              title,
              style: AppTextStyles.sfProRoundedBold.copyWith(
                fontSize: Dimensions.fontSizeLarge,
                color: colors.textPrimaryColor,
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(covariant PinnedSectionHeader oldDelegate) {
    return oldDelegate.title != title ||
        oldDelegate.icon != icon ||
        oldDelegate.trailing != trailing ||
        oldDelegate.horizontalPadding != horizontalPadding;
  }
}
