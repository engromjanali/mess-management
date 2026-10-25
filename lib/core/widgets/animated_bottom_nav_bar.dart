import 'package:mess_pilot/core/helpers/responsive_helper.dart';
import 'package:flutter/material.dart';
import 'package:mess_pilot/config/util/dimensions.dart';
import 'package:mess_pilot/config/util/styles.dart';
import 'package:mess_pilot/core/extensions/context_extensions.dart';

/// A single destination in the [AnimatedBottomNavBar].
class BottomNavItem {
  const BottomNavItem({required this.icon, required this.activeIcon, required this.label, required this.onTap, this.profileImageUrl});

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final VoidCallback onTap;
  final String? profileImageUrl;
}

class AnimatedBottomNavBar extends StatelessWidget {
  const AnimatedBottomNavBar({required this.items, required this.currentIndex, required this.visible, super.key});

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
              padding: const EdgeInsets.fromLTRB(Dimensions.paddingSizeExtraLarge, 0, Dimensions.paddingSizeExtraLarge, Dimensions.paddingSizeDefault),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: ResponsiveHelper.smallMobile, maxHeight: 70),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall, vertical: Dimensions.paddingSizeSmall),
                  decoration: BoxDecoration(
                    color: colors.surfaceColor,
                    borderRadius: BorderRadius.circular(Dimensions.radiusExtra2Large),
                    border: Border.all(color: colors.borderColor),
                    boxShadow: [BoxShadow(color: colors.shadowColor, blurRadius: 20, offset: const Offset(0, 8))],
                  ),
                  child: Row(
                    spacing: Dimensions.paddingSizeSmall,
                    children: [for (var i = 0; i < items.length; i++) _NavCell(item: items[i], active: i == currentIndex)],
                  ),
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

    return Expanded(
      flex: active ? 2 : 1,
      child: SizedBox(
        height: 48,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: item.onTap,
            borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 320),
              curve: Curves.easeOutCubic,
              decoration: BoxDecoration(color: active ? colors.primaryColor.withValues(alpha: 0.12) : Colors.transparent, borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  item.profileImageUrl == null
                      ? Icon(active ? item.activeIcon : item.icon, color: color, size: Dimensions.iconSizeDefault)
                      : _ProfileNavImage(imageUrl: item.profileImageUrl!, fallbackIcon: active ? item.activeIcon : item.icon),
                  if (active) ...[
                    const SizedBox(width: Dimensions.paddingSizeSmall),
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(item.label, maxLines: 1, style: AppTextStyles.sfProRoundedSemiBold.copyWith(color: color, fontSize: Dimensions.fontSizeDefault)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileNavImage extends StatelessWidget {
  const _ProfileNavImage({required this.imageUrl, required this.fallbackIcon});
  final String imageUrl;
  final IconData fallbackIcon;

  @override
  Widget build(BuildContext context) {
    final colors = context.customThemeColors;

    return Container(
      width: 30,
      height: 30,
      padding: const EdgeInsets.all(1),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: colors.primaryColor),
      ),
      child: ClipOval(
        child: imageUrl.isEmpty
            ? ColoredBox(
                color: colors.primaryColor.withValues(alpha: 0.12),
                child: Icon(fallbackIcon, color: colors.primaryColor, size: Dimensions.iconSizeSmall),
              )
            : Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => ColoredBox(
                  color: colors.primaryColor.withValues(alpha: 0.12),
                  child: Icon(fallbackIcon, color: colors.primaryColor, size: Dimensions.iconSizeSmall),
                ),
              ),
      ),
    );
  }
}
