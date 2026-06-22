import 'package:flutter/material.dart';
import '../../../../config/util/dimensions.dart';
import '../../../../config/util/styles.dart';
import '../../../../core/extensions/context_extensions.dart';

/// A single destination in the [AnimatedBottomNavBar].
class BottomNavItem {
  const BottomNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final VoidCallback onTap;
}

/// A modern floating bottom navigation bar that slides away on scroll-down and
/// springs back on scroll-up.
///
/// Visibility is driven by [visible] (the parent flips it from scroll
/// direction). The active cell expands into a tinted pill that reveals its
/// label with an [AnimatedSize] width animation.
class AnimatedBottomNavBar extends StatelessWidget {
  const AnimatedBottomNavBar({
    required this.items,
    required this.currentIndex,
    required this.visible,
    super.key,
  });

  final List<BottomNavItem> items;
  final int currentIndex;
  final bool visible;

  @override
  Widget build(BuildContext context) {
    final colors = context.customThemeColors;

    return IgnorePointer(
      ignoring: !visible,
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
        // Slide fully below the screen edge when hidden.
        offset: visible ? Offset.zero : const Offset(0, 2),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 240),
          opacity: visible ? 1 : 0,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                Dimensions.paddingSizeExtraLarge,
                0,
                Dimensions.paddingSizeExtraLarge,
                Dimensions.paddingSizeDefault,
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: Dimensions.paddingSizeSmall,
                  vertical: Dimensions.paddingSizeSmall,
                ),
                decoration: BoxDecoration(
                  color: colors.surfaceColor,
                  borderRadius: BorderRadius.circular(Dimensions.radiusExtra2Large),
                  border: Border.all(color: colors.borderColor),
                  boxShadow: [
                    BoxShadow(
                      color: colors.shadowColor,
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    for (var i = 0; i < items.length; i++)
                      _NavCell(item: items[i], active: i == currentIndex),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavCell extends StatelessWidget {
  const _NavCell({required this.item, required this.active});
  final BottomNavItem item;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final colors = context.customThemeColors;
    final color = active ? colors.primaryColor : colors.textSecondaryColor;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(
            horizontal: Dimensions.paddingSizeDefault,
            vertical: Dimensions.paddingSizeDefault,
          ),
          decoration: BoxDecoration(
            color: active
                ? colors.primaryColor.withValues(alpha: 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                active ? item.activeIcon : item.icon,
                color: color,
                size: Dimensions.iconSizeDefault,
              ),
              // Reveal the label only for the active cell, animating its width.
              AnimatedSize(
                duration: const Duration(milliseconds: 320),
                curve: Curves.easeOutCubic,
                child: active
                    ? Padding(
                        padding: const EdgeInsets.only(
                          left: Dimensions.paddingSizeSmall,
                        ),
                        child: Text(
                          item.label,
                          style: AppTextStyles.sfProRoundedSemiBold.copyWith(
                            color: color,
                            fontSize: Dimensions.fontSizeDefault,
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
