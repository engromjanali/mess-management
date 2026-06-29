import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:clean_boilerplate/config/route/app_router.dart';
import 'package:clean_boilerplate/config/util/dimensions.dart';
import 'package:clean_boilerplate/config/util/styles.dart';
import 'package:clean_boilerplate/core/extensions/context_extensions.dart';
import 'package:clean_boilerplate/features/settings/domain/entities/theme_mode.dart';
import 'package:clean_boilerplate/features/settings/presentation/bloc/theme/theme_bloc.dart';
import 'package:clean_boilerplate/features/settings/presentation/bloc/theme/theme_event.dart';

/// A single navigation entry rendered in the [DashboardTopBar].
class DashboardNavItem {
  const DashboardNavItem({required this.label, required this.icon, required this.onTap, this.active = false});

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool active;
}

class DashboardTopBar extends StatelessWidget {
  const DashboardTopBar({required this.userName, required this.onRefresh, this.navItems = const [], super.key});

  final String userName;
  final VoidCallback onRefresh;
  final List<DashboardNavItem> navItems;

  static const double height = 72;

  @override
  Widget build(BuildContext context) {
    final colors = context.customThemeColors;

    return Material(
      color: colors.surfaceColor,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: colors.borderColor)),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: Dimensions.webMaxWidth),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeExtraLarge24),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  // Progressive disclosure as the bar widens.
                  final showNavLabels = width >= 1000;
                  final showBrandText = width >= 720;
                  final showProfileText = width >= 880;

                  return Row(
                    children: [
                      _Brand(showText: showBrandText),
                      if (navItems.isNotEmpty) ...[
                        SizedBox(width: showNavLabels ? Dimensions.paddingSizeExtraLarge32 : Dimensions.paddingSizeLarge),
                        for (final item in navItems)
                          Padding(
                            padding: const EdgeInsets.only(right: Dimensions.paddingSizeExtraSmall),
                            child: _NavButton(item: item, showLabel: showNavLabels),
                          ),
                      ],
                      const Spacer(),
                      _ActionIcon(icon: Icons.refresh_rounded, tooltip: 'Refresh', onPressed: onRefresh),
                      _ActionIcon(
                        icon: context.isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                        tooltip: 'Toggle theme',
                        onPressed: () => context.read<ThemeBloc>().add(ThemeEvent.changeThemeMode(context.isDarkMode ? AppThemeMode.light : AppThemeMode.dark)),
                      ),
                      _ActionIcon(icon: Icons.settings_outlined, tooltip: context.local.settings, onPressed: () => context.go(AppRoutes.settings)),
                      const SizedBox(width: Dimensions.paddingSizeDefault),
                      _ProfileChip(userName: userName, showText: showProfileText),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Brand extends StatelessWidget {
  const _Brand({required this.showText});
  final bool showText;

  @override
  Widget build(BuildContext context) {
    final colors = context.customThemeColors;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 40,
          width: 40,
          decoration: BoxDecoration(color: colors.primaryColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(Dimensions.radiusDefault)),
          child: Icon(Icons.restaurant_menu_rounded, color: colors.primaryColor, size: Dimensions.iconSizeDefault),
        ),
        if (showText) ...[
          const SizedBox(width: Dimensions.paddingSizeDefault),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Mess Manager',
                style: AppTextStyles.sfProRoundedBold.copyWith(fontSize: Dimensions.fontSizeLarge, color: colors.textPrimaryColor),
              ),
              Text(
                'Dashboard',
                style: AppTextStyles.sfProRoundedMedium.copyWith(fontSize: Dimensions.fontSizeSmall, color: colors.textSecondaryColor),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({required this.item, required this.showLabel});
  final DashboardNavItem item;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.customThemeColors;
    final color = item.active ? colors.primaryColor : colors.textSecondaryColor;
    final background = item.active ? colors.primaryColor.withValues(alpha: 0.12) : Colors.transparent;

    // Icon-only when space is tight — keep the label in a tooltip.
    if (!showLabel) {
      return Tooltip(
        message: item.label,
        child: Material(
          color: background,
          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
          child: InkWell(
            onTap: item.onTap,
            borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
            child: Padding(
              padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
              child: Icon(item.icon, size: Dimensions.iconSizeDefault, color: color),
            ),
          ),
        ),
      );
    }

    return TextButton.icon(
      onPressed: item.onTap,
      icon: Icon(item.icon, size: Dimensions.iconSizeSmall, color: color),
      label: Text(
        item.label,
        style: AppTextStyles.sfProRoundedSemiBold.copyWith(fontSize: Dimensions.fontSizeDefault, color: color),
      ),
      style: TextButton.styleFrom(
        backgroundColor: background,
        padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault, vertical: Dimensions.paddingSizeDefault),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Dimensions.radiusDefault)),
      ),
    );
  }
}

class _ActionIcon extends StatelessWidget {
  const _ActionIcon({required this.icon, required this.tooltip, required this.onPressed});

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon, color: context.customThemeColors.textSecondaryColor),
    );
  }
}

class _ProfileChip extends StatelessWidget {
  const _ProfileChip({required this.userName, required this.showText});
  final String userName;
  final bool showText;

  String get _initials {
    final parts = userName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return (parts.first.characters.first + parts.last.characters.first).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.customThemeColors;

    final avatar = CircleAvatar(
      radius: 18,
      backgroundColor: colors.primaryColor.withValues(alpha: 0.15),
      child: Text(
        _initials,
        style: AppTextStyles.sfProRoundedBold.copyWith(fontSize: Dimensions.fontSizeDefault, color: colors.primaryColor),
      ),
    );

    if (!showText) return avatar;

    return Container(
      padding: const EdgeInsets.fromLTRB(Dimensions.paddingSizeExtraSmall, Dimensions.paddingSizeExtraSmall, Dimensions.paddingSizeDefault, Dimensions.paddingSizeExtraSmall),
      decoration: BoxDecoration(
        color: colors.backgroundColor,
        borderRadius: BorderRadius.circular(Dimensions.radiusExtra2Large),
        border: Border.all(color: colors.borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          avatar,
          const SizedBox(width: Dimensions.paddingSizeSmall),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 140),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.sfProRoundedSemiBold.copyWith(fontSize: Dimensions.fontSizeDefault, color: colors.textPrimaryColor),
                ),
                Text(
                  'Member',
                  style: AppTextStyles.sfProRoundedRegular.copyWith(fontSize: Dimensions.fontSizeExtraSmall, color: colors.textSecondaryColor),
                ),
              ],
            ),
          ),
          const SizedBox(width: Dimensions.paddingSizeExtraSmall),
          Icon(Icons.keyboard_arrow_down_rounded, size: Dimensions.iconSizeSmall, color: colors.textSecondaryColor),
        ],
      ),
    );
  }
}
